import std.stdio;
import dashboard_picture;

void writeBMP(in Picture img, string filename)
{
  const bpp = 3;
  const size = img.getSize();

  auto fp = File(filename, "wb");

  fp.rawWrite(['B', 'M']);
  writeLE4(fp, 0); // filesize: not known yet
  writeLE4(fp, 0); // reserved

  uint pixelOffset = 54;
  writeLE4(fp, pixelOffset);

  writeLE4(fp, 40); // header size
  writeLE4(fp, size.w);
  writeLE4(fp, size.h);
  writeLE2(fp, 1); // planes
  writeLE2(fp, cast(ushort)(bpp * 8));
  writeLE4(fp, 0); // compression: RGB
  writeLE4(fp, size.w * size.h * bpp);
  writeLE4(fp, 2835);
  writeLE4(fp, 2835);
  writeLE4(fp, 0);
  writeLE4(fp, 0);

  immutable pitch = size.w * bpp;

  ubyte[] rawLine;
  rawLine.length = size.w * bpp;

  while(rawLine.length % 4 != 0)
    rawLine ~= 0;

  static int convert(float val)
  {
    return clamp(cast(int)(val * 255.0), 0, 255);
  }

  for(int y = size.h - 1; y >= 0; --y)
  {
    for(int x = 0; x < size.w; ++x)
    {
      immutable pixel = img.blocks[0] (x, y);
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

