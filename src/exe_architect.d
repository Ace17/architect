import std.array;
import std.file;
import std.stdio;
import std.getopt;

import misc;

import ast_util;
import loader;
import parser;
import value;
import editlist;

int main(string[] args)
{
  try
  {
    bool mustDumpEditList;
    bool mustDumpAst;

    getopt(
      args,
      "dump", &mustDumpEditList,
      "ast", &mustDumpAst,
      );

    if(args.length <= 1)
      throw new Exception("One input file must be specified");

    auto text = loadTextFile(args[1]);
    auto ast = parseProgram(text);

    if(mustDumpAst)
      dumpAst(ast, &stdout);

    auto editList = buildProgram(ast);

    if(mustDumpEditList)
      dumpEditList(editList);

    return 0;
  }
  catch(Exception e)
  {
    stderr.writefln("Fatal: %s", e.msg);
    return 1;
  }
}

void dumpEditList(EditList editList)
{
  foreach(op; editList.ops)
  {
    auto args = mapArray!valueToString(op.args);
    writefln("%s(%s)", op.funcName, join(args, ", "));
  }
}

string valueToString(Value val)
{
  return toString(val);
}

string loadTextFile(string file)
{
  return cast(string)std.file.read(file);
}

