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
import gentexture;

static __gshared GenTexture* g_Texture;
static __gshared GenTexture*[16] g_Textures;

///////////////////////////////////////////////////////////////////////////////

void op_texture(EditionState state, Value[] values)
{
  if(values.length != 1)
    throw new Exception("texture takes one Vec2 argument");

  auto size = asVec2(values[0]);

  size.x = max(size.x, 16);
  size.y = max(size.y, 16);
  g_Texture = new GenTexture(cast(int)size.x, cast(int)size.y);

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

void op_store(Picture, float fIndex)
{
  const id = toTextureIndex(fIndex);

  destroy(g_Textures[id]);
  g_Textures[id] = cloneTexture(g_Texture);
}

void op_load(Picture, float fIndex)
{
  const id = toTextureIndex(fIndex);

  destroy(g_Texture);
  g_Texture = cloneTexture(g_Textures[id]);
}

int toTextureIndex(float fIndex)
{
  return clamp(cast(int)fIndex, 0, int(g_Textures.length));
}

///////////////////////////////////////////////////////////////////////////////

void op_noise(Picture, float freqx, float freqy, float octaves, float falloff)
{
  auto grad = GenTexture(2, 1);
  grad.Data[0].Init(0xffffffff);
  grad.Data[1].Init(0x00000000);

  g_Texture.Noise(grad, to!int (freqx), to!int (freqy), to!int (octaves), falloff, 123, NoiseMode.NoiseDirect | NoiseMode.NoiseBandlimit | NoiseMode.NoiseNormalize);
}

void op_derive(Picture, float fop, float strength)
{
  auto oldTexture = g_Texture;
  g_Texture = cloneTexture(oldTexture);
  auto op = floatToEnum!DeriveOp(fop);
  g_Texture.Derive(*oldTexture, op, strength);
  destroy(*oldTexture);
}

GenTexture* cloneTexture(const GenTexture* oldTexture)
{
  auto pText = new GenTexture(oldTexture.XRes, oldTexture.YRes);

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

void op_voronoi(Picture, float intensity, float fmaxCount, float minDist)
{
  Random gen;

  auto maxCount = min(256, cast(int)fmaxCount);
  CellCenter centers[256];

  auto grad = GenTexture(2, 1);
  grad.Data[0].Init(0xffffffff);
  grad.Data[1].Init(0x00000000);

  // generate random center points
  for(int i = 0; i < maxCount; i++)
  {
    int intens = uniform(0, cast(int)(intensity * 256), gen);

    centers[i].x = uniform(0.0f, 1.0f, gen);
    centers[i].y = uniform(0.0f, 1.0f, gen);
    centers[i].color = Color(intens, intens, intens, 255);
  }

  // remove points too close together
  const minDistSq = minDist * minDist;

  for(int i = 1; i < maxCount;)
  {
    const x = centers[i].x;
    const y = centers[i].y;

    // try to find a point closer than minDist
    int j;

    for(j = 0; j < i; j++)
    {
      auto dx = centers[j].x - x;
      auto dy = centers[j].y - y;

      if(dx < 0.0f)
        dx += 1.0f;

      if(dy < 0.0f)
        dy += 1.0f;

      dx = min(dx, 1.0f - dx);
      dy = min(dy, 1.0f - dy);

      if(dx * dx + dy * dy < minDistSq) // point is too close, stop
        break;
    }

    if(j < i) // we found such a point
      centers[i] = centers[--maxCount]; // remove this one
    else // accept this one
      i++;
  }

  // generate the image
  g_Texture.Cells(grad, centers.ptr, maxCount, 0.0f, CellMode.CellInner);
}

void op_mix(Picture, float fIndex, float alpha)
{
  const otherId = toTextureIndex(fIndex);
  auto other = g_Textures[otherId];

  if(other is null)
    throw new Exception("No texture at this index");

  if(other.NPixels != g_Texture.NPixels)
    throw new Exception("Texture must have the same size");

  foreach(i, ref pel; g_Texture.Data[0 .. g_Texture.NPixels])
    pel = mix(pel, other.Data[i], alpha);
}

gentexture.Pixel mix(gentexture.Pixel A, gentexture.Pixel B, float alpha)
{
  gentexture.Pixel result;
  result.r = cast(ushort) blend(cast(float)A.r, cast(float)B.b, alpha);
  result.g = cast(ushort) blend(cast(float)A.g, cast(float)B.g, alpha);
  result.b = cast(ushort) blend(cast(float)A.b, cast(float)B.b, alpha);
  result.a = cast(ushort) blend(cast(float)A.a, cast(float)B.a, alpha);
  return result;
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
}

