/**
 * @file filters.cpp
 * @brief Filters that act on one texture as input
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
#include "helpers.h"
#include <cstring>

void ColorMatrixTransform(Texture* dest, const Texture& x, Matrix44& matrix, bool clampPremult)
{
  int m[4][4];

  assert(dest->SameSize(x));

  for(int i = 0; i < 4; i++)
  {
    for(int j = 0; j < 4; j++)
    {
      assert(matrix[i][j] >= -127.0f && matrix[i][j] <= 127.0f);
      m[i][j] = matrix[i][j] * 65536.0f;
    }
  }

  for(int i = 0; i < dest->NPixels; i++)
  {
    auto& out = dest->Data[i];
    auto in = x.Data[i];

    auto r = MulShift16(m[0][0], in.r) + MulShift16(m[0][1], in.g) + MulShift16(m[0][2], in.b) + MulShift16(m[0][3], in.a);
    auto g = MulShift16(m[1][0], in.r) + MulShift16(m[1][1], in.g) + MulShift16(m[1][2], in.b) + MulShift16(m[1][3], in.a);
    auto b = MulShift16(m[2][0], in.r) + MulShift16(m[2][1], in.g) + MulShift16(m[2][2], in.b) + MulShift16(m[2][3], in.a);
    auto a = MulShift16(m[3][0], in.r) + MulShift16(m[3][1], in.g) + MulShift16(m[3][2], in.b) + MulShift16(m[3][3], in.a);

    if(clampPremult)
    {
      out.a = clamp<int>(a, 0, 65535);
      out.r = clamp<int>(r, 0, out.a);
      out.g = clamp<int>(g, 0, out.a);
      out.b = clamp<int>(b, 0, out.a);
    }
    else
    {
      out.r = clamp<int>(r, 0, 65535);
      out.g = clamp<int>(g, 0, 65535);
      out.b = clamp<int>(b, 0, 65535);
      out.a = clamp<int>(a, 0, 65535);
    }
  }
}

void CoordMatrixTransform(Texture* dest, const Texture& in, Matrix44& matrix, int mode)
{
  int scaleX = 1 << (24 - dest->ShiftX);
  int scaleY = 1 << (24 - dest->ShiftY);

  int dudx = matrix[0][0] * scaleX;
  int dudy = matrix[0][1] * scaleY;
  int dvdx = matrix[1][0] * scaleX;
  int dvdy = matrix[1][1] * scaleY;

  int u0 = matrix[0][3] * (1 << 24) + ((dudx + dudy) >> 1);
  int v0 = matrix[1][3] * (1 << 24) + ((dvdx + dvdy) >> 1);
  Pixel* out = dest->Data;

  for(int y = 0; y < dest->YRes; y++)
  {
    int u = u0;
    int v = v0;

    for(int x = 0; x < dest->XRes; x++)
    {
      in.SampleFiltered(*out, u, v, mode);

      u += dudx;
      v += dvdx;
      out++;
    }

    u0 += dudy;
    v0 += dvdy;
  }
}

void ColorRemap(Texture* dest, const Texture& inTex, const Texture& mapR, const Texture& mapG, const Texture& mapB)
{
  assert(dest->SameSize(inTex));

  for(int i = 0; i < dest->NPixels; i++)
  {
    const Pixel& in = inTex.Data[i];
    Pixel& out = dest->Data[i];

    if(in.a == 65535) // alpha==1, everything easy.
    {
      Pixel colR, colG, colB;

      mapR.SampleGradient(colR, (in.r << 8) + ((in.r + 128) >> 8));
      mapG.SampleGradient(colG, (in.g << 8) + ((in.g + 128) >> 8));
      mapB.SampleGradient(colB, (in.b << 8) + ((in.b + 128) >> 8));

      out.r = min(colR.r + colG.r + colB.r, 65535);
      out.g = min(colR.g + colG.g + colB.g, 65535);
      out.b = min(colR.b + colG.b + colB.b, 65535);
      out.a = in.a;
    }
    else if(in.a) // alpha!=0
    {
      Pixel colR, colG, colB;
      uint32_t invA = (65535U << 16) / in.a;

      mapR.SampleGradient(colR, UMulShift8(min(in.r, in.a), invA));
      mapG.SampleGradient(colG, UMulShift8(min(in.g, in.a), invA));
      mapB.SampleGradient(colB, UMulShift8(min(in.b, in.a), invA));

      out.r = MulIntens(min(colR.r + colG.r + colB.r, 65535), in.a);
      out.g = MulIntens(min(colR.g + colG.g + colB.g, 65535), in.a);
      out.b = MulIntens(min(colR.b + colG.b + colB.b, 65535), in.a);
      out.a = in.a;
    }
    else // alpha==0
      out = in;
  }
}

void CoordRemap(Texture* dest, const Texture& in, const Texture& remapTex, sF32 strengthU, sF32 strengthV, int mode)
{
  assert(dest->SameSize(remapTex));

  const Pixel* remap = remapTex.Data;
  Pixel* out = dest->Data;

  int u0 = dest->MinX;
  int v0 = dest->MinY;
  int scaleU = (1 << 24) * strengthU;
  int scaleV = (1 << 24) * strengthV;
  int stepU = 1 << (24 - dest->ShiftX);
  int stepV = 1 << (24 - dest->ShiftY);

  for(int y = 0; y < dest->YRes; y++)
  {
    int u = u0;
    int v = v0;

    for(int x = 0; x < dest->XRes; x++)
    {
      int dispU = u + MulShift16(scaleU, (remap->r - 32768) * 2);
      int dispV = v + MulShift16(scaleV, (remap->g - 32768) * 2);
      in.SampleFiltered(*out, dispU, dispV, mode);

      u += stepU;
      remap++;
      out++;
    }

    v0 += stepV;
  }
}

void Derive(Texture* dest, const Texture& in, DeriveOp op, sF32 strength)
{
  assert(dest->SameSize(in));

  Pixel* out = dest->Data;

  const auto XRes = dest->XRes;
  const auto YRes = dest->YRes;

  for(int y = 0; y < YRes; y++)
  {
    for(int x = 0; x < XRes; x++)
    {
      int dx2 = in.Data[y * XRes + ((x + 1) & (XRes - 1))].r - in.Data[y * XRes + ((x - 1) & (XRes - 1))].r;
      int dy2 = in.Data[x + ((y + 1) & (YRes - 1)) * XRes].r - in.Data[x + ((y - 1) & (YRes - 1)) * XRes].r;
      sF32 dx = dx2 * strength / (2 * 65535.0f);
      sF32 dy = dy2 * strength / (2 * 65535.0f);
      switch(op)
      {
      case DeriveGradient:
        out->r = clamp<int>(dx * 32768.0f + 32768.0f, 0, 65535);
        out->g = clamp<int>(dy * 32768.0f + 32768.0f, 0, 65535);
        out->b = 0;
        out->a = 65535;
        break;

      case DeriveNormals:
        {
          // (1 0 dx)^T x (0 1 dy)^T = (-dx -dy 1)
          sF32 scale = 32768.0f * sFInvSqrt(1.0f + dx * dx + dy * dy);

          out->r = clamp<int>(-dx * scale + 32768.0f, 0, 65535);
          out->g = clamp<int>(-dy * scale + 32768.0f, 0, 65535);
          out->b = clamp<int>(scale + 32768.0f, 0, 65535);
          out->a = 65535;
        }
        break;
      }

      out++;
    }
  }
}

// Wrap computation on pixel coordinates
static int WrapCoord(int x, int width, int mode)
{
  if(mode == 0) // wrap
    return x & (width - 1);
  else
    return clamp(x, 0, width - 1);
}

// Size is half of edge length in pixels, 26.6 fixed point
static void Blur1DBuffer(Pixel* dst, const Pixel* src, int width, int sizeFixed, int wrapMode)
{
  assert(sizeFixed > 32); // kernel should be wider than one pixel
  int frac = (sizeFixed - 32) & 63;
  int offset = (sizeFixed + 32) >> 6;

  assert(((offset - 1) * 64 + frac + 32) == sizeFixed);
  uint32_t denom = sizeFixed * 2;
  uint32_t bias = denom / 2;

  // initialize accumulators
  uint32_t accu[4];

  if(wrapMode == 0) // wrap around
  {
    // leftmost and rightmost pixels (the partially covered ones)
    int xl = WrapCoord(-offset, width, wrapMode);
    int xr = WrapCoord(offset, width, wrapMode);
    accu[0] = frac * (src[xl].r + src[xr].r) + bias;
    accu[1] = frac * (src[xl].g + src[xr].g) + bias;
    accu[2] = frac * (src[xl].b + src[xr].b) + bias;
    accu[3] = frac * (src[xl].a + src[xr].a) + bias;

    // inner part of filter kernel
    for(int x = -offset + 1; x <= offset - 1; x++)
    {
      int xc = WrapCoord(x, width, wrapMode);

      accu[0] += src[xc].r << 6;
      accu[1] += src[xc].g << 6;
      accu[2] += src[xc].b << 6;
      accu[3] += src[xc].a << 6;
    }
  }
  else // clamp on edge
  {
    // on the left edge, the first pixel is repeated over and over
    accu[0] = src[0].r * (sizeFixed + 32) + bias;
    accu[1] = src[0].g * (sizeFixed + 32) + bias;
    accu[2] = src[0].b * (sizeFixed + 32) + bias;
    accu[3] = src[0].a * (sizeFixed + 32) + bias;

    // rightmost pixel
    int xr = WrapCoord(offset, width, wrapMode);
    accu[0] += frac * src[xr].r;
    accu[1] += frac * src[xr].g;
    accu[2] += frac * src[xr].b;
    accu[3] += frac * src[xr].a;

    // inner part of filter kernel (the right half)
    for(int x = 1; x <= offset - 1; x++)
    {
      int xc = WrapCoord(x, width, wrapMode);

      accu[0] += src[xc].r << 6;
      accu[1] += src[xc].g << 6;
      accu[2] += src[xc].b << 6;
      accu[3] += src[xc].a << 6;
    }
  }

  // generate output pixels
  for(int x = 0; x < width; x++)
  {
    // write out state of accumulator
    dst[x].r = accu[0] / denom;
    dst[x].g = accu[1] / denom;
    dst[x].b = accu[2] / denom;
    dst[x].a = accu[3] / denom;

    // update accumulator
    int xl0 = WrapCoord(x - offset + 0, width, wrapMode);
    int xl1 = WrapCoord(x - offset + 1, width, wrapMode);
    int xr0 = WrapCoord(x + offset + 0, width, wrapMode);
    int xr1 = WrapCoord(x + offset + 1, width, wrapMode);

    accu[0] += 64 * (src[xr0].r - src[xl1].r) + frac * (src[xr1].r - src[xr0].r - src[xl0].r + src[xl1].r);
    accu[1] += 64 * (src[xr0].g - src[xl1].g) + frac * (src[xr1].g - src[xr0].g - src[xl0].g + src[xl1].g);
    accu[2] += 64 * (src[xr0].b - src[xl1].b) + frac * (src[xr1].b - src[xr0].b - src[xl0].b + src[xl1].b);
    accu[3] += 64 * (src[xr0].a - src[xl1].a) + frac * (src[xr1].a - src[xr0].a - src[xl0].a + src[xl1].a);
  }
}

void Blur(Texture* dest, const Texture& inImg, sF32 sizex, sF32 sizey, int order, int wrapMode)
{
  assert(dest->SameSize(inImg));

  int sizePixX = clamp(sizex, 0.0f, 1.0f) * 64 * inImg.XRes / 2;
  int sizePixY = clamp(sizey, 0.0f, 1.0f) * 64 * inImg.YRes / 2;

  // no blur at all? just copy!
  if(order < 1 || (sizePixX <= 32 && sizePixY <= 32))
  {
    *dest = inImg;
    return;
  }

  auto const XRes = dest->XRes;
  auto const YRes = dest->YRes;

  // allocate pixel buffers
  int bufSize = max(XRes, YRes);

  vector<Pixel> buf1_mem(bufSize);
  vector<Pixel> buf2_mem(bufSize);

  Pixel* buf1 = buf1_mem.data();
  Pixel* buf2 = buf2_mem.data();
  const Texture* input = &inImg;

  // horizontal blur
  if(sizePixX > 32)
  {
    // go through image row by row
    for(int y = 0; y < YRes; y++)
    {
      // copy pixels into buffer 1
      memcpy(buf1, &input->Data[y * XRes], XRes * sizeof(Pixel));

      // blur order times, ping-ponging between buffers
      for(int i = 0; i < order; i++)
      {
        Blur1DBuffer(buf2, buf1, XRes, sizePixX, (wrapMode & ClampU) ? 1 : 0);
        swap(buf1, buf2);
      }

      // copy pixels back
      memcpy(&dest->Data[y * XRes], buf1, XRes * sizeof(Pixel));
    }

    input = dest;
  }

  // vertical blur
  if(sizePixY > 32)
  {
    // go through image column by column
    for(int x = 0; x < XRes; x++)
    {
      // copy pixels into buffer 1
      const Pixel* src = &input->Data[x];
      Pixel* dst = buf1;

      for(int y = 0; y < YRes; y++)
      {
        *dst++ = *src;
        src += XRes;
      }

      // blur order times, ping-ponging between buffers
      for(int i = 0; i < order; i++)
      {
        Blur1DBuffer(buf2, buf1, YRes, sizePixY, (wrapMode & ClampV) ? 1 : 0);
        swap(buf1, buf2);
      }

      // copy pixels back
      src = buf1;
      dst = &dest->Data[x];

      for(int y = 0; y < YRes; y++)
      {
        *dst = *src++;
        dst += XRes;
      }
    }
  }
}

