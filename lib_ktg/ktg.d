extern(C++) :

// Pixel. Uses whole 16bit value range (0-65535).
// 0=>0.0, 65535=>1.0.
struct Pixel
{
  ushort r, g, b, a; // OpenGL byte order

  void Init(ubyte r, ubyte g, ubyte b, ubyte a);
}

Pixel Color(int r, int g, int b, int a = 255)
{
  Pixel result;
  result.r = cast(ushort)((r << 8) | r);
  result.g = cast(ushort)((g << 8) | g);
  result.b = cast(ushort)((b << 8) | b);
  result.a = cast(ushort)((a << 8) | a);
  return result;
}

// Simple 4x4 matrix type
alias Matrix44 = float[4][4];

// X increases from 0 (left) to 1 (right)
// Y increases from 0 (bottom) to 1 (top)

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

  this(int xres, int yres);

  // At this time of writing, D can't call C++ destructors
  ~this()
  {
    Free();
  }

  void Free();
};

///////////////////////////////////////////////////////////////////////////////
// Generators
///////////////////////////////////////////////////////////////////////////////
void Noise(Texture* dest, ref const(Texture)grad, int freqX, int freqY, int oct, float fadeoff, int seed,
           NoiseMode mode);
void GlowRect(Texture* dest, ref const(Texture)background, ref const(Texture)grad, float orgx, float orgy, float ux,
              float uy, float vx, float vy, float rectu, float rectv);
void Cells(Texture* dest, ref const(Texture)grad, const CellCenter* centers, int nCenters, float amp, CellMode mode);
void Voronoi(Texture* dest, float intensity, int maxCount, float minDist);

enum NoiseMode
{
  Direct = 0,      // use noise(x,y) directly
  Abs = 1,         // use abs(noise(x,y))

  Unnorm = 0,      // unnormalized (no further scaling)
  Normalize = 2,   // normalized (scale so values always fall into [0,1] with no clamping)

  White = 0,       // white noise function
  Bandlimit = 4,   // bandlimited (perlin-like) noise function
}

struct CellCenter
{
  float x, y;
  Pixel color;
}

enum CellMode
{
  Inner, // inner (distance to cell center)
  Outer, // outer (distance to edge)
}

///////////////////////////////////////////////////////////////////////////////
// Combiners
///////////////////////////////////////////////////////////////////////////////
void Ternary(Texture* dest, ref const(Texture)in1, ref const(Texture)in2, ref const(Texture)in3, TernaryOp op);
void Paste(Texture* dest, ref const(Texture)background, ref const(Texture)snippet, float orgx, float orgy, float ux,
           float uy, float vx, float vy, CombineOp op, int mode);
void Bump(Texture* dest, ref const(Texture)surface, ref const(Texture)normals, const Texture* specular,
          const Texture* falloff, float px, float py, float pz, float dx, float dy, float dz, Pixel ambient,
          Pixel diffuse, bool directional);
void LinearCombine(Texture* dest, Pixel color, float constWeight, const LinearInput* inputs, int nInputs);

struct LinearInput // one input for "linear combine".
{
  const(Texture)*Tex;    // the input texture
  float Weight;              // its weight
  float UShift, VShift;       // u/v translate parameter
  int FilterMode;          // filtering mode (as in CoordMatrixTransform)
}

enum CombineOp
{
  // simple arithmetic
  Add,       // x=saturate(a+b)
  Sub,       // x=saturate(a-b)
  MulC,      // x=a*b
  Min,       // x=min(a,b)
  Max,       // x=max(a,b)
  SetAlpha,  // x.rgb=a.rgb, x.a=b.r
  PreAlpha,  // x.rgb=a.rgb*b.r, x.a=b.r

  Over,      // x=b over a
  Multiply,
  Screen,
  Darken,
  Lighten,
}

enum TernaryOp
{
  Lerp,  // (1-c.r) * a + c.r * b
  Select,
}

///////////////////////////////////////////////////////////////////////////////
// Filters
///////////////////////////////////////////////////////////////////////////////
void ColorMatrixTransform(Texture* dest, ref const(Texture)in_, ref Matrix44 matrix, bool clampPremult);
void CoordMatrixTransform(Texture* dest, ref const(Texture)in_, ref Matrix44 matrix, int filterMode);
void ColorRemap(Texture* dest, ref const(Texture)in_, ref const(Texture)mapR, ref const(Texture)mapG,
                ref const(Texture)mapB);
void CoordRemap(Texture* dest, ref const(Texture)in_, ref const(Texture)remap, float strengthU, float strengthV,
                int filterMode);
void Derive(Texture* dest, ref const(Texture)in_, DeriveOp op, float strength);
void Blur(Texture* dest, ref const(Texture)in_, float sizex, float sizey, int order, int mode);

enum DeriveOp
{
  Gradient,
  Normals,
}

enum FilterMode
{
  WrapU = 0,            // wrap in u direction
  ClampU = 1,           // clamp (to edge) in u direction

  WrapV = 0,            // wrap in v direction
  ClampV = 2,           // clamp (to edge) in v direction

  Nearest = 0,    // nearest neighbor (point sampling)
  Bilinear = 4,   // bilinear filtering.
}

