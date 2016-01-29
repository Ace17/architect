#pragma once

#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <math.h>
#include <stdint.h>

/****************************************************************************/
/***                                                                      ***/
/***   Basic Types and Functions                                          ***/
/***                                                                      ***/
/****************************************************************************/
typedef uint8_t sU8;   // for packed arrays
typedef uint16_t sU16;  // for packed arrays
typedef uint32_t sU32;  // for packed arrays and bitfields
typedef uint64_t sU64;  // use as needed
typedef int8_t sS8;   // for packed arrays
typedef int16_t sS16;  // for packed arrays
typedef int32_t sS32;  // for packed arrays
typedef int64_t sS64;  // use as needed
typedef int sInt;  // use this most
typedef intptr_t sDInt; // type for pointer diff

typedef float sF32;  // basic floatingpoint
typedef double sF64;  // use as needed

/****************************************************************************/

template<class Type>
inline Type sMin(Type a, Type b)
{
  return (a < b) ? a : b;
}

template<class Type>
inline Type sMax(Type a, Type b)
{
  return (a > b) ? a : b;
}

template<class Type>
inline Type sSign(Type a)
{
  return (a == 0) ? Type(0) : (a > 0) ? Type(1) : Type(-1);
}

template<class Type>
inline Type sClamp(Type a, Type min, Type max)
{
  return (a >= max) ? max : (a <= min) ? min : a;
}

template<class Type>
inline void sSwap(Type& a, Type& b)
{
  Type s;
  s = a;
  a = b;
  b = s;
}

template<class Type>
inline Type sAlign(Type a, sInt b)
{
  return (Type)((((sDInt)a) + b - 1) & (~(b - 1)));
}

template<class Type>
inline Type sSquare(Type a)
{
  return a * a;
}

/****************************************************************************/

#define sPI 3.1415926535897932384626433832795
#define sPI2 6.28318530717958647692528676655901
#define sPIF 3.1415926535897932384626433832795f
#define sPI2F 6.28318530717958647692528676655901f
#define sSQRT2 1.4142135623730950488016887242097
#define sSQRT2F 1.4142135623730950488016887242097f

inline sInt sAbs(sInt i)
{
  return abs(i);
}

inline sInt sCmpMem(const void* dd, const void* ss, sInt c)
{
  return (sInt)memcmp(dd, ss, c);
}

inline sF64 sFATan(sF64 f)
{
  return atan(f);
}

inline sF64 sFATan2(sF64 a, sF64 b)
{
  return atan2(a, b);
}

inline sF64 sFCos(sF64 f)
{
  return cos(f);
}

inline sF64 sFAbs(sF64 f)
{
  return fabs(f);
}

inline sF64 sFLog(sF64 f)
{
  return log(f);
}

inline sF64 sFLog10(sF64 f)
{
  return log10(f);
}

inline sF64 sFSin(sF64 f)
{
  return sin(f);
}

inline sF64 sFSqrt(sF64 f)
{
  return sqrt(f);
}

inline sF64 sFTan(sF64 f)
{
  return tan(f);
}

inline sF64 sFACos(sF64 f)
{
  return acos(f);
}

inline sF64 sFASin(sF64 f)
{
  return asin(f);
}

inline sF64 sFCosH(sF64 f)
{
  return cosh(f);
}

inline sF64 sFSinH(sF64 f)
{
  return sinh(f);
}

inline sF64 sFTanH(sF64 f)
{
  return tanh(f);
}

inline sF64 sFInvSqrt(sF64 f)
{
  return 1.0 / sqrt(f);
}

inline sF64 sFFloor(sF64 f)
{
  return floor(f);
}

inline sF64 sFPow(sF64 a, sF64 b)
{
  return pow(a, b);
}

inline sF64 sFMod(sF64 a, sF64 b)
{
  return fmod(a, b);
}

inline sF64 sFExp(sF64 f)
{
  return exp(f);
}

/****************************************************************************/

