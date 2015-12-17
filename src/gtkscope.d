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

    addEvents(GdkEventMask.BUTTON_PRESS_MASK);
    addEvents(GdkEventMask.SCROLL_MASK);

    addOnButtonPress(&onButtonPress);
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

    const c = m_frozen ? 0.9 : 0.5;
    glClearColor(c, c, c, 1);
    glClear(GL_COLOR_BUFFER_BIT);

    {
      const mvp = scaleMatrix(exp(m_zoom * 0.1));

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

  static float[16] scaleMatrix(float s)
  {
    float mat[4 * 4];

    for(int x = 0; x < 4; ++x)
      for(int y = 0; y < 4; ++y)
        mat[x + y * 4] = x == y ? s : 0;

    mat[15] = 1;

    return mat;
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
    m_frozen = !m_frozen;
    queueDraw();
    return true;
  }

private:
  GLuint m_Vao;
  GLuint m_Program;
  GLuint m_Mvp;

  bool refreshView()
  {
    if(m_frozen)
      return true;

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
  bool m_frozen;
  int m_zoom = -1;
}

///////////////////////////////////////////////////////////////////////////////
// renderers
///////////////////////////////////////////////////////////////////////////////
static this()
{
  COLOR_LIGHT_RED = new Color(255, 128, 128);
  COLOR_LIGHT_GRAY = new Color(200, 200, 200);
}

