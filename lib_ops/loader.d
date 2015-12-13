/**
 * @file loader.d
 * @brief Construction of a graph from an AST
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
import std.traits;

import misc;

import ast;
import value;
import parser;
import editlist;

import dashboard;

Dashboard runProgram(string s)
{
  auto ast = parseProgram(s);
  auto editList = buildProgram(ast);

  auto state = new EditionState;

  foreach(op; editList.ops)
    g_Operations[op.funcName] (state, op.args);

  return state.board;
}

EditList buildProgram(AstProgram prog)
{
  auto editList = new EditList;
  realize(editList, prog, "root", []);
  return editList;
}

string[] getOperatorList()
{
  return g_Operations.keys.sort;
}

class Env
{
  Value[string] values;
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

  foreach(ref stmt; func.statements)
  {
    auto argVal = mapArray!eval(stmt.args, env);

    realize(editList, prog, stmt.func, argVal);
  }
}

///////////////////////////////////////////////////////////////////////////////

Value eval(AstExpr expr, Env env)
{
  Value evalNumber(AstNumber n)
  {
    return mkReal(n.value);
  }

  Value evalBinOp(AstBinOp binop)
  {
    const op1 = eval(binop.children[0], env);
    const op2 = eval(binop.children[1], env);
    final switch(binop.type)
    {
    case BinOp.Add: return add(op1, op2);
    case BinOp.Sub: return sub(op1, op2);
    case BinOp.Mul: return mul(op1, op2);
    }
  }

  Value evalIdentifier(AstIdentifier id)
  {
    if(id.name !in env.values)
      throw new Exception(format("Undeclared identifier '%s'", id.name));

    return env.values[id.name];
  }

  Value evalFunctionCall(AstFunctionCall call)
  {
    auto argVals = mapArray!eval(call.args, env);

    if(call.func !in g_Builtins)
      throw new Exception(format("Unknown function '%s'", call.func));

    return g_Builtins[call.func] (argVals);
  }

  return expr.visitDg(&evalIdentifier, &evalNumber, &evalFunctionCall, &evalBinOp);
}

///////////////////////////////////////////////////////////////////////////////
// builtins

Value builtin_vec2(float x, float y)
{
  return mkVec2(x, y);
}

Value builtin_vec3(float x, float y, float z)
{
  return mkVec3(x, y, z);
}

///////////////////////////////////////////////////////////////////////////////

class EditionState
{
  Dashboard board;
}

alias RealizeFunc = void function(EditionState state, Value[] argVals);
RealizeFunc[string] g_Operations;

void registerRealizeFunc(alias F, string name)()
{
  static void realize_func(EditionState state, Value[] argVals)
  {
    if(!state.board)
      throw new Exception("please create a dashboard first");

    alias MyArgs = ParameterTypeTuple!F;
    const N = MyArgs.length - 1;

    if(N != argVals.length)
    {
      const msg = format("invalid number of arguments for '%s' (%s instead of %s)", name, argVals.length, N);
      throw new Exception(msg);
    }

    MyArgs myArgs;

    myArgs[0] = cast(MyArgs[0])state.board;

    if(!myArgs[0])
    {
      const msg = format("invalid dashboard type, required: %s", MyArgs[0].stringof);
      throw new Exception(msg);
    }

    foreach(i, ref arg; myArgs[1 .. $])
    {
      static if(is (typeof(arg) == Vec2))
      {
        arg = asVec2(argVals[i]);
      }
      else static if(is (typeof(arg) == Vec3))
      {
        arg = asVec3(argVals[i]);
      }
      else
      {
        arg = asReal(argVals[i]);
      }
    }

    F(myArgs);
  }

  g_Operations[name] = &realize_func;
}

///////////////////////////////////////////////////////////////////////////////

alias BuiltinFunc = Value function(Value[] argVals);
BuiltinFunc[string] g_Builtins;

void registerBuiltinFunc(alias F, string name)()
{
  static Value wrappedFunction(Value[] argVals)
  {
    alias MyArgs = ParameterTypeTuple!F;
    const N = MyArgs.length;

    if(N != argVals.length)
    {
      const msg = format("invalid number of arguments for '%s' (%s instead of %s)", name, argVals.length, N);
      throw new Exception(msg);
    }

    MyArgs myArgs;

    foreach(i, ref arg; myArgs)
      arg = asReal(argVals[i]);

    return F(myArgs);
  }

  g_Builtins[name] = &wrappedFunction;
}

static this()
{
  registerBuiltinFunc!(builtin_vec2, "Vec2")();
  registerBuiltinFunc!(builtin_vec3, "Vec3")();
}

