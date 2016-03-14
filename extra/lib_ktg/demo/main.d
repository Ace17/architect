/*
   Compile with:
   $ gdc demo_ktg.d\
   lib_ktg/ktg.d\
   lib_ktg/ktg_generators.d\
   -std=c++11 \
   lib_ktg/ktg/*.cpp\
   -Ilib_ktg
 */

import std.stdio;
import std.algorithm;
import ktg;

int main()
{
  auto pic = createCoolPicture();
  //auto pic = createTerrainPicture();
  writeBMP(&pic, "yo.bmp");
  return 0;
}

Texture createCoolPicture()
{
  const H = 512;
  const W = 512;
  auto texture = Texture(W, H);

  auto grad = Texture(2, 1);

  grad.Data[1] = Color(  0,   0, 0);
  grad.Data[0] = Color(255, 128, 128);

  if(true)
  {
    auto tmp = Texture(W, H);
    Voronoi(&tmp, 10.5, 200, 0.02);
    swap(tmp, texture);
  }

  auto noise = Texture(W, H);
  Noise(&noise, grad,
      2, 2, 6,
      0.55f, 123,
      NoiseMode.Direct | NoiseMode.Bandlimit | NoiseMode.Normalize);

  {
    auto tmp = Texture(W, H);

    GlowRect(&tmp, texture, grad,
        0.5f, 0.5f, 0.41f, 0.0f, 0.0f, 0.25f, 0.7805f, 0.64f);
    swap(tmp, texture);

    Rotozoom(&tmp, texture, 0.5, 8, FilterMode.WrapU | FilterMode.WrapV);
    swap(tmp, texture);
  }

  inplace!Derive(texture, DeriveOp.Normals, 25);

  {
    const amb = Color(16, 16, 16);
    const diff = Color(255, 255, 255);
    auto tmp = Texture(W, H);
    Bump(&tmp, noise, texture, null, null, 0.0f, 0.0f, 0.0f, -2.518f, 0.719f, -3.10f, amb, diff, 1);
    swap(tmp, texture);
  }

  return texture;
}

Texture createTerrainPicture()
{
  auto texture = Texture(256, 256);

  auto grad = Texture(8, 1);

  grad.Data[0] = Color(  0,   0, 128); // deeps
  grad.Data[1] = Color(  0,   0, 255); // shallow
  grad.Data[2] = Color(  0, 128, 255); // shore
  grad.Data[3] = Color(240, 240,  64); // sand
  grad.Data[4] = Color( 32, 160,   0); // grass
  grad.Data[5] = Color(128, 160, 128);
  grad.Data[6] = Color(128, 128, 128); // rock
  grad.Data[7] = Color(255, 255, 255); // snow

  auto noise = Texture(256, 256);
  Noise(&noise, grad,
      2, 2, 6,
      0.55f, 123,
      NoiseMode.Direct | NoiseMode.Bandlimit);

  {
    auto tmp = Texture(256, 256);

    GlowRect(&tmp, texture, grad,
        0.5f, 0.5f, 0.41f, 0.0f, 0.0f, 0.25f, 0.7805f, 0.64f);
    swap(tmp, texture);
  }

  inplace!Derive(texture, DeriveOp.Normals, 25);

  swap(noise, texture);

  return texture;
}

static void inplace(alias f, T...)(ref Texture text, T args)
{
  auto tmp = Texture(text.XRes, text.YRes);
  f(&tmp, text, args);
  swap(tmp, text);
}

void writeBMP(in Texture* img, string filename)
{
  const bpp = 3;
  const width = img.XRes;
  const height = img.YRes;

  auto fp = File(filename, "wb");

  fp.rawWrite(['B', 'M']);
  writeLE4(fp, 0); // filesize: not known yet
  writeLE4(fp, 0); // reserved

  uint pixelOffset = 54;
  writeLE4(fp, pixelOffset);

  writeLE4(fp, 40); // header size
  writeLE4(fp, width);
  writeLE4(fp, height);
  writeLE2(fp, 1); // planes
  writeLE2(fp, cast(ushort)(bpp * 8));
  writeLE4(fp, 0); // compression: RGB
  writeLE4(fp, width * height * bpp);
  writeLE4(fp, 2835);
  writeLE4(fp, 2835);
  writeLE4(fp, 0);
  writeLE4(fp, 0);

  immutable pitch = width * bpp;

  ubyte[] rawLine;
  rawLine.length = width * bpp;

  while(rawLine.length % 4 != 0)
    rawLine ~= 0;

  static int convert(float val)
  {
    return clamp(cast(int)(val / 256.0), 0, 255);
  }

  for(int y = height - 1; y >= 0; --y)
  {
    for(int x = 0; x < width; ++x)
    {
      immutable pixel = img.Data[x + y * img.XRes];
      rawLine[x * 3 + 0] = cast(ubyte) convert(pixel.b);
      rawLine[x * 3 + 1] = cast(ubyte) convert(pixel.g);
      rawLine[x * 3 + 2] = cast(ubyte) convert(pixel.r);
    }

    fp.rawWrite(rawLine);
  }

  // now we know the file size: write it.
  immutable fileSize = fp.tell();
  fp.seek(2);
  writeLE4(fp, cast(uint)fileSize);
}

private:
static void writeLE2(File fp, ushort value)
{
  ubyte[2] data;
  data[0] = (value >> 0) & 0xff;
  data[1] = (value >> 8) & 0xff;
  fp.rawWrite(data);
}

static void writeLE4(File fp, uint value)
{
  ubyte[4] data;
  data[0] = (value >> 0) & 0xff;
  data[1] = (value >> 8) & 0xff;
  data[2] = (value >> 16) & 0xff;
  data[3] = (value >> 24) & 0xff;
  fp.rawWrite(data);
}

static int clamp(int val, int min, int max)
{
  if(val < min)
    return min;

  if(val > max)
    return max;

  return val;
}

