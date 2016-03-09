/**
 * @file combiners.cpp
 * @brief Filters that take multiple textures as inputs.
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

void Ternary(Texture* dest, const Texture& in1Tex, const Texture& in2Tex, const Texture& in3Tex, TernaryOp op)
{
  assert(dest->SameSize(in1Tex) && dest->SameSize(in2Tex) && dest->SameSize(in3Tex));

  for(int i = 0; i < dest->NPixels; i++)
  {
    Pixel& out = dest->Data[i];
    const Pixel& in1 = in1Tex.Data[i];
    const Pixel& in2 = in2Tex.Data[i];
    const Pixel& in3 = in3Tex.Data[i];
    switch(op)
    {
    case TernaryLerp:
      out.r = MulIntens(65535 - in3.r, in1.r) + MulIntens(in3.r, in2.r);
      out.g = MulIntens(65535 - in3.r, in1.g) + MulIntens(in3.r, in2.g);
      out.b = MulIntens(65535 - in3.r, in1.b) + MulIntens(in3.r, in2.b);
      out.a = MulIntens(65535 - in3.r, in1.a) + MulIntens(in3.r, in2.a);
      break;

    case TernarySelect:
      out = (in3.r >= 32768) ? in2 : in1;
      break;
    }
  }
}

void Paste(Texture* dest, const Texture& bgTex, const Texture& inTex, sF32 orgx, sF32 orgy, sF32 ux, sF32 uy, sF32 vx, sF32 vy, CombineOp op, int mode)
{
  assert(dest->SameSize(bgTex));

  // copy background over (if this image is not the background already)
  if(dest != &bgTex)
    *dest = bgTex;

  auto const XRes = dest->XRes;
  auto const YRes = dest->YRes;

  // calculate bounding rect
  int minX = max<int>(0, floor((orgx + min(ux, 0.0f) + min(vx, 0.0f)) * XRes));
  int minY = max<int>(0, floor((orgy + min(uy, 0.0f) + min(vy, 0.0f)) * YRes));
  int maxX = min<int>(XRes - 1, ceil((orgx + max(ux, 0.0f) + max(vx, 0.0f)) * XRes));
  int maxY = min<int>(YRes - 1, ceil((orgy + max(uy, 0.0f) + max(vy, 0.0f)) * YRes));

  // solve for u0,v0 and deltas (Cramer's rule)
  sF32 detM = ux * vy - uy * vx;

  if(fabs(detM) * XRes * YRes < 0.25f) // smaller than a pixel? skip it.
    return;

  sF32 invM = (1 << 24) / detM;
  sF32 rmx = (minX + 0.5f) / XRes - orgx;
  sF32 rmy = (minY + 0.5f) / YRes - orgy;
  int u0 = (rmx * vy - rmy * vx) * invM;
  int v0 = (ux * rmy - uy * rmx) * invM;
  int dudx = vy * invM / XRes;
  int dvdx = -uy * invM / XRes;
  int dudy = -vx * invM / YRes;
  int dvdy = ux * invM / YRes;

  for(int y = minY; y <= maxY; y++)
  {
    Pixel* out = &dest->Data[y * XRes + minX];
    int u = u0;
    int v = v0;

    for(int x = minX; x <= maxX; x++)
    {
      if(u >= 0 && u < 0x1000000 && v >= 0 && v < 0x1000000)
      {
        Pixel in;
        int transIn, transOut;

        inTex.SampleFiltered(in, u, v, ClampU | ClampV | ((mode & 1) ? FilterBilinear : FilterNearest));
        switch(op)
        {
        case CombineAdd:
          out->r = min(out->r + in.r, 65535);
          out->g = min(out->g + in.g, 65535);
          out->b = min(out->b + in.b, 65535);
          out->a = min(out->a + in.a, 65535);
          break;

        case CombineSub:
          out->r = max<int>(out->r - in.r, 0);
          out->g = max<int>(out->g - in.g, 0);
          out->b = max<int>(out->b - in.b, 0);
          out->a = max<int>(out->a - in.a, 0);
          break;

        case CombineMulC:
          out->r = MulIntens(out->r, in.r);
          out->g = MulIntens(out->g, in.g);
          out->b = MulIntens(out->b, in.b);
          out->a = MulIntens(out->a, in.a);
          break;

        case CombineMin:
          out->r = min(out->r, in.r);
          out->g = min(out->g, in.g);
          out->b = min(out->b, in.b);
          out->a = min(out->a, in.a);
          break;

        case CombineMax:
          out->r = max(out->r, in.r);
          out->g = max(out->g, in.g);
          out->b = max(out->b, in.b);
          out->a = max(out->a, in.a);
          break;

        case CombineSetAlpha:
          out->a = in.r;
          break;

        case CombinePreAlpha:
          out->r = MulIntens(out->r, in.r);
          out->g = MulIntens(out->g, in.r);
          out->b = MulIntens(out->b, in.r);
          out->a = in.g;
          break;

        case CombineOver:
          transIn = 65535 - in.a;

          out->r = MulIntens(transIn, out->r) + in.r;
          out->g = MulIntens(transIn, out->g) + in.g;
          out->b = MulIntens(transIn, out->b) + in.b;
          out->a += MulIntens(in.a, 65535 - out->a);
          break;

        case CombineMultiply:
          transIn = 65535 - in.a;
          transOut = 65535 - out->a;

          out->r = MulIntens(transIn, out->r) + MulIntens(transOut, in.r) + MulIntens(in.r, out->r);
          out->g = MulIntens(transIn, out->g) + MulIntens(transOut, in.g) + MulIntens(in.g, out->g);
          out->b = MulIntens(transIn, out->b) + MulIntens(transOut, in.b) + MulIntens(in.b, out->b);
          out->a += MulIntens(in.a, transOut);
          break;

        case CombineScreen:
          out->r += MulIntens(in.r, 65535 - out->r);
          out->g += MulIntens(in.g, 65535 - out->g);
          out->b += MulIntens(in.b, 65535 - out->b);
          out->a += MulIntens(in.a, 65535 - out->a);
          break;

        case CombineDarken:
          out->r += in.r - max(MulIntens(in.r, out->a), MulIntens(out->r, in.a));
          out->g += in.g - max(MulIntens(in.g, out->a), MulIntens(out->g, in.a));
          out->b += in.b - max(MulIntens(in.b, out->a), MulIntens(out->b, in.a));
          out->a += MulIntens(in.a, 65535 - out->a);
          break;

        case CombineLighten:
          out->r += in.r - min(MulIntens(in.r, out->a), MulIntens(out->r, in.a));
          out->g += in.g - min(MulIntens(in.g, out->a), MulIntens(out->g, in.a));
          out->b += in.b - min(MulIntens(in.b, out->a), MulIntens(out->b, in.a));
          out->a += MulIntens(in.a, 65535 - out->a);
          break;
        }
      }

      u += dudx;
      v += dvdx;
      out++;
    }

    u0 += dudy;
    v0 += dvdy;
  }
}

void Bump(Texture* dest, const Texture& surface, const Texture& normals, const Texture* specular, const Texture* falloffMap, sF32 px, sF32 py, sF32 pz, sF32 dx, sF32 dy, sF32 dz, Pixel ambient, Pixel diffuse, bool directional)
{
  assert(dest->SameSize(surface) && dest->SameSize(normals));

  sF32 L[3], H[3]; // light/halfway vector

  sF32 scale = sFInvSqrt(dx * dx + dy * dy + dz * dz);
  dx *= scale;
  dy *= scale;
  dz *= scale;

  if(directional)
  {
    L[0] = -dx;
    L[1] = -dy;
    L[2] = -dz;

    scale = sFInvSqrt(2.0f + 2.0f * L[2]); // 1/sqrt((L + <0,0,1>)^2)
    H[0] = L[0] * scale;
    H[1] = L[1] * scale;
    H[2] = (L[2] + 1.0f) * scale;
  }

  auto invX = 1.0f / dest->XRes;
  auto invY = 1.0f / dest->YRes;
  Pixel* out = dest->Data;
  const Pixel* surf = surface.Data;
  const Pixel* normal = normals.Data;

  for(int y = 0; y < dest->YRes; y++)
  {
    for(int x = 0; x < dest->XRes; x++)
    {
      // determine vectors to light
      if(!directional)
      {
        L[0] = px - (x + 0.5f) * invX;
        L[1] = py - (y + 0.5f) * invY;
        L[2] = pz;

        sF32 scale = sFInvSqrt(L[0] * L[0] + L[1] * L[1] + L[2] * L[2]);
        L[0] *= scale;
        L[1] *= scale;
        L[2] *= scale;

        // determine halfway vector
        if(specular)
        {
          sF32 scale = sFInvSqrt(2.0f + 2.0f * L[2]); // 1/sqrt((L + <0,0,1>)^2)
          H[0] = L[0] * scale;
          H[1] = L[1] * scale;
          H[2] = (L[2] + 1.0f) * scale;
        }
      }

      // fetch normal
      sF32 N[3];
      N[0] = (normal->r - 0x8000) / 32768.0f;
      N[1] = (normal->g - 0x8000) / 32768.0f;
      N[2] = (normal->b - 0x8000) / 32768.0f;

      // get falloff term if specified
      Pixel falloff;

      if(falloffMap)
      {
        sF32 spotTerm = max(dx * L[0] + dy * L[1] + dz * L[2], 0.0f);
        falloffMap->SampleGradient(falloff, spotTerm * (1 << 24));
      }

      // lighting calculation
      sF32 NdotL = max(N[0] * L[0] + N[1] * L[1] + N[2] * L[2], 0.0f);
      Pixel ambDiffuse;

      ambDiffuse.r = NdotL * diffuse.r;
      ambDiffuse.g = NdotL * diffuse.g;
      ambDiffuse.b = NdotL * diffuse.b;
      ambDiffuse.a = NdotL * diffuse.a;

      if(falloffMap)
        ambDiffuse.CompositeMulC(falloff);

      ambDiffuse.CompositeAdd(ambient);
      out->r = MulIntens(surf->r, ambDiffuse.r);
      out->g = MulIntens(surf->g, ambDiffuse.g);
      out->b = MulIntens(surf->b, ambDiffuse.b);
      out->a = MulIntens(surf->a, ambDiffuse.a);

      if(specular)
      {
        Pixel addTerm;
        sF32 NdotH = max(N[0] * H[0] + N[1] * H[1] + N[2] * H[2], 0.0f);
        specular->SampleGradient(addTerm, NdotH * (1 << 24));

        if(falloffMap)
          addTerm.CompositeMulC(falloff);

        out->r = clamp<int>(out->r + addTerm.r, 0, out->a);
        out->g = clamp<int>(out->g + addTerm.g, 0, out->a);
        out->b = clamp<int>(out->b + addTerm.b, 0, out->a);
      }

      out++;
      surf++;
      normal++;
    }
  }
}

void LinearCombine(Texture* dest, Pixel color, sF32 constWeight, const LinearInput* inputs, int nInputs)
{
  int w[256], uo[256], vo[256];

  assert(nInputs <= 255);
  assert(constWeight >= -127.0f && constWeight <= 127.0f);

  // convert weights and offsets to fixed point
  for(int i = 0; i < nInputs; i++)
  {
    assert(inputs[i].Weight >= -127.0f && inputs[i].Weight <= 127.0f);
    assert(inputs[i].UShift >= -127.0f && inputs[i].UShift <= 127.0f);
    assert(inputs[i].VShift >= -127.0f && inputs[i].VShift <= 127.0f);

    w[i] = inputs[i].Weight * 65536.0f;
    uo[i] = inputs[i].UShift * (1 << 24);
    vo[i] = inputs[i].VShift * (1 << 24);
  }

  // compute preweighted constant color
  int t = constWeight * 65536.0f;
  int c_r = MulShift16(t, color.r);
  int c_g = MulShift16(t, color.g);
  int c_b = MulShift16(t, color.b);
  int c_a = MulShift16(t, color.a);

  // calculate output image
  int u0 = dest->MinX;
  int v0 = dest->MinY;
  int stepU = 1 << (24 - dest->ShiftX);
  int stepV = 1 << (24 - dest->ShiftY);
  Pixel* out = dest->Data;

  for(int y = 0; y < dest->YRes; y++)
  {
    int u = u0;
    int v = v0;

    for(int x = 0; x < dest->XRes; x++)
    {
      // initialize accumulator with start value
      int acc_r = c_r;
      int acc_g = c_g;
      int acc_b = c_b;
      int acc_a = c_a;

      // accumulate inputs
      for(int j = 0; j < nInputs; j++)
      {
        const LinearInput& in = inputs[j];
        Pixel inPix;

        in.Tex->SampleFiltered(inPix, u + uo[j], v + vo[j], in.FilterMode);

        acc_r += MulShift16(w[j], inPix.r);
        acc_g += MulShift16(w[j], inPix.g);
        acc_b += MulShift16(w[j], inPix.b);
        acc_a += MulShift16(w[j], inPix.a);
      }

      // store (with clamping)
      out->r = clamp(acc_r, 0, 65535);
      out->g = clamp(acc_g, 0, 65535);
      out->b = clamp(acc_b, 0, 65535);
      out->a = clamp(acc_a, 0, 65535);

      // advance to next pixel
      u += stepU;
      out++;
    }

    v0 += stepV;
  }
}

