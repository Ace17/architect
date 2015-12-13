/**
 * @file value.d
 * @brief
 * @author Sebastien Alaiwan
 * @date 2015-12-09
 */

/*
 * Copyright (C) 2015 - Sebastien Alaiwan
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 */

import std.string;
import algebraic: Either;

struct Vec2
{
  float x, y;

  Vec2 opAdd(in Vec2 other) const
  {
    return Vec2(x + other.x, y + other.y);
  }

  Vec2 opSub(in Vec2 other) const
  {
    return Vec2(x - other.x, y - other.y);
  }
}

struct Vec3
{
  float x, y, z;

  Vec3 opAdd(in Vec3 other) const
  {
    return Vec3(x + other.x, y + other.y, z + other.z);
  }

  Vec3 opSub(in Vec3 other) const
  {
    return Vec3(x - other.x, y - other.y, z + other.z);
  }
}

struct Real
{
  float val;
}

struct Null
{
}

alias Either!(Null, Real, Vec2, Vec3) Value;

auto mkReal(float val)
{
  return Value(Real(val));
}

auto mkVec2(float x, float y)
{
  return Value(Vec2(x, y));
}

auto mkVec3(float x, float y, float z)
{
  return Value(Vec3(x, y, z));
}

float asReal(in Value val)
{
  static float fail(T)(in T)
  {
    throw new Exception("Expected a real number");
  }

  static float onReal(in Real r)
  {
    return r.val;
  }

  return val.visit!(fail!Null, onReal, fail!Vec2, fail!Vec3)();
}

Vec2 asVec2(in Value val)
{
  static Vec2 fail(T)(in T)
  {
    throw new Exception("Expected a Vec2");
  }

  static Vec2 onVec2(in Vec2 r)
  {
    return r;
  }

  return val.visit!(fail!Null, fail!Real, onVec2, fail!Vec3)();
}

Vec3 asVec3(in Value val)
{
  static Vec3 fail(T)(in T)
  {
    throw new Exception("Expected a Vec3");
  }

  static Vec3 onVec3(in Vec3 r)
  {
    return r;
  }

  return val.visit!(fail!Null, fail!Real, fail!Vec2, onVec3)();
}

Value add(Value a, Value b)
{
  Value fail(T)(T)
  {
    throw new Exception(format("Can't add to this type: %s", T.stringof));
  }

  Value onReal(Real r)
  {
    return mkReal(r.val + asReal(b));
  }

  Value onVec2(Vec2 r)
  {
    return Value(r + asVec2(b));
  }

  Value onVec3(Vec3 r)
  {
    return Value(r + asVec3(b));
  }

  return a.visitDg!Value(&fail!Null, &onReal, &onVec2, &onVec3);
}

Value sub(Value a, Value b)
{
  Value fail(T)(T)
  {
    throw new Exception(format("Can't add to this type: %s", T.stringof));
  }

  Value onReal(Real r)
  {
    return mkReal(r.val - asReal(b));
  }

  Value onVec2(Vec2 r)
  {
    return Value(r - asVec2(b));
  }

  Value onVec3(Vec3 r)
  {
    return Value(r - asVec3(b));
  }

  return a.visitDg!Value(&fail!Null, &onReal, &onVec2, &onVec3);
}

string toString(Value a)
{
  string defaultString(Null)
  {
    return "<null>";
  }

  string onReal(Real r)
  {
    return format("%.2s", r.val);
  }

  string onVec2(Vec2 r)
  {
    return format("Vec2(%.2s, %.2s)", r.x, r.y);
  }

  string onVec3(Vec3 r)
  {
    return format("Vec3(%.2s, %.2s, %.2s)", r.x, r.y, r.z);
  }

  return a.visitDg(&defaultString, &onReal, &onVec2, &onVec3);
}

