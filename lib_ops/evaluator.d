/**
 * @file evaluator.d
 * @brief Evaluation of expressions
 * @author Sebastien Alaiwan
 * @date 2015-12-17
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

class Env
{
  Value[string] values;
}

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

