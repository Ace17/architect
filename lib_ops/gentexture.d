extern(C++) :

alias sF32 = float;
alias sU8 = ubyte;
alias sU16 = ushort;
alias sU32 = uint;
alias sInt = int;
alias sU64 = ulong;

// Pixel. Uses whole 16bit value range (0-65535).
// 0=>0.0, 65535=>1.0.
struct Pixel
{
  sU16 r, g, b, a; // OpenGL byte order

  void Init(sU8 r, sU8 g, sU8 b, sU8 a);
  void Init(sU32 rgba); // 0xaarrggbb (D3D style)

  void Lerp(sInt t, Pixel x, Pixel y); // t=0..65536

  void CompositeAdd(Pixel b);
  void CompositeMulC(Pixel b);
  void CompositeROver(Pixel b);
  void CompositeScreen(Pixel b);
}

Pixel Color(int r, int g, int b, int a = 255)
{
  Pixel result;
  result.Init(cast(sU8)r, cast(sU8)g, cast(sU8)b, cast(sU8)a);
  return result;
}

// CellCenter. 2D pair of coordinates plus a cell color.
struct CellCenter
{
  sF32 x, y;
  Pixel color;
}

// LinearInput. One input for "linear combine".

struct LinearInput
{
  const(GenTexture)*Tex;    // the input texture
  sF32 Weight;              // its weight
  sF32 UShift, VShift;       // u/v translate parameter
  sInt FilterMode;          // filtering mode (as in CoordMatrixTransform)
}

// Simple 4x4 matrix type
alias Matrix44 = sF32[4][4];

// X increases from 0 (left) to 1 (right)
// Y increases from 0 (bottom) to 1 (top)

struct GenTexture
{
  Pixel* Data;    // pointer to pixel data.
  sInt XRes;      // width of texture (must be a power of 2)
  sInt YRes;      // height of texture (must be a power of 2)
  sInt NPixels;   // width*height (number of pixels)

  sInt ShiftX;    // log2(XRes)
  sInt ShiftY;    // log2(YRes)
  sInt MinX;      // (1 << 24) / (2 * XRes) = Min X for clamp to edge
  sInt MinY;      // (1 << 24) / (2 * YRes) = Min Y for clamp to edge

  this(sInt xres, sInt yres);

  // At this time of writing, D can't call C++ destructors
  ~this()
  {
    Free();
  }

  void Free();

  // Actual generator functions
  void Noise(ref const(GenTexture)grad, sInt freqX, sInt freqY, sInt oct, sF32 fadeoff, sInt seed, NoiseMode mode);
  void GlowRect(ref const(GenTexture)background, ref const(GenTexture)grad, sF32 orgx, sF32 orgy, sF32 ux, sF32 uy, sF32 vx, sF32 vy, sF32 rectu, sF32 rectv);
  void Cells(ref const(GenTexture)grad, const CellCenter* centers, sInt nCenters, sF32 amp, sInt mode);

  // Filters
  void ColorMatrixTransform(ref const(GenTexture)in_, ref Matrix44 matrix, bool clampPremult);
  void CoordMatrixTransform(ref const(GenTexture)in_, ref Matrix44 matrix, sInt filterMode);
  void ColorRemap(ref const(GenTexture)in_, ref const(GenTexture)mapR, ref const(GenTexture)mapG, ref const(GenTexture)mapB);
  void CoordRemap(ref const(GenTexture)in_, ref const(GenTexture)remap, sF32 strengthU, sF32 strengthV, sInt filterMode);
  void Derive(ref const(GenTexture)in_, DeriveOp op, sF32 strength);
  void Blur(ref const(GenTexture)in_, sF32 sizex, sF32 sizey, sInt order, sInt mode);

  // Combiners
  void Ternary(ref const(GenTexture)in1, ref const(GenTexture)in2, ref const(GenTexture)in3, TernaryOp op);
  void Paste(ref const(GenTexture)background, ref const(GenTexture)snippet, sF32 orgx, sF32 orgy, sF32 ux, sF32 uy, sF32 vx, sF32 vy, CombineOp op, sInt mode);
  void Bump(ref const(GenTexture)surface, ref const(GenTexture)normals, const GenTexture* specular, const GenTexture* falloff, sF32 px, sF32 py, sF32 pz, sF32 dx, sF32 dy, sF32 dz, Pixel ambient, Pixel diffuse, bool directional);
  void LinearCombine(Pixel color, sF32 constWeight, const LinearInput* inputs, sInt nInputs);
};

enum TernaryOp
{
  TernaryLerp = 0,  // (1-c.r) * a + c.r * b
  TernarySelect,
}

enum DeriveOp
{
  DeriveGradient = 0,
  DeriveNormals,
}

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
}

enum NoiseMode
{
  NoiseDirect = 0,      // use noise(x,y) directly
  NoiseAbs = 1,         // use abs(noise(x,y))

  NoiseUnnorm = 0,      // unnormalized (no further scaling)
  NoiseNormalize = 2,   // normalized (scale so values always fall into [0,1] with no clamping)

  NoiseWhite = 0,       // white noise function
  NoiseBandlimit = 4,   // bandlimited (perlin-like) noise function
}

// Cell mode
enum CellMode
{
  CellInner = 0,        // inner (distance to cell center)
  CellOuter = 1,        // outer (distance to edge)
}

// Filter mode
enum FilterMode
{
  WrapU = 0,            // wrap in u direction
  ClampU = 1,           // clamp (to edge) in u direction

  WrapV = 0,            // wrap in v direction
  ClampV = 2,           // clamp (to edge) in v direction

  FilterNearest = 0,    // nearest neighbor (point sampling)
  FilterBilinear = 4,   // bilinear filtering.
}

