/**
 * @file ops_building.d
 * @brief Tilemap edition
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

import std.algorithm;
import std.math;

import execute;
import value;
import dashboard_tilemap;

void op_building(EditionState state, Value[])
{
  state.board = new TileMap;
}

void op_rect(TileMap b, Vec2 pos, Vec2 size, float tile)
{
  const ix = cast(int) round(pos.x);
  const iy = cast(int) round(pos.y);
  const iw = cast(int) round(size.x);
  const ih = cast(int) round(size.y);
  const itile = cast(int) round(tile);

  const left = max(ix, 0);
  const bottom = max(iy, 0);
  const right = min(ix + iw, b.tiles.length);
  const top = min(iy + ih, b.tiles[0].length);

  for(int j = bottom; j < top; ++j)
    for(int i = left; i < right; ++i)
      b.tiles[i][j] = itile;
}

static this()
{
  g_Operations["tilemap"] = RealizeFunc("building", &op_building);

  registerOperator!(op_rect, "tilemap", "rect")();
}

