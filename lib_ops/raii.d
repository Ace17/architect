import std.stdio;

struct owning_vector (T)
{
public:
  @property size_t length(size_t size)
  {
    for(auto i = size; i < m_Elements.length; ++i)
      destroy(m_Elements[i]);

    m_Elements.length = size;
    return size;
  }

  void opOpAssign(string sOp)(T element)
  {
    m_Elements ~= element;
  }

  int opApply(int delegate(T) dg)
  {
    foreach(T e; m_Elements)
    {
      auto result = dg(e);

      if(result)
        break;
    }

    return 0;
  }

  int opApply(int delegate(ref const(T)) dg) const
  {
    foreach(ref const(T)e; m_Elements)
    {
      auto result = dg(e);

      if(result)
        break;
    }

    return 0;
  }

  int opApply(int delegate(ref int i, ref const(T)) dg) const
  {
    foreach(int k, ref const(T)e; m_Elements)
    {
      auto result = dg(k, e);

      if(result)
        break;
    }

    return 0;
  }

  void remove(T toRemove)
  {
    T[] oldElements = m_Elements;
    m_Elements.length = 0;
    destroy(toRemove);

    foreach(e; oldElements)
    {
      if(e !is toRemove)
        m_Elements ~= e;
    }
  }

  ~this()
  {
    foreach(e; m_Elements)
      destroy(e);
  }

  auto asArray()
  {
    return m_Elements;
  }

private:
  T[] m_Elements;
}

