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
  pic.blocks = [];
  pic.blocks ~= Block(pic.data.ptr, Dimension(w, h), w);

  state.board = pic;
}

void op_fill(Picture pic, Vec3 color)
{
  auto block = pic.currBlock;

  for(int y = 0; y < block.dim.h; y++)
    for(int x = 0; x < block.dim.w; x++)
      block(x, y) = toPixel(color);
}

void op_gradient(Picture pic, Vec3 color1, Vec3 color2, Vec2 direction)
{
  auto block = pic.currBlock;

  for(int y = 0; y < block.dim.h; y++)
  {
    for(int x = 0; x < block.dim.w; x++)
    {
      const alpha = cast(float)(x + y) / cast(float)(block.dim.w);
      block(x, y) = toPixel(blend(color1, color2, alpha));
    }
  }
}

void op_rect(Picture pic, Vec3 color, Vec2 pos, Vec2 size)
{
  for(int y = 0; y < size.y; y++)
  {
    for(int x = 0; x < size.x; x++)
    {
      const ix = cast(int)pos.x + x;
      const iy = cast(int)pos.y + y;

      if(pic.currBlock.isInside(ix, iy))
        pic.currBlock()(ix, iy) = toPixel(color);
    }
  }
}

Pixel toPixel(Vec3 v)
{
  return Pixel(v.x, v.y, v.z, 1.0);
}

void op_select(Picture pic, Vec2 pos, Vec2 size)
{
  auto block = pic.currBlock();
  auto addr = block.pixels + cast(int)pos.x + block.stride * cast(int)pos.y;
  auto subBlock = Block(addr, Dimension(cast(int)size.x, cast(int)size.y), block.stride);
  pic.blocks ~= subBlock;
}

void op_deselect(Picture pic)
{
  if(pic.blocks.length <= 1)
    throw new Exception("Nothing to deselect");

  pic.blocks.length--;
}

static this()
{
  g_Operations["picture"] = &op_picture;

  registerRealizeFunc!(op_fill, "fill")();
  registerRealizeFunc!(op_rect, "fillrect")();
  registerRealizeFunc!(op_gradient, "gradient")();
  registerRealizeFunc!(op_select, "select")();
  registerRealizeFunc!(op_deselect, "deselect")();
}

