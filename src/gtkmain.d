/**
 * @brief Entry point for GTK version.
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
import std.typecons;
import std.conv;
import std.file;
import std.algorithm: max;
import std.math;

import gobject.ObjectG;
import gobject.ParamSpec;

import gdk.Event;

import gtk.HPaned;
import gtk.Label;
import gtk.Main;
import gtk.MainWindow;
import gtk.ScrolledWindow;
import gtk.Statusbar;
import gtk.TextBuffer;
import gtk.TextIter;
import gtk.TextView;
import gtk.VBox;
import gtk.Widget;
import pango.PgFontDescription;

import gsv.SourceView;

import gtkc.gdktypes;

import misc;

import dashboard;
import cmdline;
import parser;
import loader;
import gtkscope;

int main(string[] args)
{
  auto cfg = parseCmdLine(args);

  if(cfg.bHelp)
    return 0;

  Main.disableSetlocale();
  Main.init(args);

  auto wnd = new MyMainWindow;

  if(cfg.sFilename != "")
    wnd.loadFile(cfg.sFilename);

  Main.run();
  return 0;
}

class MyMainWindow : MainWindow, IDashboardSource
{
public:
  this()
  {
    super("Architect");

    m_dashboard = new Dashboard;
    m_filename = "untitled.ops";

    auto opList = createOperatorList();
    auto editor = createTextEditor();
    auto monitor = createMonitor(this);
    auto hbox = new HPaned(editor, monitor);
    hbox.setPosition(800);
    hbox = new HPaned(opList, hbox);
    hbox.setPosition(200);

    auto vbox = new VBox(false, 10);
    vbox.packStart(createStatusBar(), false, false, 0);
    vbox.packStart(hbox, true, true, 0);
    vbox.packEnd(createStatusBar(), false, false, 0);

    addOnKeyPress(&onKeyDown);

    setFocus(m_textView);

    setStatusBar("Ready.");

    resize(1280, 720);
    add(vbox);
    showAll();
  }

  string getName()
  {
    return m_targetId;
  }

  void lockedUpdate(void delegate(Dashboard) f)
  {
    f(m_dashboard);
  }

private:
  Widget createOperatorList()
  {
    string text;
    text ~= "Available operators:\n";

    foreach(type; getOperatorList())
      text ~= format("* %s\n", type);

    auto r = new Label(text, false);
    r.setSizeRequest(30, -1);
    return r;
  }

  Widget createTextEditor()
  {
    auto r = new ScrolledWindow(null, null);
    m_textView = new SourceView;
    m_textView.setAutoIndent(true);
    m_textView.setIndentOnTab(true);
    m_textView.setInsertSpacesInsteadOfTabs(true);
    m_textView.setShowLineNumbers(true);
    m_textView.getBuffer().addOnChanged(&onTextChange);

    auto font = new PgFontDescription("monospace", 10);
    m_textView.modifyFont(font);

    r.add(m_textView);
    return r;
  }

  Widget createStatusBar()
  {
    m_statusBar = new Statusbar;
    m_statusBar.push(0, "");
    return m_statusBar;
  }

  bool onKeyDown(Event evt, Widget)
  {
    uint keyval;
    evt.getKeyval(keyval);
    GdkModifierType state;
    const shift = evt.getState(state) && state & GdkModifierType.SHIFT_MASK;
    switch(keyval)
    {
    case 65307: // ESC
      {
        Main.quit();
        return true;
      }
    case 65471: // F2
      {
        setStatusBar(format("Saved to '%s'", m_filename));
        std.file.write(m_filename, m_textView.getBuffer().getText());
        return true;
      }
    case 65473: // F4
      {
        loadFile(m_filename);
        return true;
      }
    case 65474: // F5
      {
        m_targetId = getSelectedText(m_textView.getBuffer());
        return true;
      }
    case 65475: // F6
      {
        return true;
      }
    case 65476: // F7
      {
        incrementNumberUnderCursor(shift ? -0.1 : -1);
        return true;
      }
    case 65477: // F8
      {
        incrementNumberUnderCursor(shift ? +0.1 : +1);
        return true;
      }
    default:
      {
        return false;
      }
    }
  }

  void loadFile(string filename)
  {
    try
    {
      m_filename = filename;

      const s = cast(string)std.file.read(filename);
      m_textView.getBuffer().setText(s);

      loadGraph(s);

      setStatusBar(format("Loaded '%s'.", filename));
    }
    catch(Exception e)
    {
      setStatusBar(format("Can't load graph: %s", e.msg), true);
    }
  }

  void loadGraph(string s)
  {
    auto newDashboard = runProgram(s);
    .destroy(m_dashboard);
    m_dashboard = newDashboard;
  }

  void incrementNumberUnderCursor(float amount)
  {
    auto buff = m_textView.getBuffer();
    TextIter start, end;

    if(!findNumberAtCursor(buff, start, end))
      return;

    try
    {
      const originalValue = to!float (buff.getText(start, end, true));

      const newValue = originalValue + amount;

      string newStringValue;

      if(isInteger(newValue))
        newStringValue = format("%s", round(newValue));
      else
        newStringValue = format("%s", newValue);

      buff.delet(start, end);
      buff.insert(start, newStringValue);
      start.backwardChar();
      buff.placeCursor(start);
    }
    catch(Exception)
    {
    }
  }

  static bool isInteger(float value)
  {
    return abs(value - round(value)) < 0.01;
  }

  void onTextChange(TextBuffer buff)
  {
    try
    {
      const text = buff.getText();

      if(sameGraph(m_prevGraphText, text))
        return;

      loadGraph(text);
      setStatusBar("OK");
      m_prevGraphText = text;
    }
    catch(Exception e)
    {
      setStatusBar(format("Invalid graph: %s", e.msg), true);
      m_prevGraphText = "";
    }
  }

  void setStatusBar(string text, bool isError = false)
  {
    m_statusBar.modifyBg(GtkStateType.NORMAL, isError ? COLOR_LIGHT_RED : COLOR_LIGHT_GRAY);
    m_statusBar.pop(0);
    m_statusBar.push(1, text);
  }

  string m_filename;
  SourceView m_textView;
  Statusbar m_statusBar;
  Dashboard m_dashboard;
  string m_targetId = "none";

  string m_prevGraphText;
}

string getSelectedText(TextBuffer buff)
{
  TextIter start, end;

  if(!buff.getSelectionBounds(start, end))
    return "";

  return buff.getText(start, end, true);
}

string getNumberAtCursor(TextBuffer buff)
{
  TextIter start, end;

  if(!findNumberAtCursor(buff, start, end))
    return "";

  return buff.getText(start, end, true);
}

bool findNumberAtCursor(TextBuffer buff, out TextIter start, out TextIter end)
{
  {
    buff.getIterAtMark(start, buff.getInsert());

    while(isNumber(getOneChar(buff, start)))
      start.backwardChar();

    if(getOneChar(buff, start) == '-')
      start.backwardChar();

    start.forwardChar();
  }

  {
    buff.getIterAtMark(end, buff.getInsert());

    while(isNumber(getOneChar(buff, end)))
      end.forwardChar();
  }

  return true;
}

char getOneChar(TextBuffer buff, TextIter start)
{
  auto end = new TextIter;
  end.assign(start);

  if(!end.forwardChar())
    return char.init;

  return buff.getText(start, end, true)[0];
}

bool isNumber(char c)
{
  return c == '.' || (c >= '0' && c <= '9');
}

