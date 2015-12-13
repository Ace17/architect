/**
 * @file dashboard_picture.d
 * @brief Types for picture processing
 * @author Sebastien Alaiwan
 * @date 2015-12-13
 */

/*
 * Copyright (C) 2015 - Sebastien Alaiwan
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 */

import dashboard;
import array2d;

struct Dimension
{
  int w, h;
}

class Picture : Dashboard
{
  this()
  {
    pixels = new Matrix!Pixel(256, 256);
  }

  Dimension getSize() const
  {
    return Dimension(pixels.getWidth(), pixels.getHeight());
  }

  Matrix!Pixel pixels;
}

struct Pixel
{
  float r, g, b, a;
}

struct Block
{
  Pixel* pixels;
  Dimension dim;
  int stride;

  this(Pixel * _pixels, Dimension _dim, int _stride)
  {
    pixels = _pixels;
    dim = _dim;
    stride = _stride;
  }

  ref Pixel opCall(BlockPos pos)
  {
    return this.opCall(pos.x, pos.y);
  }

  Pixel opCall(BlockPos pos) const
  {
    return this.opCall(pos.x, pos.y);
  }

  ref Pixel opCall(int x, int y)
  {
    return pixels[x + y * stride];
  }

  Pixel opCall(int x, int y) const
  {
    return pixels[x + y * stride];
  }
}

struct BlockPos
{
  int x, y;
}
