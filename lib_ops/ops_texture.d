/**
 * @file ops_picture.d
 * @brief Picture processing/synthesis
 * @author Sebastien Alaiwan
 * @date 2015-11-07
 */

/*
 * Copyright (C) 2015 - Sebastien Alaiwan
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 */

import std.math;
import std.algorithm;
import std.conv;
import std.random;

import misc;

import execute;
import value;
import dashboard_picture;
import ktg;

static __gshared Texture* g_Texture;
static __gshared Texture*[16] g_Textures;

///////////////////////////////////////////////////////////////////////////////

void op_texture(EditionState state, Value[] values)
{
  if(values.length != 1)
    throw new Exception("texture takes one Vec2 argument");

  auto size = asVec2(values[0]);

  size.x = max(size.x, 16);
  size.y = max(size.y, 16);
  g_Texture = new Texture(cast(int)size.x, cast(int)size.y);

  for(int i = 0; i < g_Texture.NPixels; ++i)
  {
    g_Texture.Data[i].r = 0;
    g_Texture.Data[i].g = 255;
    g_Texture.Data[i].b = 0;
    g_Texture.Data[i].a = 0;
  }
}

void op_display(EditionState state, Value[] a)
{
  auto pic = new Picture;
  const w = cast(int)g_Texture.XRes;
  const h = cast(int)g_Texture.YRes;
  pic.data.length = w * h;

  for(int i = 0; i < g_Texture.NPixels; ++i)
  {
    pic.data[i].r = g_Texture.Data[i].r / 65536.0f;
    pic.data[i].g = g_Texture.Data[i].g / 65536.0f;
    pic.data[i].b = g_Texture.Data[i].b / 65536.0f;
    pic.data[i].a = g_Texture.Data[i].a / 65536.0f;
  }

  state.board = pic;
}

void op_store(Picture, int idx)
{
  const id = clampTextureIndex(idx);

  destroy(g_Textures[id]);
  g_Textures[id] = cloneTexture(g_Texture);
}

void op_load(Picture, int idx)
{
  const id = clampTextureIndex(idx);

  destroy(g_Texture);
  g_Texture = cloneTexture(g_Textures[id]);
}

///////////////////////////////////////////////////////////////////////////////

const WHITE_MASK = Color(0xff, 0xff, 0xff, 0xff);
const BLACK_MASK = Color(0, 0, 0, 0);

void op_noise(Picture, float freqx, float freqy, float octaves, float falloff)
{
  auto grad = Texture(2, 1);
  grad.Data[0] = WHITE_MASK;
  grad.Data[1] = BLACK_MASK;

  Noise(g_Texture, grad, to!int (freqx), to!int (freqy), to!int (octaves), falloff, 123,
        NoiseMode.Direct | NoiseMode.Bandlimit | NoiseMode.Normalize);
}

void op_derive(Picture, float fop, float strength)
{
  auto src = cloneTexture(g_Texture);
  scope(exit) destroy(*src);

  auto op = floatToEnum!DeriveOp(fop);
  Derive(g_Texture, *src, op, strength);
}

void op_blur(Picture, float sizex, float sizey, int order, int mode)
{
  auto src = cloneTexture(g_Texture);
  scope(exit) destroy(*src);

  Blur(g_Texture, *src, sizex, sizey, order, mode);
}

Texture* cloneTexture(const Texture* oldTexture)
{
  auto pText = new Texture(oldTexture.XRes, oldTexture.YRes);

  for(int i = 0; i < pText.NPixels; ++i)
    pText.Data[i] = oldTexture.Data[i];

  return pText;
}

T floatToEnum(T)(float input)
{
  const min = 0;
  const max = cast(int)T.max;
  return cast(T) clamp(cast(int)input, min, max);
}

void op_voronoi(Picture, float intensity, int maxCount, float minDist)
{
  Voronoi(g_Texture, intensity, maxCount, minDist);
}

void op_mix(Picture, int idx, float alpha)
{
  const other = getStoredTexture(idx);

  if(other.NPixels != g_Texture.NPixels)
    throw new Exception("Texture must have the same size");

  foreach(i, ref pel; g_Texture.Data[0 .. g_Texture.NPixels])
    pel = mix(pel, other.Data[i], alpha);
}

void op_bump(Picture, int baseTexIdx, int bumpMapIdx, Vec3 p, Vec3 d, Vec3 ambient, Vec3 diffuse)
{
  int directional = 1;

  const baseTex = getStoredTexture(baseTexIdx);

  if(baseTex.NPixels != g_Texture.NPixels)
    throw new Exception("Texture must have the same size");

  const bumpMap = getStoredTexture(bumpMapIdx);

  if(bumpMap.NPixels != g_Texture.NPixels)
    throw new Exception("Texture must have the same size");

  Bump(g_Texture, *baseTex, *bumpMap, null, null, p.x, p.y, p.z, d.x, d.y, d.z, toPixel(ambient), toPixel(
         diffuse), directional ? 1 : 0);
}

void op_rect(Picture, float orgx, float orgy, float ux, float uy, float vx, float vy, float rectu, float rectv)
{
  auto grad = Texture(2, 1);
  grad.Data[0] = WHITE_MASK;
  grad.Data[1] = BLACK_MASK;

  auto src = cloneTexture(g_Texture);
  scope(exit) destroy(*src);

  GlowRect(g_Texture, *src, grad, orgx, orgy, ux, uy, vx, vy, rectu, rectv);
}

void op_mul(Picture, float f)
{
  foreach(i, ref pel; g_Texture.Data[0 .. g_Texture.NPixels])
  {
    pel.r *= f;
    pel.g *= f;
    pel.b *= f;
    pel.a *= f;
  }
}

void op_offset(Picture, float r, float g, float b, float a)
{
  foreach(i, ref pel; g_Texture.Data[0 .. g_Texture.NPixels])
  {
    pel.r += r;
    pel.g += g;
    pel.b += b;
    pel.a += a;
  }
}

ktg.Pixel toPixel(Vec3 v)
{
  static auto rescale(float val)
  {
    return cast(ubyte) clamp(val* 256, 0, 255);
  }

  return ktg.Color(rescale(v.x), rescale(v.y), rescale(v.z));
}

ktg.Pixel mix(ktg.Pixel A, ktg.Pixel B, float alpha)
{
  ktg.Pixel result;
  result.r = cast(ushort) blend(cast(float)A.r, cast(float)B.b, alpha);
  result.g = cast(ushort) blend(cast(float)A.g, cast(float)B.g, alpha);
  result.b = cast(ushort) blend(cast(float)A.b, cast(float)B.b, alpha);
  result.a = cast(ushort) blend(cast(float)A.a, cast(float)B.a, alpha);
  return result;
}

Texture* getStoredTexture(int idx)
{
  const otherId = clampTextureIndex(idx);
  auto other = g_Textures[otherId];

  if(other is null)
    throw new Exception("No texture at this index");

  return other;
}

int clampTextureIndex(int idx)
{
  return clamp(idx, 0, cast(int)(g_Textures.length - 1));
}

static this()
{
  g_Operations["texture"] = RealizeFunc("txt", &op_texture);
  g_Operations["display"] = RealizeFunc("txt", &op_display);
  registerOperator!(op_store, "txt", "tstore")();
  registerOperator!(op_load, "txt", "tload")();
  registerOperator!(op_noise, "txt", "tnoise")();
  registerOperator!(op_derive, "txt", "tderive")();
  registerOperator!(op_voronoi, "txt", "tvoronoi")();
  registerOperator!(op_mix, "txt", "tmix")();
  registerOperator!(op_blur, "txt", "tblur")();
  registerOperator!(op_bump, "txt", "tbump")();
  registerOperator!(op_rect, "txt", "trect")();
  registerOperator!(op_mul, "txt", "tmul")();
  registerOperator!(op_offset, "txt", "toffset")();
}

