/**
 * @file helpers.h
 * @brief Helper functions for filters.
 * @author Sebastien Alaiwan
 * @date 2016-03-06
 */

/*
 * Copyright (C) 2015 - Sebastien Alaiwan
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 */

#pragma once
#include <math.h>
#include <algorithm>
#include <cassert>

using namespace std; // okay for 'std', otherwise code gets too verbose

typedef float sF32;

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

