/**
 * @author Sebastien Alaiwan
 * @date 2015-10-11
 */

/*
 * Copyright (C) 2015 - Sebastien Alaiwan
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 */

import std.string;
import std.algorithm;
import std.math;

import gdk.Color;
import gdk.Cairo;
import gdk.GLContext;
import gdk.DragContext;

import gtk.DrawingArea;
import gtk.Statusbar;
import gtk.VPaned;
import gtk.Widget;
import gtk.GLArea;

import glib.Timeout;

import dashboard;
import openglcore;
import glshader;
import i_renderer;

interface IDashboardSource
{
  void lockedUpdate(void delegate(Dashboard) updateFunction);
  string getName();
}

Widget createMonitor(IDashboardSource pinFinder)
{
  auto glmon = new MonitorArea(pinFinder);

  glmon.m_renderers = g_renderers;

  return glmon;
}

static Color COLOR_LIGHT_RED;
static Color COLOR_LIGHT_GRAY;

private:
class MonitorArea : GLArea
{
public:
  this(IDashboardSource pinFinder)
  {
    setAutoRender(true);
    m_pinMonitor = pinFinder;

    m_timer = new Timeout(50, &refreshView);

    addOnButtonPress(&onButtonPress);
    addOnButtonRelease(&onButtonRelease);
    addOnMotionNotify(&onMotionNotify);
    addOnScroll(&onScroll);

    addOnRender(&render);
    addOnRealize(&realize);
    addOnUnrealize(&unrealize);

    showAll();
  }

  ~this()
  {
    .destroy(m_timer);
  }

private:
  void realize(Widget)
  {
    m_currRenderer = cast(int)(m_renderers.length - 1);

    makeCurrent();
    uint position_index;
    uint color_index;
    m_Program = initShaders(&m_Mvp);
    initBuffers();
  }

  void unrealize(Widget)
  {
    makeCurrent();
    glDeleteBuffers(1, &m_Vao);
    glDeleteProgram(m_Program);
  }

  bool render(GLContext, GLArea a)
  {
    makeCurrent();

    const c = 0.5;
    glClearColor(c, c, c, 1);
    glClear(GL_COLOR_BUFFER_BIT);

    {
      const rotationX = makeRotationMatrixY(m_rotationX + m_dragRotationX);
      const rotationY = makeRotationMatrixX(m_rotationY + m_dragRotationY);
      auto mvp = scaleMatrix(exp(m_zoom * 0.1));

      mvp = multMatrix(mvp, rotationX);
      mvp = multMatrix(mvp, rotationY);

      glUseProgram(m_Program);

      // update the "mvp" matrix we use in the shader
      glUniformMatrix4fv(m_Mvp, 1, GL_FALSE, mvp.ptr);

      glBindBuffer(GL_ARRAY_BUFFER, m_Vao);
      glEnableVertexAttribArray(0);

      m_renderers[m_currRenderer].render(m_Program);

      glDisableVertexAttribArray(0);
      glBindBuffer(GL_ARRAY_BUFFER, 0);
      glUseProgram(0);
    }

    glFlush();

    return true;
  }

  void initBuffers()
  {
    // we need to create a VAO to store the other buffers
    glGenVertexArrays(1, &m_Vao);
    glBindVertexArray(m_Vao);

    foreach(r; m_renderers)
      r.createBuffers();
  }

  bool onScroll(GdkEventScroll* event, Widget w)
  {
    m_zoom += event.direction == GdkScrollDirection.UP ? 1 : -1;
    queueDraw();

    return true;
  }

  bool onButtonPress(GdkEventButton* event, Widget w)
  {
    m_drag = true;
    m_dragX = event.x;
    m_dragY = event.y;
    return true;
  }

  bool onMotionNotify(GdkEventMotion* event, Widget w)
  {
    if(m_drag)
    {
      m_dragRotationX = (event.x - m_dragX) / 100.0f;
      m_dragRotationY = (event.y - m_dragY) / 100.0f;
    }

    return true;
  }

  bool onButtonRelease(GdkEventButton* event, Widget w)
  {
    m_drag = false;
    m_rotationX += (event.x - m_dragX) / 100.0f;
    m_rotationY += (event.y - m_dragY) / 100.0f;
    m_dragRotationX = m_dragRotationY = 0;
    return true;
  }

private:
  GLuint m_Vao;
  GLuint m_Program;
  GLuint m_Mvp;

  bool refreshView()
  {
    m_pinMonitor.lockedUpdate(&refreshPin);
    queueRender();

    return true;
  }

  void refreshPin(Dashboard pin)
  {
    foreach(int i, r; m_renderers)
    {
      if(r.update(pin))
      {
        m_currRenderer = cast(int)i;
        break;
      }
    }
  }

  IDashboardSource m_pinMonitor;
  IRenderer[] m_renderers;
  int m_currRenderer;
  Timeout m_timer;
  int m_zoom = -1;
  bool m_drag;
  float m_rotationX = 0, m_rotationY = 0;
  float m_dragRotationX = 0, m_dragRotationY = 0;
  double m_dragX, m_dragY;
}

static this()
{
  COLOR_LIGHT_RED = new Color(255, 128, 128);
  COLOR_LIGHT_GRAY = new Color(200, 200, 200);
}

private:
unittest
{
  assert(identityMatrix() == multMatrix(identityMatrix(), identityMatrix()));
}

float[16] makeRotationMatrixX(float theta)
{
  const cosTheta = cast(float) cos(theta);
  const sinTheta = cast(float) sin(theta);

  return [
    1.0f, 0.0f, 0.0f, 0.0f,
    0.0f, cosTheta, -sinTheta, 0.0f,
    0.0f, sinTheta, cosTheta, 0.0f,
    0.0f, 0.0f, 0.0f, 1.0f,
  ];
}

float[16] makeRotationMatrixY(float theta)
{
  const cosTheta = cast(float) cos(theta);
  const sinTheta = cast(float) sin(theta);

  return [
    cosTheta, 0.0f, sinTheta, 0.0f,
    0.0f, 1.0f, 0.0f, 0.0f,
    -sinTheta, 0.0f, cosTheta, 0.0f,
    0.0f, 0.0f, 0.0f, 1.0f,
  ];
}

float[16] makeRotationMatrixZ(float theta)
{
  const cosTheta = cast(float) cos(theta);
  const sinTheta = cast(float) sin(theta);

  return [
    cosTheta, -sinTheta, 0.0f, 0.0f,
    sinTheta, cosTheta, 0.0f, 0.0f,
    0.0f, 0.0f, 1.0f, 0.0f,
    0.0f, 0.0f, 0.0f, 1.0f,
  ];
}

float[16] identityMatrix()
{
  float r[4 * 4];

  for(int x = 0; x < 4; ++x)
    for(int y = 0; y < 4; ++y)
      r[x + y * 4] = x == y ? 1 : 0;

  return r;
}

float[16] scaleMatrix(float s)
{
  float r[4 * 4];

  for(int x = 0; x < 4; ++x)
    for(int y = 0; y < 4; ++y)
      r[x + y * 4] = x == y ? s : 0;

  r[15] = 1;

  return r;
}

float[16] multMatrix(float[16] a, float[16] b)
{
  float[16] r;

  for(int row = 0; row < 4; ++row)
  {
    for(int col = 0; col < 4; ++col)
    {
      float val = 0;

      for(int k = 0; k < 4; ++k)
        val += a[k + row * 4] * b[col + k * 4];

      r[col + row * 4] = val;
    }
  }

  return r;
}

