/**
 * @brief Dead-simple lexer. Only supports regular languages.
 * @author Sebastien Alaiwan
 */

/*
 * Copyright (C) 2015 - Sebastien Alaiwan
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 */

import std.stdio;
import std.regex;
import std.algorithm;
import std.string;

import misc;

unittest
{
  TK[] filter(in Token[] tokens)
  {
    TK[] r;

    foreach(t; tokens)
      r ~= t.type;

    return r;
  }

  assertEquals([TK.Number], filter(runLexer("0")));
  assertEquals([TK.Let], filter(runLexer("let")));
  assertEquals([TK.Identifier], filter(runLexer("wavelet")));
  assertEquals([TK.Float], filter(runLexer("3.14")));
  assertEquals([TK.Float], filter(runLexer("3.14f")));
  assertEquals([TK.Float], filter(runLexer("-3.14f")));
  assertEquals([TK.Float], filter(runLexer(".99f")));
  assertEquals([TK.Identifier, TK.Semicolon], filter(runLexer("hello;")));
  assertEquals([TK.Plus], filter(runLexer("+")));
  assertEquals([TK.Minus], filter(runLexer("-")));
  assertEquals([TK.Mul], filter(runLexer("*")));
  assertEquals([TK.Div], filter(runLexer("/")));
  assertEquals([TK.Mod], filter(runLexer("%")));
  assertEquals([TK.Identifier], filter(runLexer("var123 // comment\n")));
  assertEquals([TK.Let, TK.Identifier, TK.Equal, TK.Number], filter(runLexer("let a = -1\n")));
}

Token[] runLexer(string s)
{
  Token[] tokens;

  while(s.length > 0)
  {
    auto token = nextToken(s);

    if(token.type != TK.White)
      tokens ~= token;

    s = s[token.lexem.length .. $];
  }

  return tokens;
}

struct Token
{
  TK type;
  string lexem;

  string toString() const
  {
    return "<" ~ lexem ~ ">";
  }
}

enum TK
{
  EndOfFile,
  White,
  Let,
  Identifier,
  Number,
  Float,
  Dot,
  Equal,
  Plus,
  Minus,
  Mul,
  Div,
  Mod,
  Semicolon,
  Comma,
  LeftPar,
  RightPar,
  LeftBrace,
  RightBrace,
  LeftBracket,
  RightBracket,
}

private:
Token nextToken(string s)
{
  struct Rule
  {
    string regex;
    TK type;
  }

  immutable Rule[] Rules =
  [
    { r"^-?[0-9]*\.[0-9]+f?", TK.Float },
    { r"^-?[0-9]+", TK.Number },
    { "^let", TK.Let },
    { r"^[a-zA-Z0-9_]+", TK.Identifier },
    { r"^;", TK.Semicolon },
    { r"^\.", TK.Dot },
    { r"^\=", TK.Equal },
    { r"^\s+", TK.White },
    { "^//.*\n", TK.White }, // C++ style comments
    { r"^,", TK.Comma },
    { r"^\+", TK.Plus },
    { r"^\*", TK.Mul },
    { r"^\/", TK.Div },
    { r"^\%", TK.Mod },
    { r"^-", TK.Minus },
    { r"^\(", TK.LeftPar },
    { r"^\)", TK.RightPar },
    { r"^\{", TK.LeftBrace },
    { r"^\}", TK.RightBrace },
    { r"^\[", TK.LeftBracket },
    { r"^\]", TK.RightBracket },
  ];

  foreach(rule; Rules)
  {
    auto m = match(s, rule.regex);

    if(m.empty())
      continue;

    auto f = m.front();

    if(!f.captures.empty())
    {
      Token r;
      r.lexem = f.captures.front();
      r.type = rule.type;
      return r;
    }
  }

  throw new Exception(format("Unrecognized token: '%s'", s));
}

