#include "gentexture.h"
#include "helpers.h"

// Perlin permutation table
static uint16_t Ptable[4096];
static uint32_t* Ptemp;

static int P(int i)
{
  return Ptable[i & 4095];
}

// Initialize perlin
static int InitPerlinCompare(const void* e1, const void* e2)
{
  unsigned i1 = Ptemp[*((uint16_t*)e1)];
  unsigned i2 = Ptemp[*((uint16_t*)e2)];

  return i1 - i2;
}

static void InitPerlin()
{
  uint32_t seed = 0x93638245u;
  Ptemp = new uint32_t[4096];

  // generate 4096 pseudorandom numbers using LFSR
  for(int i = 0; i < 4096; i++)
  {
    Ptemp[i] = seed;
    seed = (seed << 1) ^ ((seed & 0x80000000u) ? 0xc0000401u : 0);
  }

  for(int i = 0; i < 4096; i++)
    Ptable[i] = i;

  qsort(Ptable, 4096, sizeof(*Ptable), InitPerlinCompare);

  delete[] Ptemp;
  Ptemp = 0;
}

// Perlin gradient function
static sF32 PGradient2(int hash, sF32 x, sF32 y)
{
  hash &= 7;
  sF32 u = hash < 4 ? x : y;
  sF32 v = hash < 4 ? y : x;

  return ((hash & 1) ? -u : u) + ((hash & 2) ? -2.0f * v : 2.0f * v);
}

// Perlin smoothstep function
static sF32 SmoothStep(sF32 x)
{
  return x * x * x * (10 + x * (6 * x - 15));
}

// 2D non-bandlimited noise function
static sF32 Noise2(int x, int y, int maskx, int masky, int seed)
{
  static const int M = 0x10000;

  int X = x >> 16, Y = y >> 16;
  sF32 fx = (x & (M - 1)) / 65536.0f;
  sF32 fy = (y & (M - 1)) / 65536.0f;
  sF32 u = SmoothStep(fx);
  sF32 v = SmoothStep(fy);
  maskx &= 4095;
  masky &= 4095;

  return LerpF(v,
               LerpF(u,
                     (P(((X + 0) & maskx) + P(((Y + 0) & masky)) + seed)) / 2047.5f - 1.0f,
                     (P(((X + 1) & maskx) + P(((Y + 0) & masky)) + seed)) / 2047.5f - 1.0f),
               LerpF(u,
                     (P(((X + 0) & maskx) + P(((Y + 1) & masky)) + seed)) / 2047.5f - 1.0f,
                     (P(((X + 1) & maskx) + P(((Y + 1) & masky)) + seed)) / 2047.5f - 1.0f));
}

// 2D Perlin noise function
static sF32 PNoise2(int x, int y, int maskx, int masky, int seed)
{
  static const int M = 0x10000;
  static const sF32 S = sFInvSqrt(5.0f);

  int X = x >> 16, Y = y >> 16;
  sF32 fx = (x & (M - 1)) / 65536.0f;
  sF32 fy = (y & (M - 1)) / 65536.0f;
  sF32 u = SmoothStep(fx);
  sF32 v = SmoothStep(fy);
  maskx &= 4095;
  masky &= 4095;

  return S *
         LerpF(v,
               LerpF(u,
                     PGradient2((P(((X + 0) & maskx) + P(((Y + 0) & masky)) + seed)), fx, fy),
                     PGradient2((P(((X + 1) & maskx) + P(((Y + 0) & masky)) + seed)), fx - 1.0f, fy)),
               LerpF(u,
                     PGradient2((P(((X + 0) & maskx) + P(((Y + 1) & masky)) + seed)), fx, fy - 1.0f),
                     PGradient2((P(((X + 1) & maskx) + P(((Y + 1) & masky)) + seed)), fx - 1.0f, fy - 1.0f)));
}

static int GShuffle(int x, int y, int z)
{
  /*uint32_t seed = ((x & 0x3ff) << 20) | ((y & 0x3ff) << 10) | (z & 0x3ff);

     seed ^= seed << 3;
     seed += seed >> 5;
     seed ^= seed << 4;
     seed += seed >> 17;
     seed ^= seed << 25;
     seed += seed >> 6;

     return seed;*/

  return P(P(P(x) + y) + z);
}

// 2D grid noise function (tiling)
static sF32 GNoise2(int x, int y, int maskx, int masky, int seed)
{
  // input coordinates
  int i = x >> 16;
  int j = y >> 16;
  sF32 xp = (x & 0xffff) / 65536.0f;
  sF32 yp = (y & 0xffff) / 65536.0f;
  sF32 sum = 0.0f;

  // sum over grid vertices
  for(int oy = 0; oy <= 1; oy++)
  {
    for(int ox = 0; ox <= 1; ox++)
    {
      sF32 xr = xp - ox;
      sF32 yr = yp - oy;

      sF32 t = xr * xr + yr * yr;

      if(t < 1.0f)
      {
        t = 1.0f - t;
        t *= t;
        t *= t;
        sum += t * PGradient2(GShuffle((i + ox) & maskx, (j + oy) & masky, seed), xr, yr);
      }
    }
  }

  return sum;
}

void Noise(GenTexture* dest, const GenTexture& grad, int freqX, int freqY, int oct, sF32 fadeoff, int seed, NoiseMode mode)
{
  assert(oct > 0);

  seed = P(seed);

  int offset;
  sF32 scaling;

  if(mode & NoiseNormalize)
    scaling = (fadeoff - 1.0f) / (sFPow(fadeoff, oct) - 1.0f);
  else
    scaling = min(1.0f, 1.0f / fadeoff);

  if(mode & NoiseAbs) // absolute mode
  {
    offset = 0;
    scaling *= (1 << 24);
  }
  else
  {
    offset = 1 << 23;
    scaling *= (1 << 23);
  }

  int offsX = (1 << (16 - dest->ShiftX + freqX)) >> 1;
  int offsY = (1 << (16 - dest->ShiftY + freqY)) >> 1;

  Pixel* out = dest->Data;

  for(int y = 0; y < dest->YRes; y++)
  {
    for(int x = 0; x < dest->XRes; x++)
    {
      int n = offset;
      sF32 s = scaling;

      int px = (x << (16 - dest->ShiftX + freqX)) + offsX;
      int py = (y << (16 - dest->ShiftY + freqY)) + offsY;
      int mx = (1 << freqX) - 1;
      int my = (1 << freqY) - 1;

      for(int i = 0; i < oct; i++)
      {
        sF32 nv = (mode & NoiseBandlimit) ? Noise2(px, py, mx, my, seed) : GNoise2(px, py, mx, my, seed);

        if(mode & NoiseAbs)
          nv = abs(nv);

        n += nv * s;
        s *= fadeoff;

        px += px;
        py += py;
        mx += mx + 1;
        my += my + 1;
      }

      grad.SampleGradient(*out, n);
      out++;
    }
  }
}

void GlowRect(GenTexture* dest, const GenTexture& bgTex, const GenTexture& grad, sF32 orgx, sF32 orgy, sF32 ux, sF32 uy, sF32 vx, sF32 vy, sF32 rectu, sF32 rectv)
{
  assert(dest->SameSize(bgTex));

  // copy background over (if we're not the background texture already)
  if(dest != &bgTex)
    *dest = bgTex;

  auto const XRes = dest->XRes;
  auto const YRes = dest->YRes;

  // calculate bounding rect
  int minX = max(0, int(floor((orgx - abs(ux) - abs(vx)) * XRes)));
  int minY = max(0, int(floor((orgy - abs(uy) - abs(vy)) * YRes)));
  int maxX = min(XRes - 1, int(ceil((orgx + abs(ux) + abs(vx)) * XRes)));
  int maxY = min(YRes - 1, int(ceil((orgy + abs(uy) + abs(vy)) * YRes)));

  // solve for u0,v0 and deltas (cramer's rule)
  sF32 detM = ux * vy - uy * vx;

  if(fabs(detM) * XRes * YRes < 0.25f) // smaller than a pixel? skip it.
    return;

  sF32 invM = (1 << 16) / detM;
  sF32 rmx = (minX + 0.5f) / XRes - orgx;
  sF32 rmy = (minY + 0.5f) / YRes - orgy;
  int u0 = (rmx * vy - rmy * vx) * invM;
  int v0 = (ux * rmy - uy * rmx) * invM;
  int dudx = vy * invM / XRes;
  int dvdx = -uy * invM / XRes;
  int dudy = -vx * invM / YRes;
  int dvdy = ux * invM / YRes;
  int ruf = min<int>(rectu * 65536.0f, 65535);
  int rvf = min<int>(rectv * 65536.0f, 65535);
  sF32 gus = 1.0f / (65536.0f - ruf);
  sF32 gvs = 1.0f / (65536.0f - rvf);

  for(int y = minY; y <= maxY; y++)
  {
    Pixel* out = &dest->Data[y * XRes + minX];
    int u = u0;
    int v = v0;

    for(int x = minX; x <= maxX; x++)
    {
      if(u > -65536 && u < 65536 && v > -65536 && v < 65536)
      {
        Pixel col;

        int du = max(abs(u) - ruf, 0);
        int dv = max(abs(v) - rvf, 0);

        if(!du && !dv)
        {
          grad.SampleGradient(col, 0);
          out->CompositeROver(col);
        }
        else
        {
          sF32 dus = du * gus;
          sF32 dvs = dv * gvs;
          sF32 dist = dus * dus + dvs * dvs;

          if(dist < 1.0f)
          {
            grad.SampleGradient(col, (1 << 24) * sqrt(dist));
            out->CompositeROver(col);
          }
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

void Cells(GenTexture* dest, const GenTexture& grad, const CellCenter* centers, int nCenters, sF32 amp, int mode)
{
  assert(((mode & 1) == 0) ? nCenters >= 1 : nCenters >= 2);

  struct CellPoint
  {
    int x, y;
    int distY;
    int node;
  };

  Pixel* out = dest->Data;

  vector<CellPoint> points(nCenters);

  // convert cell center coordinates to fixed point
  static const int scaleF = 14; // should be <=14 for 32-bit ints.
  static const int scale = 1 << scaleF;

  for(int i = 0; i < nCenters; i++)
  {
    points[i].x = int(centers[i].x * scale + 0.5f) & (scale - 1);
    points[i].y = int(centers[i].y * scale + 0.5f) & (scale - 1);
    points[i].distY = -1;
    points[i].node = i;
  }

  int stepX = 1 << (scaleF - dest->ShiftX);
  int stepY = 1 << (scaleF - dest->ShiftY);
  int yc = stepY >> 1;

  amp = amp * (1 << 24);

  for(int y = 0; y < dest->YRes; y++)
  {
    int xc = stepX >> 1;

    // calculate new y distances
    for(int i = 0; i < nCenters; i++)
    {
      int dy = (yc - points[i].y) & (scale - 1);
      points[i].distY = sSquare(min(dy, scale - dy));
    }

    // (insertion) sort by y-distance
    for(int i = 1; i < nCenters; i++)
    {
      CellPoint v = points[i];
      int j = i;

      while(j && points[j - 1].distY > v.distY)
      {
        points[j] = points[j - 1];
        j--;
      }

      points[j] = v;
    }

    int best, best2;
    int besti, best2i;

    best = best2 = sSquare(scale);
    besti = best2i = -1;

    for(int x = 0; x < dest->XRes; x++)
    {
      int t, dx;

      // update "best point" stats
      if(besti != -1 && best2i != -1)
      {
        dx = (xc - points[besti].x) & (scale - 1);
        best = sSquare(min(dx, scale - dx)) + points[besti].distY;

        dx = (xc - points[best2i].x) & (scale - 1);
        best2 = sSquare(min(dx, scale - dx)) + points[best2i].distY;

        if(best2 < best)
        {
          swap(best, best2);
          swap(besti, best2i);
        }
      }

      // search for better points
      for(int i = 0; i<nCenters && best2> points[i].distY; i++)
      {
        int dx = (xc - points[i].x) & (scale - 1);
        dx = sSquare(min(dx, scale - dx));

        int dist = dx + points[i].distY;

        if(dist < best)
        {
          best2 = best;
          best2i = besti;
          best = dist;
          besti = i;
        }
        else if(dist > best && dist < best2)
        {
          best2 = dist;
          best2i = i;
        }
      }

      // color the pixel accordingly
      sF32 d0 = sqrt(best) / scale;

      if((mode & 1) == CellInner) // inner
        t = clamp<int>(d0 * amp, 0, 1 << 24);
      else // outer
      {
        sF32 d1 = sqrt(best2) / scale;

        if(d0 + d1 > 0.0f)
          t = clamp<int>(d0 / (d1 + d0) * 2 * amp, 0, 1 << 24);
        else
          t = 0;
      }

      grad.SampleGradient(*out, t);
      out[0].CompositeMulC(centers[points[besti].node].color);

      out++;
      xc += stepX;
    }

    yc += stepY;
  }
}

static int static_this()
{
  InitPerlin();
  return 0;
}

static int const g_Registered = static_this();

