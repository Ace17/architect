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
import dashboard_mesh;

void op_mesh(EditionState state, Value[])
{
  state.board = new Mesh;
}

void op_rect(Mesh b)
{
  b.vertices =
  [
    /* 0 */ Vec3(0, 0, 0),
    /* 1 */ Vec3(0, 1, 0),
    /* 2 */ Vec3(1, 1, 0),
    /* 3 */ Vec3(1, 0, 0),
    /* 4 */ Vec3(0, 0, 1),
    /* 5 */ Vec3(0, 1, 1),
    /* 6 */ Vec3(1, 1, 1),
    /* 7 */ Vec3(1, 0, 1),
  ];

  b.faces =
  [
    [0, 1, 2], [0, 2, 3],
    [4, 6, 5], [4, 7, 6],
    [0, 3, 7], [0, 7, 4],
    [1, 6, 2], [1, 5, 6],
    [0, 5, 1], [0, 4, 5],
    [3, 2, 6], [3, 6, 7],
  ];
}

static this()
{
  g_Operations["mesh"] = RealizeFunc("mesh", &op_mesh);

  registerOperator!(op_rect, "mesh", "cube")();
}

