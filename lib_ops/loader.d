/**
 * @file loader.d
 * @brief Evaluation of an AST to produce an edit list
 * @author Sebastien Alaiwan
 * @date 2015-11-07
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

import misc;

import ast;
import value;
import parser;
import editlist;
import evaluator;

import dashboard;
import execute;

string[] getOperatorList()
{
  string[] r;

  foreach(name, op; g_Operations)
    r ~= (op.category ~ "." ~ name);

  return r.sort;
}

Dashboard runProgram(string s)
{
  auto ast = parseProgram(s);
  auto editList = buildProgram(ast);
  return executeEditList(editList);
}

EditList buildProgram(AstProgram prog)
{
  auto editList = new EditList;
  realize(editList, prog, "root", []);
  return editList;
}

void realize(EditList editList, AstProgram prog, string name, Value[] args)
{
  if(name in g_Operations)
  {
    editList.ops ~= EditOperation(name, args);
    return;
  }

  realize_user(editList, prog, name, args);
}

void realize_user(EditList editList, AstProgram prog, string name, Value[] argVals)
{
  if(name !in prog.functions)
    throw new Exception(format("unknown template: '%s'", name));

  auto func = prog.functions[name];

  const N = func.argNames.length;

  if(N != argVals.length)
  {
    const msg = format("invalid number of arguments for '%s' (%s instead of %s)", name, argVals.length, N);
    throw new Exception(msg);
  }

  auto env = new Env;

  foreach(i, argVal; argVals)
  {
    const argName = func.argNames[i];
    env.values[argName] = argVal;
  }

  foreach(def; func.defs)
    env.values[def.id] = eval(def.rhs, env);

  foreach(name, def; prog.functions)
    env.values[name] = Value(Identifier(name));

  foreach(ref stmt; func.statements)
  {
    auto argVal = mapArray!eval(stmt.args, env);

    string funcName = stmt.func;

    if(funcName in env.values)
      funcName = asIdentifier(env.values[funcName]).name;

    realize(editList, prog, funcName, argVal);
  }
}

///////////////////////////////////////////////////////////////////////////////
// builtins

Value builtin_vec2(float x, float y)
{
  return mkVec2(x, y);
}

Value builtin_rotate(Vec2 v, float angle)
{
  const x = sin(angle) * v.x + cos(angle) * v.y;
  const y = cos(angle) * v.x - sin(angle) * v.y;
  return mkVec2(x, y);
}

Value builtin_floor(float val)
{
  return mkReal(floor(val));
}

Value builtin_vec3(float x, float y, float z)
{
  return mkVec3(x, y, z);
}

static this()
{
  registerBuiltinFunc!(builtin_floor, "floor")();
  registerBuiltinFunc!(builtin_vec2, "Vec2")();
  registerBuiltinFunc!(builtin_vec3, "Vec3")();
  registerBuiltinFunc!(builtin_rotate, "R")();
}

