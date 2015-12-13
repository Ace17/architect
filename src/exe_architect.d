import std.array;
import std.file;
import std.stdio;

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
    if(args.length <= 1)
      throw new Exception("Bad usage");

    auto text = loadTextFile(args[1]);
    auto ast = parseProgram(text);
    dumpAst(ast, &stdout);

    auto editList = buildProgram(ast);
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
  writefln("-------------");
  writefln("Edit list");

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

