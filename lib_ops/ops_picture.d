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

import misc;

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
  const w = cast(int)size.x;
  const h = cast(int)size.y;
  pic.data.length = w * h;
  pic.block = Block(pic.data.ptr, Dimension(w, h), w);

  state.board = pic;
}

void op_fill(Picture pic, Vec3 color)
{
  pic.data[] = toPixel(color);
}

void op_gradient(Picture pic, Vec3 color1, Vec3 color2, Vec2 direction)
{
  for(int y = 0; y < pic.block.dim.w; y++)
  {
    for(int x = 0; x < pic.block.dim.h; x++)
    {
      const alpha = cast(float)(x + y) / cast(float)(pic.block.dim.w);
      pic.block(x, y) = toPixel(blend(color1, color2, alpha));
    }
  }
}

void op_rect(Picture pic, Vec3 color, Vec2 pos, Vec2 size)
{
  for(int y = 0; y < size.x; y++)
  {
    for(int x = 0; x < size.y; x++)
    {
      const ix = cast(int)pos.x + x;
      const iy = cast(int)pos.y + y;

      if(pic.block.isInside(ix, iy))
        pic.block(ix, iy) = toPixel(color);
    }
  }
}

Pixel toPixel(Vec3 v)
{
  return Pixel(v.x, v.y, v.z, 1.0);
}

static this()
{
  g_Operations["picture"] = &op_picture;

  registerRealizeFunc!(op_fill, "fill")();
  registerRealizeFunc!(op_rect, "fillrect")();
  registerRealizeFunc!(op_gradient, "gradient")();
}

