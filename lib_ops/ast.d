/**
 * @brief AST definition
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

import std.typecons;
import algebraic: Either;

struct AstProgram
{
  AstFuncDef[string] functions;
}

struct AstFuncDef
{
  string id;
  string[] argNames;
  AstFunctionCall[] statements;
  AstDefinition[] defs;
}

struct AstDefinition
{
  string id;
  AstExpr rhs;
}

struct AstSettings
{
  string id;
  float[] values;
}

///////////////////////////////////////////////////////////////////////////////
// expressions

struct AstFunctionCall
{
  string func;
  AstExpr[] args;
}

struct AstIdentifier
{
  string name;
}

struct AstBinOp
{
  BinOp type;
  AstExpr[] children;
}

enum BinOp
{
  Add,
  Sub,
  Mul,
}

struct AstNumber
{
  float value;
}

alias Either!(AstIdentifier, AstNumber, AstFunctionCall, AstBinOp) AstExpr;

