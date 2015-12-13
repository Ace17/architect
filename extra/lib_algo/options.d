/**
 * @file options.d
 * @brief A command-line parser utility.
 * @author Sebastien Alaiwan
 * @date 2014-06-02
 */

// Boost Software License - Version 1.0 - August 17th, 2003
//
// Permission is hereby granted, free of charge, to any person or organization
// obtaining a copy of the software and accompanying documentation covered by
// this license (the "Software") to use, reproduce, display, distribute,
// execute, and transmit the Software, and to prepare derivative works of the
// Software, and to permit third-parties to whom the Software is furnished to
// do so, all subject to the following:
//
// The copyright notices in the Software and this entire statement, including
// the above license grant, this restriction and the following disclaimer,
// must be included in all copies of the Software, in whole or in part, and
// all derivative works of the Software, unless such copies or derivative
// works are solely in the form of machine-executable object code generated by
// a source language processor.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
// SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
// FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.

import std.stdio;
import std.conv;
import std.algorithm : startsWith;

class CmdLineOptions
{
public:
  void addFlag(string sShortName, string sLongName, bool* pOption, string sDesc="")
  {
    addOption(sShortName, sLongName, pOption, sDesc);
  }

  void addOption(T)(string sShortName, string sLongName, T* pOption, string sDesc="")
  {
    auto opt = new GenericOption!(T)(pOption);
    opt.m_ShortName = sShortName;
    opt.m_LongName = sLongName;
    opt.m_Desc = sDesc;
    m_Options ~= opt;
  }

  void addOption(IOption opt)
  {
    m_Options ~= opt;
  }

  void parse(string[] args)
  {
    if(args.length == 0 || args[0] == "")
      throw new Exception("expected program name as first argument");

    // skip program name (args[0])
    args = args[1..$];

    while(args.length > 0)
    {
      immutable word = args[0];

      if(startsWith(word, "--"))
      {
        bool bNoMatch = true;
        foreach(o; m_Options)
        {
          if(word[2..$] == o.longName())
          {
            args = args[1..$];
            bNoMatch = false;
            o.parse(args);
            break;
          }
        }

        if(bNoMatch)
          throw new Exception("unknown option: " ~ word);
      }
      else if(startsWith(word, "-"))
      {
        bool bNoMatch = true;
        foreach(o; m_Options)
        {
          if(word[1..$] == o.shortName())
          {
            args = args[1..$];
            bNoMatch = false;
            o.parse(args);
            break;
          }
        }

        if(bNoMatch)
          throw new Exception("unknown option: " ~ word);
      }
      else
      {
        args = args[1..$];
        m_Files ~= word;
      }
    }
  }

  void showUsage()
  {
    foreach(opt; m_Options)
    {
      auto line = "-" ~ opt.shortName() ~ ", --" ~ opt.longName();
      auto typeDesc = opt.typeDesc();
      if(typeDesc != "")
        line ~= " <" ~ typeDesc ~ ">";
      write("    ");
      write(line);
      for(auto i=line.length;i < 32;++i)
        write(" ");
      writeln(opt.desc());
    }
  }

  string[] getFiles()
  {
    return m_Files;
  }

private:

  IOption[] m_Options;
  string[] m_Files;
}

class IOption
{
  abstract string shortName() const;
  abstract string longName() const;
  abstract string typeDesc() const;
  abstract string desc() const;

  abstract bool parse(ref string[] args);
}

class GenericOption(T) : IOption
{
  override string shortName() const
  {
    return m_ShortName;
  }

  override string longName() const
  {
    return m_LongName;
  }

  override string typeDesc() const
  {
    return typeString!(T).s;
  }

  override string desc() const
  {
    return m_Desc;
  }

  string m_ShortName, m_LongName;
  string m_Desc;

  this(T* pValue)
  {
    m_pValue = pValue;
  }

  T* m_pValue;

  override bool parse(ref string[] args)
  {
    return parseTypedOption(*m_pValue, args);
  }
}

template typeString(T:int)
{
  static immutable s = "number";
}

template typeString(T:string)
{
  static immutable s = "string";
}

template typeString(T:string[])
{
  static immutable s = "files...";
}

template typeString(T:bool)
{
  static immutable s = "";
}

bool parseTypedOption(ref int pValue, ref string[] args)
{
  if(args == [])
    throw new Exception("Expected a number");

  pValue = to!(int)(args[0]);
  args = args[1..$];
  return true;
}

bool parseTypedOption(ref bool pValue, ref string[] args)
{
  pValue = true;
  return true;
}

bool parseTypedOption(ref string pValue, ref string[] args)
{
  if(args == [])
    throw new Exception("Expected a string");

  pValue = args[0];
  args = args[1..$];
  return true;
}

bool parseTypedOption(ref string[] pValue, ref string[] args)
{
  if(args == [])
    throw new Exception("Expected a list of strings");

  while(args.length > 0 && args[0][0] != '-')
  {
    pValue ~= args[0];
    args = args[1..$];
  }
  return true;
}

unittest
{
  auto opt = new CmdLineOptions;

  bool flag = false;
  opt.addOption("f", "flag", &flag);

  auto arg = ["prog", "-f", "yo" ];
  opt.parse(arg);

  assert(flag);
  assert(opt.getFiles() == [ "yo" ]);
}

unittest
{
  auto opt = new CmdLineOptions;

  string fullscreen;
  opt.addOption("f", "fullscreen", &fullscreen, "Use fullscreen mode");

  auto arg = ["prog", "-f", "val", "a", "b", "-f", "c", "-f", "d" ];
  opt.parse(arg);

  assert(opt.getFiles() == [ "a", "b" ]);
}

unittest
{
  auto opt = new CmdLineOptions;

  string path;
  opt.addOption("p", "path", &path, "my desc");

  auto arg = ["prog", "-p" ];

  try
  {
    opt.parse(arg);
    assert(false);
  }
  catch(Exception e)
  {
  }
}

