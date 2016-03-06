#include "gentexture.h"
#include <algorithm>
#include <cmath>
#include <vector>
#include <cassert>
#include <cstring>

using namespace std;

typedef float sF32;  // basic floatingpoint

/****************************************************************************/
/***                                                                      ***/
/***   Helpers                                                            ***/
/***                                                                      ***/
/****************************************************************************/

template<class T>
inline T sSquare(T a)
{
  return a * a;
}

inline double sFInvSqrt(double f)
{
  return 1.0 / sqrt(f);
}

inline double sFPow(double a, double b)
{
  return pow(a, b);
}

// Return true if x is a power of 2, false otherwise
static bool IsPowerOf2(int x)
{
  return (x & (x - 1)) == 0;
}

template<class T>
inline T clamp(T val, T min, T max)
{
  return (val >= max) ? max : (val <= min) ? min : val;
}

// Returns floor(log2(x))
static int FloorLog2(int x)
{
  int res = 0;

  if(x & 0xffff0000)
    x >>= 16, res += 16;

  if(x & 0x0000ff00)
    x >>= 8, res += 8;

  if(x & 0x000000f0)
    x >>= 4, res += 4;

  if(x & 0x0000000c)
    x >>= 2, res += 2;

  if(x & 0x00000002)
    res++;

  return res;
}

// Multiply intensities.
// Returns the result of round(a*b/65535.0)
static uint32_t MulIntens(uint32_t a, uint32_t b)
{
  uint32_t x = a * b + 0x8000;
  return (x + (x >> 16)) >> 16;
}

// Returns the result of round(a*b/65536)
static int MulShift16(int a, int b)
{
  return (int64_t(a) * int64_t(b) + 0x8000) >> 16;
}

// Returns the result of round(a*b/256)
static uint32_t UMulShift8(uint32_t a, uint32_t b)
{
  return (uint64_t(a) * uint64_t(b) + 0x80) >> 8;
}

// Linearly interpolate between a and b with t=0..65536 [0,1]
// 0<=a,b<65536.
static int Lerp(int t, int a, int b)
{
  return a + ((t * (b - a)) >> 16);
}

static sF32 LerpF(sF32 t, sF32 a, sF32 b)
{
  return a + t * (b - a);
}

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
/***   GenTexture                                                         ***/
/***                                                                      ***/
/****************************************************************************/

void GenTexture::__ctor(int xres, int yres)
{
  Data = 0;
  XRes = 0;
  YRes = 0;

  Init(xres, yres);
}

GenTexture::GenTexture()
{
  Data = 0;
  XRes = 0;
  YRes = 0;

  UpdateSize();
}

GenTexture::GenTexture(int xres, int yres)
{
  Data = 0;
  XRes = 0;
  YRes = 0;

  Init(xres, yres);
}

GenTexture::GenTexture(const GenTexture& x)
{
  XRes = x.XRes;
  YRes = x.YRes;
  UpdateSize();

  Data = new Pixel[NPixels];
  memcpy(Data, x.Data, NPixels * sizeof(Pixel));
}

GenTexture::~GenTexture()
{
  Free();
}

void GenTexture::Free()
{
  delete[] Data;
}

void GenTexture::Init(int xres, int yres)
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

void GenTexture::UpdateSize()
{
  NPixels = XRes * YRes;
  ShiftX = FloorLog2(XRes);
  ShiftY = FloorLog2(YRes);

  MinX = 1 << (24 - 1 - ShiftX);
  MinY = 1 << (24 - 1 - ShiftY);
}

void GenTexture::Swap(GenTexture& x)
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

GenTexture & GenTexture::operator = (const GenTexture& x)
{
  GenTexture t = x;

  Swap(t);
  return *this;
}

bool GenTexture::SameSize(const GenTexture& x) const
{
  return XRes == x.XRes && YRes == x.YRes;
}

// ---- Sampling helpers
void GenTexture::SampleNearest(Pixel& result, int x, int y, int wrapMode) const
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

void GenTexture::SampleBilinear(Pixel& result, int x, int y, int wrapMode) const
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

void GenTexture::SampleFiltered(Pixel& result, int x, int y, int filterMode) const
{
  if(filterMode & FilterBilinear)
    SampleBilinear(result, x, y, filterMode);
  else
    SampleNearest(result, x, y, filterMode);
}

void GenTexture::SampleGradient(Pixel& result, int x) const
{
  x = clamp(x, 0, 1 << 24);
  x -= x >> ShiftX; // x=(1<<24) -> Take rightmost pixel

  int x0 = x >> (24 - ShiftX);
  int x1 = (x0 + 1) & (XRes - 1);
  int fx = uint32_t(x << (ShiftX + 8)) >> 16;

  result.Lerp(fx, Data[x0], Data[x1]);
}

// ---- The operators themselves

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

void GenTexture::ColorMatrixTransform(const GenTexture& x, Matrix44& matrix, bool clampPremult)
{
  int m[4][4];

  assert(SameSize(x));

  for(int i = 0; i < 4; i++)
  {
    for(int j = 0; j < 4; j++)
    {
      assert(matrix[i][j] >= -127.0f && matrix[i][j] <= 127.0f);
      m[i][j] = matrix[i][j] * 65536.0f;
    }
  }

  for(int i = 0; i < NPixels; i++)
  {
    auto& out = Data[i];
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

void GenTexture::CoordMatrixTransform(const GenTexture& in, Matrix44& matrix, int mode)
{
  int scaleX = 1 << (24 - ShiftX);
  int scaleY = 1 << (24 - ShiftY);

  int dudx = matrix[0][0] * scaleX;
  int dudy = matrix[0][1] * scaleY;
  int dvdx = matrix[1][0] * scaleX;
  int dvdy = matrix[1][1] * scaleY;

  int u0 = matrix[0][3] * (1 << 24) + ((dudx + dudy) >> 1);
  int v0 = matrix[1][3] * (1 << 24) + ((dvdx + dvdy) >> 1);
  Pixel* out = Data;

  for(int y = 0; y < YRes; y++)
  {
    int u = u0;
    int v = v0;

    for(int x = 0; x < XRes; x++)
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

void GenTexture::ColorRemap(const GenTexture& inTex, const GenTexture& mapR, const GenTexture& mapG, const GenTexture& mapB)
{
  assert(SameSize(inTex));

  for(int i = 0; i < NPixels; i++)
  {
    const Pixel& in = inTex.Data[i];
    Pixel& out = Data[i];

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

void GenTexture::CoordRemap(const GenTexture& in, const GenTexture& remapTex, sF32 strengthU, sF32 strengthV, int mode)
{
  assert(SameSize(remapTex));

  const Pixel* remap = remapTex.Data;
  Pixel* out = Data;

  int u0 = MinX;
  int v0 = MinY;
  int scaleU = (1 << 24) * strengthU;
  int scaleV = (1 << 24) * strengthV;
  int stepU = 1 << (24 - ShiftX);
  int stepV = 1 << (24 - ShiftY);

  for(int y = 0; y < YRes; y++)
  {
    int u = u0;
    int v = v0;

    for(int x = 0; x < XRes; x++)
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

void GenTexture::Derive(const GenTexture& in, DeriveOp op, sF32 strength)
{
  assert(SameSize(in));

  Pixel* out = Data;

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

void GenTexture::Blur(const GenTexture& inImg, sF32 sizex, sF32 sizey, int order, int wrapMode)
{
  assert(SameSize(inImg));

  int sizePixX = clamp(sizex, 0.0f, 1.0f) * 64 * inImg.XRes / 2;
  int sizePixY = clamp(sizey, 0.0f, 1.0f) * 64 * inImg.YRes / 2;

  // no blur at all? just copy!
  if(order < 1 || (sizePixX <= 32 && sizePixY <= 32))
  {
    *this = inImg;
    return;
  }

  // allocate pixel buffers
  int bufSize = max(XRes, YRes);

  vector<Pixel> buf1_mem(bufSize);
  vector<Pixel> buf2_mem(bufSize);

  Pixel* buf1 = buf1_mem.data();
  Pixel* buf2 = buf2_mem.data();
  const GenTexture* input = &inImg;

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
      memcpy(&Data[y * XRes], buf1, XRes * sizeof(Pixel));
    }

    input = this;
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
      dst = &Data[x];

      for(int y = 0; y < YRes; y++)
      {
        *dst = *src++;
        dst += XRes;
      }
    }
  }
}

void GenTexture::Ternary(const GenTexture& in1Tex, const GenTexture& in2Tex, const GenTexture& in3Tex, TernaryOp op)
{
  assert(SameSize(in1Tex) && SameSize(in2Tex) && SameSize(in3Tex));

  for(int i = 0; i < NPixels; i++)
  {
    Pixel& out = Data[i];
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

void GenTexture::Paste(const GenTexture& bgTex, const GenTexture& inTex, sF32 orgx, sF32 orgy, sF32 ux, sF32 uy, sF32 vx, sF32 vy, CombineOp op, int mode)
{
  assert(SameSize(bgTex));

  // copy background over (if this image is not the background already)
  if(this != &bgTex)
    *this = bgTex;

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
    Pixel* out = &Data[y * XRes + minX];
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

void GenTexture::Bump(const GenTexture& surface, const GenTexture& normals, const GenTexture* specular, const GenTexture* falloffMap, sF32 px, sF32 py, sF32 pz, sF32 dx, sF32 dy, sF32 dz, Pixel ambient, Pixel diffuse, bool directional)
{
  assert(SameSize(surface) && SameSize(normals));

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

  auto invX = 1.0f / XRes;
  auto invY = 1.0f / YRes;
  Pixel* out = Data;
  const Pixel* surf = surface.Data;
  const Pixel* normal = normals.Data;

  for(int y = 0; y < YRes; y++)
  {
    for(int x = 0; x < XRes; x++)
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

void GenTexture::LinearCombine(Pixel color, sF32 constWeight, const LinearInput* inputs, int nInputs)
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
  int u0 = MinX;
  int v0 = MinY;
  int stepU = 1 << (24 - ShiftX);
  int stepV = 1 << (24 - ShiftY);
  Pixel* out = Data;

  for(int y = 0; y < YRes; y++)
  {
    int u = u0;
    int v = v0;

    for(int x = 0; x < XRes; x++)
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

static int static_this()
{
  InitPerlin();
  return 0;
}

int const g_Registered = static_this();

