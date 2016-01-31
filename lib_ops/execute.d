/**
 * @file execute.d
 * @brief Execution of the edit list
 * @author Sebastien Alaiwan
 * @date 2015-12-17
 */
import std.traits;
import std.string;
import std.conv;
import std.math;

import dashboard;
import editlist;
import value;

Dashboard executeEditList(EditList editList)
{
  auto state = new EditionState;

  foreach(op; editList.ops)
    g_Operations[op.funcName].call(state, op.args);

  return state.board;
}

///////////////////////////////////////////////////////////////////////////////

class EditionState
{
  Dashboard board;
}

struct RealizeFunc
{
  string category;
  void function(EditionState state, Value[] argVals) call;
}

RealizeFunc[string] g_Operations;

void registerOperator(alias F, string cat, string name)()
{
  static void realize_func(EditionState state, Value[] argVals)
  {
    if(!state.board)
      throw new Exception("please create a dashboard first");

    alias MyArgs = ParameterTypeTuple!F;
    const N = MyArgs.length - 1;

    if(N != argVals.length)
    {
      string s;
      foreach(type; MyArgs[1..$])
      {
        s ~= type.stringof;
        s ~= " ";
      }
      const msg = format("invalid number of arguments for '%s' (%s instead of %s) (%s)", name, argVals.length, N, s);
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
      else static if(is (typeof(arg) == int))
      {
        arg = to!int (lrint(asReal(argVals[i])));
      }
      else
      {
        arg = asReal(argVals[i]);
      }
    }

    F(myArgs);
  }

  g_Operations[name] = RealizeFunc(cat, &realize_func);
}

