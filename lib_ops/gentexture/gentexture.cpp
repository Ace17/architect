/**
 * @file gentexture.cpp
 * @brief Base texture class
 * @author Sebastien Alaiwan
 * @date 2016-03-06
 */

/*
 * Copyright (C) 2016 - Sebastien Alaiwan
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 */

#include "gentexture.h"
#include <cmath>
#include <vector>
#include <cstring>
#include "helpers.h"

/****************************************************************************/
/***                                                                      ***/
/***   Pixel                                                              ***/
/***                                                                      ***/
/****************************************************************************/

void Pixel::Init(uint8_t _r, uint8_t _g, uint8_t _b, uint8_t _a)
{
  r = (_r << 8) | _r;
  g = (_g << 8) | _g;
  b = (_b << 8) | _b;
  a = (_a << 8) | _a;
}

void Pixel::Init(uint32_t rgba)
{
  auto rv = (rgba >> 16) & 0xff;
  auto gv = (rgba >> 8) & 0xff;
  auto bv = (rgba >> 0) & 0xff;
  auto av = (rgba >> 24) & 0xff;

  a = (av << 8) | av;
  r = MulIntens((rv << 8) | rv, a);
  g = MulIntens((gv << 8) | gv, a);
  b = MulIntens((bv << 8) | bv, a);
}

void Pixel::Lerp(int t, Pixel x, Pixel y)
{
  r = ::Lerp(t, x.r, y.r);
  g = ::Lerp(t, x.g, y.g);
  b = ::Lerp(t, x.b, y.b);
  a = ::Lerp(t, x.a, y.a);
}

void Pixel::CompositeAdd(Pixel x)
{
  r = clamp<int>(r + x.r, 0, 65535);
  g = clamp<int>(g + x.g, 0, 65535);
  b = clamp<int>(b + x.b, 0, 65535);
  a = clamp<int>(a + x.a, 0, 65535);
}

void Pixel::CompositeMulC(Pixel x)
{
  r = MulIntens(r, x.r);
  g = MulIntens(g, x.g);
  b = MulIntens(b, x.b);
  a = MulIntens(a, x.a);
}

void Pixel::CompositeROver(Pixel x)
{
  int transIn = 65535 - x.a;
  r = MulIntens(transIn, r) + x.r;
  g = MulIntens(transIn, g) + x.g;
  b = MulIntens(transIn, b) + x.b;
  a = MulIntens(transIn, a) + x.a;
}

void Pixel::CompositeScreen(Pixel x)
{
  r += MulIntens(x.r, 65535 - r);
  g += MulIntens(x.g, 65535 - g);
  b += MulIntens(x.b, 65535 - b);
  a += MulIntens(x.a, 65535 - a);
}

/****************************************************************************/
/***                                                                      ***/
/***   Texture                                                         ***/
/***                                                                      ***/
/****************************************************************************/

void Texture::__ctor(int xres, int yres)
{
  Data = 0;
  XRes = 0;
  YRes = 0;

  Init(xres, yres);
}

Texture::Texture()
{
  Data = 0;
  XRes = 0;
  YRes = 0;

  UpdateSize();
}

Texture::Texture(int xres, int yres)
{
  Data = 0;
  XRes = 0;
  YRes = 0;

  Init(xres, yres);
}

Texture::Texture(const Texture& x)
{
  XRes = x.XRes;
  YRes = x.YRes;
  UpdateSize();

  Data = new Pixel[NPixels];
  memcpy(Data, x.Data, NPixels * sizeof(Pixel));
}

Texture::~Texture()
{
  Free();
}

void Texture::Free()
{
  delete[] Data;
}

void Texture::Init(int xres, int yres)
{
  if(XRes != xres || YRes != yres)
  {
    delete[] Data;

    assert(IsPowerOf2(xres));
    assert(IsPowerOf2(yres));

    XRes = xres;
    YRes = yres;
    UpdateSize();

    Data = new Pixel[NPixels];
  }
}

void Texture::UpdateSize()
{
  NPixels = XRes * YRes;
  ShiftX = FloorLog2(XRes);
  ShiftY = FloorLog2(YRes);

  MinX = 1 << (24 - 1 - ShiftX);
  MinY = 1 << (24 - 1 - ShiftY);
}

void Texture::Swap(Texture& x)
{
  swap(Data, x.Data);
  swap(XRes, x.XRes);
  swap(YRes, x.YRes);
  swap(NPixels, x.NPixels);
  swap(ShiftX, x.ShiftX);
  swap(ShiftY, x.ShiftY);
  swap(MinX, x.MinX);
  swap(MinY, x.MinY);
}

Texture & Texture::operator = (const Texture& x)
{
  Texture t = x;

  Swap(t);
  return *this;
}

bool Texture::SameSize(const Texture& x) const
{
  return XRes == x.XRes && YRes == x.YRes;
}

// ---- Sampling helpers
void Texture::SampleNearest(Pixel& result, int x, int y, int wrapMode) const
{
  if(wrapMode & 1)
    x = clamp(x, MinX, 0x1000000 - MinX);

  if(wrapMode & 2)
    y = clamp(y, MinY, 0x1000000 - MinY);

  x &= 0xffffff;
  y &= 0xffffff;

  int ix = x >> (24 - ShiftX);
  int iy = y >> (24 - ShiftY);

  result = Data[(iy << ShiftX) + ix];
}

void Texture::SampleBilinear(Pixel& result, int x, int y, int wrapMode) const
{
  if(wrapMode & 1)
    x = clamp(x, MinX, 0x1000000 - MinX);

  if(wrapMode & 2)
    y = clamp(y, MinY, 0x1000000 - MinY);

  x = (x - MinX) & 0xffffff;
  y = (y - MinY) & 0xffffff;

  int x0 = x >> (24 - ShiftX);
  int x1 = (x0 + 1) & (XRes - 1);
  int y0 = y >> (24 - ShiftY);
  int y1 = (y0 + 1) & (YRes - 1);
  int fx = uint32_t(x << (ShiftX + 8)) >> 16;
  int fy = uint32_t(y << (ShiftY + 8)) >> 16;

  Pixel t0, t1;
  t0.Lerp(fx, Data[(y0 << ShiftX) + x0], Data[(y0 << ShiftX) + x1]);
  t1.Lerp(fx, Data[(y1 << ShiftX) + x0], Data[(y1 << ShiftX) + x1]);
  result.Lerp(fy, t0, t1);
}

void Texture::SampleFiltered(Pixel& result, int x, int y, int filterMode) const
{
  if(filterMode & FilterBilinear)
    SampleBilinear(result, x, y, filterMode);
  else
    SampleNearest(result, x, y, filterMode);
}

void Texture::SampleGradient(Pixel& result, int x) const
{
  x = clamp(x, 0, 1 << 24);
  x -= x >> ShiftX; // x=(1<<24) -> Take rightmost pixel

  int x0 = x >> (24 - ShiftX);
  int x1 = (x0 + 1) & (XRes - 1);
  int fx = uint32_t(x << (ShiftX + 8)) >> 16;

  result.Lerp(fx, Data[x0], Data[x1]);
}

