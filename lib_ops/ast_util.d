import std.stdio;
import ast;

void dumpAst(AstProgram ast, File* o)
{
  void print(T...)(string fmt, T args)
  {
    o.writef(fmt, args);
  }

  void dumpExpr(AstExpr e)
  {
    void visitFunctionCall(AstFunctionCall call)
    {
      print("%s", call.func);
      print("(");

      foreach(i, arg; call.args)
      {
        if(i > 0)
          print(", ");

        dumpExpr(arg);
      }

      print(")");
    }

    void visitNumber(AstNumber num)
    {
      print("%s", num.value);
    }

    void visitIdentifier(AstIdentifier id)
    {
      print("%s", id.name);
    }

    void visitBinOp(AstBinOp binOp)
    {
      dumpExpr(binOp.children[0]);
      print("%s", toString(binOp.type));
      dumpExpr(binOp.children[1]);
    }

    e.visitDg(&visitIdentifier, &visitNumber, &visitFunctionCall, &visitBinOp);
  }

  foreach(funcName, func; ast.functions)
  {
    o.writefln("%s()", funcName);
    o.writefln("{");

    foreach(def; func.defs)
    {
      print("  let %s = ", def.id);
      dumpExpr(def.rhs);
      o.writefln(";");
    }

    foreach(statement; func.statements)
    {
      o.writef("  ");
      dumpExpr(AstExpr(statement));
      o.writefln(";");
    }

    o.writefln("}");
    o.writefln("");
  }
}

string toString(BinOp op)
{
  final switch(op)
  {
  case BinOp.Add: return "+";
  case BinOp.Sub: return "-";
  case BinOp.Mul: return "*";
  case BinOp.Div: return "/";
  case BinOp.Mod: return "%";
  }
}

