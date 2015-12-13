/**
 * @file vect.d
 * @brief
 * @author Sebastien Alaiwan
 * @date 2015-01-25
 */

/*
 * Copyright (C) 2015 - Sebastien Alaiwan
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import misc;

unittest
{
  assertEquals(Vector2f(1, 1), Vector2f(1, 1));
  assertEquals(Vector2f(4, 6), Vector2f(1, 2) + Vector2f(3, 4));
  assertEquals(Vector2f(-2, -3), Vector2f(1, 2) - Vector2f(3, 5));
  assertEquals(26.0f, Vector2f(2, 3) * Vector2f(4, 6));
}

struct Vector2f
{
  float x, y;

  Vector2f opDiv(float f) const
  {
    return Vector2f(x / f, y / f);
  }

  Vector2f opAddAssign(in Vector2f other)
  {
    x += other.x;
    y += other.y;
    return this;
  }

  Vector2f opAdd(in Vector2f other) const
  {
    return Vector2f(x + other.x, y + other.y);
  }

  Vector2f opSub(in Vector2f other) const
  {
    return Vector2f(x - other.x, y - other.y);
  }

  float opMul(in Vector2f other) const
  {
    return other.x * x + other.y * y;
  }

  Vector2f opMul(float other) const
  {
    return Vector2f(other * x, other * y);
  }
}

unittest
{
  auto a = Vec2(1, 0);
  auto b = Vec2(0, 1);
  assertEquals(Vec2(1, 1), a + b);
  assertEquals(Vec2(1, -1), a - b);

  auto c = Vec2(1, 2);
  assertEquals(Vec2(2, 4), c * 2);
}

struct Vec2
{
  float x, y;

  Vec2 opAdd(in Vec2 other) const
  {
    return Vec2(x + other.x, y + other.y);
  }

  Vec2 opSub(in Vec2 other) const
  {
    return Vec2(x - other.x, y - other.y);
  }

  Vec2 opMul(float f) const
  {
    return Vec2(f * x, f * y);
  }
}

unittest
{
  auto a = Vec3(1, 0, 2);
  auto b = Vec3(0, 1, 1);
  assertEquals(Vec3(1, 1, 3), a + b);

  auto c = Vec3(1, 2, 0);
  assertEquals(Vec3(2, 4, 0), c * 2);
}

struct Vec3
{
  float x, y, z;

  Vec3 opAdd(in Vec3 other) const
  {
    return Vec3(x + other.x, y + other.y, z + other.z);
  }

  Vec3 opSub(in Vec3 other) const
  {
    return Vec3(x - other.x, y - other.y, z + other.z);
  }

  Vec3 opMul(float f) const
  {
    return Vec3(f * x, f * y, f * z);
  }
}

