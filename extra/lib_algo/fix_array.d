import std.c.stdlib;

unittest
{
  // primitive type
  auto tab = FixArray!int (13);
  assert(tab.size() == 13);
  assert(tab[0] == 0);
  tab[4] = 777;
  assert(tab[4] == 777);
  tab[12] = 1;
  tab[0] = 3;

  int sum = 0;

  foreach(e; tab)
    sum += e;

  assert(sum == 777 + 1 + 3);
}

struct FixArray (T)
{
public:
  this(int count)
  {
    m_count = count;
    m_elements = cast(T*) malloc(T.sizeof* count);

    for(int i = 0; i < count; ++i)
      m_elements[i] = T.init;
  }

  ~this()
  {
    free(m_elements);
  }

  ref T opIndex(ulong idx)
  {
    return m_elements[idx];
  }

  int opApply(int delegate(ref T) dg)
  {
    for(int i = 0; i < m_count; ++i)
    {
      auto result = dg(m_elements[i]);

      if(result)
        return result;
    }

    return 0;
  }

  int size() const
  {
    return m_count;
  }

private:
  T* m_elements;
  const int m_count;
}

