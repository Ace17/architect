/**
 * @author Sebastien Alaiwan
 * @date 2011-11-13
 */

/*
 * Copyright (C) 2015 - Sebastien Alaiwan
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import std.stdio;
import std.conv;
import std.algorithm;

import base_module;
import factory;
import raii;
import topological;

unittest
{
  import video_pin;
  class MockModule : BaseModule!("mock", false)
  {
    this()
    {
      addInputPin(new VideoInputPin(this, "in"));
      addOutputPin(new VideoOutputPin(this, "out"));
      add(Parameter("param", 0, 1, &param));
    }

    override void process()
    {
      ++processCount;
    }

    int processCount = 0;
    float param;
  }

  // test that a module is not reprocessed twice
  {
    auto g = new GraphModule;
    auto m = new MockModule;
    g.addModule(m);
    assert(m.processCount == 0);
    g.process();
    assert(m.processCount == 1);
    g.process();
    assert(m.processCount == 1);
  }

  // test that a module is reprocessed when a parameter is changed
  {
    auto g = new GraphModule;
    auto A = new MockModule;
    g.addModule(A);
    g.process();
    assert(A.processCount == 1);

    A.setValue(0, 0.5f);

    g.process();
    assert(A.processCount == 2, "Just-configured module should be reprocessed");
  }

  // test that a module is reprocessed when its input is re-connected
  {
    auto g = new GraphModule;
    auto A = new MockModule;
    auto B = new MockModule;
    g.addModule(A);
    g.addModule(B);
    g.process();
    assert(A.processCount == 1);
    assert(B.processCount == 1);

    B.getInputPin(0).connectWith(A.getOutputPin(0));

    g.process();
    assert(A.processCount == 1, "Unchanged module shouldn't be reprocessed");
    assert(B.processCount == 2, "Just-connected module should be reprocessed");

    B.getInputPin(0).disconnect();
    g.process();
    assert(A.processCount == 1, "Unchanged module shouldn't be reprocessed");
    assert(B.processCount == 3, "Just-disconnected module should be reprocessed");
  }

  // test that a module is reprocessed when one of its input has been reprocessed
  {
    auto g = new GraphModule;
    auto A = new MockModule;
    auto B = new MockModule;
    g.addModule(A);
    g.addModule(B);
    B.getInputPin(0).connectWith(A.getOutputPin(0));
    g.process();
    assert(A.processCount == 1);
    assert(B.processCount == 1);

    A.setValue(0, 0.5f);
    g.process();
    assert(A.processCount == 2);
    assert(B.processCount == 2);
  }
}

class GraphModule : Module
{
public:
  this()
  {
    m_Type = "graph";
  }

  void addModule(Module mod)
  {
    // if the module has no ID, create one.
    if(mod.getId() == "" || mod.getId() == "<undef>")
    {
      string id;

      int i = 0;

      do
        id = mod.getType() ~ "_" ~ to!string(i++);
      while(findModule(id));

      mod.setId(id);
    }

    m_Modules ~= mod;
    m_modulesByName[mod.getId()] = mod;
    mod.enterGraph(this);
  }

  void aliasModule(Module mod, string name)
  {
    assert(canFind(m_Modules.asArray(), mod));
    m_modulesByName[name] = mod;
  }

  void removeModule(Module mod)
  {
    mod.leaveGraph(this);
    m_Modules.remove(mod);

    static Module[string] remove(Module[string] list, Module toRemove)
    {
      Module[string] r;

      foreach(name, mod; list)
      {
        if(mod !is toRemove)
          r[name] = mod;
      }

      return r;
    }

    m_modulesByName = remove(m_modulesByName, mod);
  }

  override string getType() const
  {
    return m_Type;
  }

  override void process()
  {
    recomputeOrder();

    bool[Module] mustProcess;

    foreach(m; m_orderedModules)
      mustProcess[m] = false;

    foreach(m; m_orderedModules)
    {
      bool moduleIsDirty = false;

      if(m.isDirty())
        moduleIsDirty = true;

      foreach(parent; getParents(m))
        if(mustProcess[parent])
          moduleIsDirty = true;

      mustProcess[m] = moduleIsDirty;
    }

    foreach(m; m_orderedModules)
    {
      if(!mustProcess[m])
        continue;

      m.process();
      m.clearDirty();
    }
  }

  override int getNumInputPins() const
  {
    return 0;
  }

  override int getNumOutputPins() const
  {
    return 0;
  }

  override inout (IInputPin)getInputPin(int iIndex) inout
  {
    return null;
  }

  override inout (IOutputPin)getOutputPin(int iIndex) inout
  {
    return null;
  }

  override void setId(string Id)
  {
    m_Id = Id;
  }

  override string getId() const
  {
    return m_Id;
  }

  void enumModules(void delegate(Module) f)
  {
    foreach(Module m; m_Modules)
      f(m);
  }

  Module findModule(string id)
  {
    if(id !in m_modulesByName)
      return null;

    return m_modulesByName[id];
  }

  void setType(string s)
  {
    m_Type = s;
  }

  override float[] saveState() const
  {
    return [];
  }

  override void loadState(float[] state)
  {
  }

  override void enterGraph(GraphModule g)
  {
  }

  override void leaveGraph(GraphModule g)
  {
  }

  override string[] getParamList() const
  {
    return [];
  }

  override float getValue(int idx) const
  {
    return 0.0f;
  }

  override void setValue(int idx, float val)
  {
  }

  override bool isDirty() const
  {
    return m_isDirty;
  }

  override void clearDirty()
  {
    m_isDirty = false;
  }

  override void setDirty()
  {
    m_isDirty = true;
  }

private:
  void recomputeOrder()
  {
    Module[][Module] children;

    foreach(m; m_Modules)
      children[m] = [];

    foreach(child; m_Modules)
    {
      foreach(parent; getParents(child))
        children[parent] ~= child;
    }

    Module[] getChildren(Module m)
    {
      return children[m];
    }

    m_orderedModules = topologicalSort(m_Modules.asArray(), &getChildren);
  }

  Module[] getParents(Module child)
  {
    Module[] r;

    for(int i = 0; i < child.getNumInputPins(); ++i)
    {
      auto pin = child.getInputPin(i);

      if(pin.isConnected())
        r ~= pin.getConnected().getOwner();
    }

    return r;
  }

  owning_vector!Module m_Modules;
  Module[] m_orderedModules;
  Module[string] m_modulesByName;
  string m_Id;
  string m_Type;
  bool m_isDirty;
}

