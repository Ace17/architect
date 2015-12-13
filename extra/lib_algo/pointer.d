/**
 * @file pointer.d
 * @brief A non-owning pointer that does not forward constness.
 * @author Sebastien Alaiwan
 * @date 2013-04-12
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

unittest
{
  class Dependency
  {
  }

  class UserClass
  {
    this(Dependency d)
    {
      m_Dep = d;
    }

    const ptr!Dependency m_Dep;
  }

  auto dep = new Dependency;
  auto obj = new UserClass(dep);
}

struct ptr(T)
{
public:
  this(T pObject)
  {
    m_p = pObject;
  }

  auto opDispatch(string s, U...)(U i) const
  {
    // cast away the constness from the context
    auto nonConstObject = cast(T)(m_p);
    return mixin("nonConstObject." ~ s)(i);
  }

  T get() const
  {
    auto nonConstObject = cast(T)(m_p);
    return nonConstObject;
  }

private:
  T m_p;
}

ptr!T make_ptr(T)(T pObject)
{
  return ptr!T(pObject);
}

