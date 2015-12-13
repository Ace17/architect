/**
 * @file ops_picture.d
 * @brief Picture processing/synthesis
 * @author Sebastien Alaiwan
 * @date 2015-11-07
 */

/*
 * Copyright (C) 2015 - Sebastien Alaiwan
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 */

import std.math;
import std.algorithm;

import array2d;
import misc: clamp;

import loader;
import value;
import dashboard_picture;

void op_picture(EditionState state, Value[] values)
{
  if(values.length != 1)
    throw new Exception("picture takes one Vec2 argument");

  auto size = asVec2(values[0]);

  size.x = max(size.x, 16);
  size.y = max(size.y, 16);

  auto pic = new Picture;
  pic.pixels = new Matrix!Pixel(cast(int)size.x, cast(int)size.y);
  state.board = pic;
}

void op_fill(Picture pic, Vec3 color)
{
  void setToLuma(int x, int y, ref Pixel pel)
  {
    pel.r = color.x;
    pel.g = color.y;
    pel.b = color.z;
    pel.a = 1.0f;
  }

  pic.pixels.scan(&setToLuma);
}

void op_rect(Picture pic, Vec3 color, Vec2 pos, Vec2 size)
{
  for(int y = 0; y < size.x; y++)
  {
    for(int x = 0; x < size.y; x++)
    {
      const pel = Pixel(color.x, color.y, color.z, 1.0f);
      const ix = cast(int)pos.x + x;
      const iy = cast(int)pos.y + y;

      if(isInside(pic.pixels, ix, iy))
        pic.pixels.set(ix, iy, pel);
    }
  }
}

static this()
{
  g_Operations["picture"] = &op_picture;

  registerRealizeFunc!(op_fill, "fill")();
  registerRealizeFunc!(op_rect, "fillrect")();
}

