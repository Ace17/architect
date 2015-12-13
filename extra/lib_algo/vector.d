/**
 * @file vector.d
 * @brief A RAII friendly vector class.
 * @author Sebastien Alaiwan
 * @date 2014-06-02
 */

// Copyright (C) 2015 - Sebastien Alaiwan
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

import std.traits;
import std.algorithm;
import std.stdio;

unittest
{
  vector!int v;
  v.push_back(1);
  v.push_back(2);
  v.push_back(3);

  auto v2 = v;
  assert(v2.size() == 3);
}

struct vector(T)
{
public:
  T[] m_data;

  ~this()
  {
    foreach(ref elt; m_data)
    clear(elt);
  }

  void push_back(T t)
  {
    immutable idx = m_data.length;
    m_data.length = idx + 1;
    move(m_data[idx], t);
  }

  void pop_back()
  {
    if(empty())
      return;
    clear(m_data[$-1]);
    m_data.length = m_data.length - 1;
  }

  size_t size() const
  {
    return m_data.length;
  }

  bool empty() const
  {
    return m_data.length == 0;
  }

  static if(isAssignable!(T, T))
  {
    void opAssign(ref vector!T other)
    {
      m_data.length = other.m_data.length;
      for(int i=0; i < other.m_data.length; ++i)
        m_data[i] = other.m_data[i];
    }
  }
  else
  {
    @disable this(this)
    {
    }
  }

  int opApply(int delegate(ref const(T) v) dg)
  {
    int r;
    foreach(ref element; m_data)
    {
      r = dg(element);
      if(r == 1)
        break;
    }
    return r;
  }
}

