import std.stdio;
import std.algorithm;
import std.conv;
import vector;
import stack;
import set;
import list;
import queue;
import misc;
import options;
import memory;
import pointer;
import array2d : array2d;

int main(string[] args)
{

  {
    writefln("----------------------------------------");
    writefln("* Stack");

    auto s = new stack.stack!int;
    s.push(1);
    s.push(3);
    s.push(5);
    s.push(7);
    writefln("stack=%s", s);

    while(!s.empty)
    {
      writefln("Top: %s", s.top());
      writefln("pop");
      s.pop;
    }
  }

  {
    writefln("----------------------------------------");
    writefln("* List");

    auto l = new list.list!(int);
    for(int i=0; i < 8; ++i)
      l.push_back((i*47)%33);
    for(int i=0; i < 8; ++i)
      l.push_front((i*32)%43);
    writefln("list=%s", l);
    l.sort();
    writefln("list=%s", l);
  }

  {
    writefln("----------------------------------------");
    writefln("* Linked node");

    class LinkedObject
    {
    public:
      this(int index)
      {
        m_Node = linked_node!LinkedObject(this);
        m_Index = index;
      }

      linked_node!LinkedObject m_Node;
      const int m_Index;
    }

    linked_node!LinkedObject linkedList;
    for(int i=1; i <= 10; ++i)
    {
      auto element = new LinkedObject(i);
      linkedList.insert_after(&element.m_Node);
    }

    writefln("Initial list:");
    foreach(element; linkedList)
    writefln("- %s (%s)", element, element.m_Index);

    writefln("Removing some elements:");
    foreach(element; linkedList)
    {
      if(element.m_Index % 3)
      {
        writefln("- removing %s", element.m_Index);
        element.m_Node.remove();
      }
    }

    writefln("New list:");
    foreach(element; linkedList)
    writefln("- %s (%s)", element, element.m_Index);
  }

  {
    writefln("----------------------------------------");
    writefln("* Options");

    auto optionParser = new CmdLineOptions;

    bool fullscreen;
    string id, path, key;
    int priority;
    string[] files;
    optionParser.addOption("s", "fullscreen", &fullscreen);
    optionParser.addOption("i", "id", &id);
    optionParser.addOption("p", "path", &path);
    optionParser.addOption("k", "key", &key);
    optionParser.addOption("y", "priority", &priority);
    optionParser.addOption("f", "files", &files);

    auto arg = ["exe_coder", "-i", "coder.channels.channel1", "--path", "D:", "--key", "yo", "--priority", "4", "--files", "a", "b", "c", "-s" ];

    optionParser.parse(arg);
    writefln("Parsed : %s", arg);
    writefln("fullscreen: %s", fullscreen);
    writefln("id: '%s'", id);
    writefln("path: '%s'", path);
    writefln("key: '%s'", key);
    writefln("priority: %s", priority);
    writefln("files: %s", files);

    writefln("Usage:");
    optionParser.showUsage();
  }

  {
    writefln("----------------------------------------");
    writefln("* Options: custom types");

    struct Dimension
    {
      int width, height;
    }

    class DimOption : IOption
    {
      this(Dimension* dim)
      {
        pDim = dim;
      }

      override string shortName() const { return "s"; }
      override string longName() const { return "size"; }
      override string typeDesc() const { return "WxH"; }
      override string desc() const { return "Picture size"; }
  
      override bool parse(ref string[] args)
      {
        string word = args[0];
        args = args[1..$];
        auto numbers = splitter(word, "x");
        pDim.width = to!int(numbers.front()); numbers.popFront();
        pDim.height = to!int(numbers.front()); numbers.popFront();
        return true;
      }

      Dimension* pDim;
    }

    auto parser = new CmdLineOptions;

    Dimension dim;
    parser.addOption(new DimOption(&dim));

    auto arg = ["prog", "-s", "192x128"];

    parser.parse(arg);
    writefln("dim: %s", dim);

    writefln("Usage:");
    parser.showUsage();
  }

  // vector
  {
    writefln("----------------------------------------");
    writefln("* vector");

    vector.vector!int v;
    v.push_back(1);
    v.push_back(2);
    v.push_back(3);
    v.push_back(4);
    v.push_back(5);

    auto v2 = v;

    foreach(elt; v)
    {
      writefln("- %s", elt);
      if(elt >= 3)
        break;
    }

    struct MyStruct
    {
      this(int a=0)
      {
        writefln("MyStruct.this()");
      }

      ~this()
      {
        writefln("MyStruct.~this()");
      }
    }

    vector.vector!MyStruct v3;
    v3.push_back(MyStruct(0));
  }

  // unique_ptr
  {
    writefln("----------------------------------------");
    writefln("* unique_ptr");

    int numInstances = 0;

    class MyClass
    {
    public:
      this(string name)
      {
        m_Name = name;
        writefln("MyClass.this() (numInstances=%s)", numInstances);
        numInstances ++;
      }

      ~this()
      {
        numInstances --;
        writefln("MyClass.~this() (numInstances=%s)", numInstances);
      }

      void print()
      {
        writefln("My name is '%s'", m_Name);
      }

    private:
      string m_Name;
    }

    writefln("numInstances=%s", numInstances);
    assert(numInstances == 0);

    {
      writefln("* base test");
      auto p = unique_ptr!MyClass(new MyClass("Object"));
      p.print();
    }

    writefln("numInstances=%s", numInstances);
    assert(numInstances == 0);

    {
      writefln("* make_unique");
      auto p = make_unique(new MyClass("Object2"));
      p.print();
    }

    writefln("numInstances=%s", numInstances);
    assert(numInstances == 0);

    {
      writefln("* array");
      vector.vector!(unique_ptr!MyClass) v;

      writefln("Allocating");
      for(int i=0; i < 10; ++i)
        v.push_back(make_unique(new MyClass("Object" ~ to!string(i))));

      writefln("Disallocating");
      for(int i=0; i < 10; ++i)
        v.pop_back();

      //auto v2 = v;

      writefln("Terminated");
    }

    writefln("numInstances=%s", numInstances);
    assert(numInstances == 0);
  }

  // pointer
  {
    writefln("----------------------------------------");
    writefln("* ptr");

    class TheClass
    {
      void f()
      {
        writefln("TheClass.f()");
      }

      void fConst() const
      {
        writefln("TheClass.fConst()");
      }
    }

    {
      writefln("* base test");
      const auto p = make_ptr(new TheClass);
      p.f();
      p.fConst();
    }

    {
      writefln("* re-assign test");
      ptr!TheClass p = new TheClass;
      p = ptr!TheClass(new TheClass);

      auto p2 = p.get();
    }
  }

  // array2d
  {
    writefln("----------------------------------------");
    writefln("* array2d");

    auto m = new array2d!int(8, 8);
    for(int i=0; i < 8; ++i)
      for(int j=0; j < 8; ++j)
        m.set(i, j, i+j*j);
  }

  // misc.explode
  {
    writefln("----------------------------------------");
    writefln("* misc.explode");

    assert(explode("hello;world", ';') == ["hello", "world"]);
    assert(explode("hello;world;", ';') == ["hello", "world"]);
    assert(explode("a--b--c", ';') == ["a--b--c"]);
    assert(explode("a--b--c", '-') == ["a", "", "b", "", "c"]);
    assert(explode("hello world !", ' ') == ["hello", "world", "!"]);
  }

  return 0;
}
