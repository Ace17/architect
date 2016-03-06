extern(C++) :

// Pixel. Uses whole 16bit value range (0-65535).
// 0=>0.0, 65535=>1.0.
struct Pixel
{
  ushort r, g, b, a; // OpenGL byte order

  void Init(ubyte r, ubyte g, ubyte b, ubyte a);
  void Init(uint rgba); // 0xaarrggbb (D3D style)
}

Pixel Color(int r, int g, int b, int a = 255)
{
  Pixel result;
  result.Init(cast(ubyte)r, cast(ubyte)g, cast(ubyte)b, cast(ubyte)a);
  return result;
}

// CellCenter. 2D pair of coordinates plus a cell color.
struct CellCenter
{
  float x, y;
  Pixel color;
}

// LinearInput. One input for "linear combine".

struct LinearInput
{
  const(GenTexture)*Tex;    // the input texture
  float Weight;              // its weight
  float UShift, VShift;       // u/v translate parameter
  int FilterMode;          // filtering mode (as in CoordMatrixTransform)
}

// Simple 4x4 matrix type
alias Matrix44 = float[4][4];

// X increases from 0 (left) to 1 (right)
// Y increases from 0 (bottom) to 1 (top)

struct GenTexture
{
  Pixel* Data;    // pointer to pixel data.
  int XRes;      // width of texture (must be a power of 2)
  int YRes;      // height of texture (must be a power of 2)
  int NPixels;   // width*height (number of pixels)

  int ShiftX;    // log2(XRes)
  int ShiftY;    // log2(YRes)
  int MinX;      // (1 << 24) / (2 * XRes) = Min X for clamp to edge
  int MinY;      // (1 << 24) / (2 * YRes) = Min Y for clamp to edge

  this(int xres, int yres);

  // At this time of writing, D can't call C++ destructors
  ~this()
  {
    Free();
  }

  void Free();

  // Filters
  void ColorMatrixTransform(ref const(GenTexture)in_, ref Matrix44 matrix, bool clampPremult);
  void CoordMatrixTransform(ref const(GenTexture)in_, ref Matrix44 matrix, int filterMode);
  void ColorRemap(ref const(GenTexture)in_, ref const(GenTexture)mapR, ref const(GenTexture)mapG, ref const(GenTexture)mapB);
  void CoordRemap(ref const(GenTexture)in_, ref const(GenTexture)remap, float strengthU, float strengthV, int filterMode);
  void Derive(ref const(GenTexture)in_, DeriveOp op, float strength);
  void Blur(ref const(GenTexture)in_, float sizex, float sizey, int order, int mode);
};

// Actual generator functions
void Noise(GenTexture* dest, ref const(GenTexture)grad, int freqX, int freqY, int oct, float fadeoff, int seed, NoiseMode mode);
void GlowRect(GenTexture* dest, ref const(GenTexture)background, ref const(GenTexture)grad, float orgx, float orgy, float ux, float uy, float vx, float vy, float rectu, float rectv);
void Cells(GenTexture* dest, ref const(GenTexture)grad, const CellCenter* centers, int nCenters, float amp, int mode);

// Combiners
void Ternary(GenTexture* dest, ref const(GenTexture)in1, ref const(GenTexture)in2, ref const(GenTexture)in3, TernaryOp op);
void Paste(GenTexture* dest, ref const(GenTexture)background, ref const(GenTexture)snippet, float orgx, float orgy, float ux, float uy, float vx, float vy, CombineOp op, int mode);
void Bump(GenTexture* dest, ref const(GenTexture)surface, ref const(GenTexture)normals, const GenTexture* specular, const GenTexture* falloff, float px, float py, float pz, float dx, float dy, float dz, Pixel ambient, Pixel diffuse, bool directional);
void LinearCombine(GenTexture* dest, Pixel color, float constWeight, const LinearInput* inputs, int nInputs);

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

