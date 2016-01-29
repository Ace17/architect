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

import misc;

import execute;
import value;
import dashboard_picture;
import gentexture;

static __gshared GenTexture* g_Texture;

///////////////////////////////////////////////////////////////////////////////

void op_texture(EditionState state, Value[] values)
{
  if(values.length != 1)
    throw new Exception("texture takes one Vec2 argument");

  auto size = asVec2(values[0]);

  size.x = max(size.x, 16);
  size.y = max(size.y, 16);
  g_Texture = new GenTexture(cast(int)size.x, cast(int)size.y);


  for(int i=0;i < g_Texture.NPixels;++i)
  {
    g_Texture.Data[i].r = 0;
    g_Texture.Data[i].g = 255;
    g_Texture.Data[i].b = 0;
    g_Texture.Data[i].a = 0;
  }
}

void op_save(EditionState state, Value[] a)
{
  auto pic = new Picture;
  const w = cast(int)g_Texture.XRes;
  const h = cast(int)g_Texture.YRes;
  pic.data.length = w * h;

  for(int i=0;i < g_Texture.NPixels;++i)
  {
    pic.data[i].r = g_Texture.Data[i].r/65536.0f;
    pic.data[i].g = g_Texture.Data[i].g/65536.0f;
    pic.data[i].b = g_Texture.Data[i].b/65536.0f;
    pic.data[i].a = g_Texture.Data[i].a/65536.0f;
  }

  state.board = pic;
}

///////////////////////////////////////////////////////////////////////////////

void op_noise(Picture pic, float freqx, float freqy, float octaves, float falloff)
{
  auto grad = GenTexture(2, 1);
  grad.Data[0].Init(0xffffffff);
  grad.Data[1].Init(0x00000000);

  g_Texture.Noise(grad, to!int(freqx), to!int(freqy), to!int(octaves), falloff, 123, NoiseMode.NoiseDirect | NoiseMode.NoiseBandlimit | NoiseMode.NoiseNormalize);
}

void op_derive(Picture pic, float fop, float strength)
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
  for(int i=0;i < pText.NPixels;++i)
    pText.Data[i] = oldTexture.Data[i];
  return pText;
}

T floatToEnum(T)(float input)
{
  const min = 0;
  const max = cast(int)T.max;
  return cast(T)clamp(cast(int)input, min, max);
}

static this()
{
  g_Operations["texture"] = RealizeFunc("txt", &op_texture);
  g_Operations["save"] = RealizeFunc("txt", &op_save);
  registerOperator!(op_noise, "txt", "tnoise")();
  registerOperator!(op_derive, "txt", "tderive")();
}

