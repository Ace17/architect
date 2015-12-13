/**
 * @file geom_pin.d
 * @brief Types for geometry processing
 * @author Sebastien Alaiwan
 * @date 2015-07-13
 */

import std.math;
import std.stdio;

import misc;

import base_module;
import vect;

alias float Pixel;

class MeshOutputPin : IOutputPin
{
public:
  this(Module m, string name)
  {
    m_pModule = m;
    m_Name = name;
    m_Data = new Mesh;
  }

  const(Mesh) getData() const
  {
    return m_Data;
  }

  string getName() const
  {
    return m_Name;
  }

  inout (Module)getOwner() inout
  {
    return m_pModule;
  }

  Mesh getBlockForWriting()
  {
    return m_Data;
  }

private:
  Mesh m_Data;
  Module m_pModule;
  string m_Name;
}

alias BaseInputPin!(Mesh, MeshOutputPin) MeshInputPin;

class Mesh
{
public:
  Vector2f[] vertices;
  int[2][] segments;
}

