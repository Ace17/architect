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
import std.math;
import algebraic: Either;
import misc;
public import vect;

struct Real
{
  float val;
}

struct Null
{
}

struct Identifier
{
  string name;
}

alias Either!(Null, Real, Vec2, Vec3, Identifier) Value;

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

T valueAs(T)(in Value val)
{
  static T typeCheck(U)(in U val)
  {
    static if(is (T == U))
      return val;
    else
      throw new Exception("Expected a " ~ T.stringof ~ ", got a " ~ U.stringof);
  }

  static T onNull(Null r)
  {
    return typeCheck(r);
  }

  static T onReal(Real r)
  {
    return typeCheck(r);
  }

  static T onVec2(Vec2 r)
  {
    return typeCheck(r);
  }

  static T onVec3(Vec3 r)
  {
    return typeCheck(r);
  }

  static T onIdentifier(Identifier r)
  {
    return typeCheck(r);
  }

  return val.visit!(onNull, onReal, onVec2, onVec3, onIdentifier)();
}

float asReal(in Value val)
{
  return valueAs!Real(val).val;
}

alias asVec2 = valueAs!Vec2;
alias asVec3 = valueAs!Vec3;
alias asIdentifier = valueAs!Identifier;

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

  return a.visitDg!Value(&fail!Null, &onReal, &onVec2, &onVec3, &fail!Identifier);
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

  return a.visitDg!Value(&fail!Null, &onReal, &onVec2, &onVec3, &fail!Identifier);
}

Value mul(Value a, Value b)
{
  Value fail(T)(T)
  {
    throw new Exception(format("Can't mul to this type: %s", T.stringof));
  }

  Value onReal(Real r)
  {
    return mkReal(r.val * asReal(b));
  }

  Value onVec2(Vec2 r)
  {
    return Value(r * asReal(b));
  }

  Value onVec3(Vec3 r)
  {
    return Value(r * asReal(b));
  }

  return a.visitDg!Value(&fail!Null, &onReal, &onVec2, &onVec3, &fail!Identifier);
}

Value div(Value a, Value b)
{
  Value fail(T)(T)
  {
    throw new Exception(format("Can't div to this type: %s", T.stringof));
  }

  Value onReal(Real r)
  {
    return mkReal(r.val / asReal(b));
  }

  return a.visitDg!Value(&fail!Null, &onReal, &fail!Vec2, &fail!Vec3, &fail!Identifier);
}

Value mod(Value a, Value b)
{
  Value fail(T)(T)
  {
    throw new Exception(format("Can't div to this type: %s", T.stringof));
  }

  Value onReal(Real r)
  {
    return mkReal(std.math.fmod(r.val, asReal(b)));
  }

  return a.visitDg!Value(&fail!Null, &onReal, &fail!Vec2, &fail!Vec3, &fail!Identifier);
}

string toString(Value a)
{
  static string defaultString(Null)
  {
    return "<null>";
  }

  static string onReal(Real r)
  {
    return format("%.2s", r.val);
  }

  static string onVec2(Vec2 r)
  {
    return format("Vec2(%.2s, %.2s)", r.x, r.y);
  }

  static string onVec3(Vec3 r)
  {
    return format("Vec3(%.2s, %.2s, %.2s)", r.x, r.y, r.z);
  }

  static string onIdentifier(Identifier r)
  {
    return format("%s", r.name);
  }

  return a.visit!(defaultString, onReal, onVec2, onVec3, onIdentifier)();
}

