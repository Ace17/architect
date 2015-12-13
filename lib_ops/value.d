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

struct Real
{
  float val;
}

struct Null
{
}

alias Either!(Null, Real, Vec2) Value;

auto mkReal(float val)
{
  return Value(Real(val));
}

auto mkVec2(float x, float y)
{
  return Value(Vec2(x, y));
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

  return val.visit!(fail!Null, onReal, fail!Vec2)();
}

Vec2 asVec2(in Value val)
{
  static Vec2 fail(T)(in T)
  {
    throw new Exception("Expected a real number");
  }

  static Vec2 onVec2(in Vec2 r)
  {
    return r;
  }

  return val.visit!(fail!Null, fail!Real, onVec2)();
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

  return a.visitDg!Value(&fail!Null, &onReal, &onVec2);
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

  return a.visitDg!Value(&fail!Null, &onReal, &onVec2);
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

  return a.visitDg(&defaultString, &onReal, &onVec2);
}

