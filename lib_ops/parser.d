/**
 * @author Sebastien Alaiwan
 * @date 2015-01-04
 */

/*
 * Copyright (C) 2015 - Sebastien Alaiwan
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 */

import std.conv;
import std.algorithm;
import std.stdio;
import std.string;
import std.typecons;

import misc;

import lexer;
import ast;

AstProgram parseProgram(string text)
{
  try
  {
    auto tokens = runLexer(text);
    auto stream = new Stream(tokens);

    auto parser = scoped!Parser(stream);
    return parser.program();
  }
  catch(Exception e)
  {
    throw new Exception(format("syntax error: %s", e.msg));
  }
}

bool sameGraph(string s1, string s2)
{
  return runLexer(s1) == runLexer(s2);
}

private:
class Parser
{
  this(Stream s_)
  {
    s = s_;
  }

  AstProgram program()
  {
    AstProgram r;

    while(frontType(s) != TK.EndOfFile)
    {
      auto func = funcDef();
      r.functions[func.id] = func;
    }

    return r;
  }

  AstFuncDef funcDef()
  {
    AstFuncDef r;
    r.id = expect(s, TK.Identifier);

    // arguments
    expect(s, TK.LeftPar);
    bool firstArg = true;

    while(frontType(s) != TK.RightPar)
    {
      if(!firstArg)
        expect(s, TK.Comma);

      r.argNames ~= expect(s, TK.Identifier);
      firstArg = false;
    }

    expect(s, TK.RightPar);

    // body
    expect(s, TK.LeftBrace);

    while(frontType(s) != TK.RightBrace)
    {
      if(frontType(s) == TK.Let)
      {
        expect(s, TK.Let);
        AstDefinition def;
        def.id = expect(s, TK.Identifier);
        expect(s, TK.Equal);
        def.rhs = expression();
        r.defs ~= def;
      }
      else
      {
        AstFunctionCall call;
        call.func = expect(s, TK.Identifier);
        call.args = argList();
        r.statements ~= call;
      }

      expect(s, TK.Semicolon);
    }

    expect(s, TK.RightBrace);

    return r;
  }

  AstExpr expression()
  {
    return binOp();
  }

  AstExpr binOp()
  {
    AstExpr r = factor();

    for(;;)
    {
      BinOp type;

      if(frontType(s) == TK.Plus)
        type = BinOp.Add;
      else if(frontType(s) == TK.Minus)
        type = BinOp.Sub;
      else
        break;

      pop(s);
      auto other = factor();
      r = AstExpr(AstBinOp(type, [r, other]));
    }

    return r;
  }

  AstExpr factor()
  {
    AstExpr r = atom();

    for(;;)
    {
      BinOp type;

      if(frontType(s) == TK.Mul)
        type = BinOp.Mul;
      else
        break;

      pop(s);
      auto other = atom();
      r = AstExpr(AstBinOp(type, [r, other]));
    }

    return r;
  }

  AstExpr atom()
  {
    if(frontType(s) == TK.Identifier)
    {
      const name = expect(s, TK.Identifier);

      if(frontType(s) == TK.LeftPar)
      {
        AstFunctionCall call;
        call.func = name;
        call.args = argList();
        return AstExpr(call);
      }
      else
      {
        auto id = AstIdentifier(name);
        return AstExpr(id);
      }
    }
    else if(frontType(s) == TK.Float)
    {
      auto num = expect(s, TK.Float);

      if(num[$ - 1] == 'f')
        num.length--;

      return AstExpr(AstNumber(to!float (num)));
    }
    else if(frontType(s) == TK.Number)
    {
      auto num = expect(s, TK.Number);
      return AstExpr(AstNumber(to!float (num)));
    }
    else
    {
      throw new Exception("expected an expression");
    }
  }

  AstExpr[] argList()
  {
    AstExpr[] r;
    expect(s, TK.LeftPar);

    while(frontType(s) != TK.RightPar)
    {
      if(r.length > 0)
        expect(s, TK.Comma);

      r ~= expression();
    }

    expect(s, TK.RightPar);

    return r;
  }

  Stream s;
}

TK frontType(Stream s)
{
  if(s.empty())
    return TK.EndOfFile;
  else
    return s.tokens[0].type;
}

string frontLexem(Stream s)
{
  if(s.empty())
    return "<eof>";
  else
    return s.tokens[0].lexem;
}

string expect(Stream s, TK expectedType)
{
  if(s.empty() || frontType(s) != expectedType)
    throw new Exception("Unexpected token: '" ~ frontLexem(s) ~ "', expected " ~ to!string(expectedType));

  return pop(s);
}

string pop(Stream s)
{
  string lexem = frontLexem(s);
  s.tokens = s.tokens[1 .. $];
  return lexem;
}

class Stream
{
  this(const(Token)[] tk)
  {
    tokens = tk;
  }

  bool empty() const
  {
    return tokens.length == 0;
  }

  const(Token)[] tokens;
}

