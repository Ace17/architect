#pragma once

#include <cstdint>

// Pixel. Uses whole 16bit value range (0-65535).
// 0=>0.0, 65535=>1.0.
struct Pixel
{
  uint16_t r, g, b, a;

  void Init(uint8_t r, uint8_t g, uint8_t b, uint8_t a);
  void Init(uint32_t rgba); // 0xaarrggbb (D3D style)

  void Lerp(int t, Pixel x, Pixel y); // t=0..65536

  void CompositeAdd(Pixel b);
  void CompositeMulC(Pixel b);
  void CompositeROver(Pixel b);
  void CompositeScreen(Pixel b);
};

// CellCenter. 2D pair of coordinates plus a cell color.
struct CellCenter
{
  float x, y;
  Pixel color;
};

// LinearInput. One input for "linear combine".
struct Texture;

struct LinearInput
{
  const Texture* Tex;    // the input texture
  float Weight;              // its weight
  float UShift, VShift;       // u/v translate parameter
  int FilterMode;          // filtering mode (as in CoordMatrixTransform)
};

// Simple 4x4 matrix type
typedef float Matrix44[4][4];

// X increases from 0 (left) to 1 (right)
// Y increases from 0 (bottom) to 1 (top)

// Ternary operations
enum TernaryOp
{
  TernaryLerp = 0,  // (1-c.r) * a + c.r * b
  TernarySelect,
};

// Derive operations
enum DeriveOp
{
  DeriveGradient = 0,
  DeriveNormals,
};

// Combine operations
enum CombineOp
{
  // simple arithmetic
  CombineAdd = 0,   // x=saturate(a+b)
  CombineSub,       // x=saturate(a-b)
  CombineMulC,      // x=a*b
  CombineMin,       // x=min(a,b)
  CombineMax,       // x=max(a,b)
  CombineSetAlpha,  // x.rgb=a.rgb, x.a=b.r
  CombinePreAlpha,  // x.rgb=a.rgb*b.r, x.a=b.r

  CombineOver,      // x=b over a
  CombineMultiply,
  CombineScreen,
  CombineDarken,
  CombineLighten,
};

// Noise mode
enum NoiseMode
{
  NoiseDirect = 0,      // use noise(x,y) directly
  NoiseAbs = 1,         // use abs(noise(x,y))

  NoiseUnnorm = 0,      // unnormalized (no further scaling)
  NoiseNormalize = 2,   // normalized (scale so values always fall into [0,1] with no clamping)

  NoiseWhite = 0,       // white noise function
  NoiseBandlimit = 4,   // bandlimited (perlin-like) noise function
};

// Cell mode
enum CellMode
{
  CellInner = 0,        // inner (distance to cell center)
  CellOuter = 1,        // outer (distance to edge)
};

// Filter mode
enum FilterMode
{
  WrapU = 0,            // wrap in u direction
  ClampU = 1,           // clamp (to edge) in u direction

  WrapV = 0,            // wrap in v direction
  ClampV = 2,           // clamp (to edge) in v direction

  FilterNearest = 0,    // nearest neighbor (point sampling)
  FilterBilinear = 4,   // bilinear filtering.
};

struct Texture
{
  Pixel* Data;    // pointer to pixel data.
  int XRes;      // width of texture (must be a power of 2)
  int YRes;      // height of texture (must be a power of 2)
  int NPixels;   // width*height (number of pixels)

  int ShiftX;    // log2(XRes)
  int ShiftY;    // log2(YRes)
  int MinX;      // (1 << 24) / (2 * XRes) = Min X for clamp to edge
  int MinY;      // (1 << 24) / (2 * YRes) = Min Y for clamp to edge

  Texture();
  Texture(int xres, int yres);
  Texture(const Texture& x);
  ~Texture();
  void __ctor(int, int);
  void Free();

  void Init(int xres, int yres);
  void UpdateSize();
  void Swap(Texture& x);

  Texture & operator = (const Texture& x);

  bool SameSize(const Texture& x) const;

  // Sampling helpers with filtering (coords are 1.7.24 fixed point)
  void SampleNearest(Pixel& result, int x, int y, int wrapMode) const;
  void SampleBilinear(Pixel& result, int x, int y, int wrapMode) const;
  void SampleFiltered(Pixel& result, int x, int y, int filterMode) const;
  void SampleGradient(Pixel& result, int x) const;
};

