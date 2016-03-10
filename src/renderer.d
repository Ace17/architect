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

// This part only depends on OpenGL, not GTK

import std.algorithm: min, max;

import openglcore;

import i_renderer;
import dashboard;
import dashboard_mesh;
import dashboard_tilemap;
import dashboard_picture;
import dashboard_sound;
import vect;

import misc;

const VERTEX_SIZE = 8;

class MeshRenderer : IRenderer
{
public:
  void createBuffers()
  {
    glGenBuffers(1, &m_Vbo);
    m_Texture = createBasicTexture(1234);
  }

  bool update(Dashboard p)
  {
    auto mesh = cast(Mesh)p;

    if(!mesh)
      return false;

    m_length = 0;
    GLfloat[] lines;

    foreach(face; mesh.faces)
    {
      foreach(i, vid; face)
      {
        auto vertex = mesh.vertices[vid];
        immutable normal = Vec3(1, 0, 0);
        immutable u = [0, 1, 1];
        immutable v = [0, 0, 1];
        lines ~=[vertex.x, vertex.y, vertex.z, normal.x, normal.y, normal.z, u[i], v[i]];
        m_length++;
      }
    }

    glBindBuffer(GL_ARRAY_BUFFER, m_Vbo);
    glBufferData(GL_ARRAY_BUFFER, lines.length * float.sizeof, lines.ptr, GL_STATIC_DRAW);

    return true;
  }

  void render(int programId)
  {
    glBindTexture(GL_TEXTURE_2D, m_Texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

    const positionLoc = glGetAttribLocation(programId, "a_position");
    glEnableVertexAttribArray(positionLoc);
    glVertexAttribPointer(positionLoc, 3, GL_FLOAT, GL_FALSE, VERTEX_SIZE * GLfloat.sizeof, null);

    // connect the uv coords to the "v_texCoord" attribute of the vertex shader
    const texCoordLoc = glGetAttribLocation(programId, "a_texCoord");
    glEnableVertexAttribArray(texCoordLoc);
    glVertexAttribPointer(texCoordLoc, 2, GL_FLOAT, GL_TRUE, VERTEX_SIZE * GLfloat.sizeof,
                          cast(GLvoid*)(6 * GLfloat.sizeof));

    glDrawArrays(GL_TRIANGLES, 0, m_length);
    glBindTexture(GL_TEXTURE_2D, 0);
  }

private:
  int m_length;
  GLuint m_Vbo, m_Texture;
}

class TileMapRenderer : IRenderer
{
public:
  void createBuffers()
  {
    glGenBuffers(1, &m_Vbo);

    foreach(int i, ref texture; m_Texture)
      texture = createBasicTexture(i);
  }

  bool update(Dashboard p)
  {
    m_building = cast(TileMap)p;
    return m_building !is null;
  }

  void render(int programId)
  {
    const scroll = Vec2(-NUM_TILE_COLS / 2, -NUM_TILE_ROWS / 2);

    for(int y = 0; y < NUM_TILE_ROWS; ++y)
      for(int x = 0; x < NUM_TILE_COLS; ++x)
        drawTile(programId, scroll + Vec2(x, y), m_building.tiles[x][y] % m_Texture.length);
  }

  TileMap m_building;

private:
  void drawTile(int programId, Vec2 pos, int tile)
  {
    const u0 = 0;
    const u1 = 1;
    const v0 = 0;
    const v1 = 1;

    immutable GLfloat[] lines =
    [
      pos.x + 0, pos.y + 0, 0, 0, 0, 1, u0, v0,
      pos.x + 1, pos.y + 0, 0, 0, 0, 1, u1, v0,
      pos.x + 1, pos.y + 1, 0, 0, 0, 1, u1, v1,

      pos.x + 1, pos.y + 1, 0, 0, 0, 1, u1, v1,
      pos.x + 0, pos.y + 1, 0, 0, 0, 1, u0, v1,
      pos.x + 0, pos.y + 0, 0, 0, 0, 1, u0, v0,
    ];

    const positionLoc = glGetAttribLocation(programId, "a_position");
    const texCoordLoc = glGetAttribLocation(programId, "a_texCoord");

    glBindTexture(GL_TEXTURE_2D, m_Texture[tile]);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

    glBindBuffer(GL_ARRAY_BUFFER, m_Vbo);
    glBufferData(GL_ARRAY_BUFFER, lines.length * float.sizeof, lines.ptr, GL_STATIC_DRAW);

    glEnableVertexAttribArray(positionLoc);
    glVertexAttribPointer(positionLoc, 3, GL_FLOAT, GL_FALSE, VERTEX_SIZE * GLfloat.sizeof, null);

    // connect the uv coords to the "v_texCoord" attribute of the vertex shader
    glEnableVertexAttribArray(texCoordLoc);
    glVertexAttribPointer(texCoordLoc, 2, GL_FLOAT, GL_TRUE, VERTEX_SIZE * GLfloat.sizeof,
                          cast(GLvoid*)(6 * GLfloat.sizeof));

    glDrawArrays(GL_TRIANGLES, 0, cast(int)lines.length / VERTEX_SIZE);
    glBindTexture(GL_TEXTURE_2D, 0);
  }

  GLuint m_Vbo;
  GLuint[3] m_Texture;
}

class PictureRenderer : IRenderer
{
public:
  void createBuffers()
  {
    glGenBuffers(1, &m_Vbo);
    glGenTextures(1, &m_Texture);

    glBindTexture(GL_TEXTURE_2D, m_Texture);

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  }

  bool update(Dashboard p)
  {
    auto pic = cast(Picture)p;

    if(!pic)
      return false;

    static ubyte convertPixel(float v)
    {
      const scaled = cast(int)(v * 255.0f);
      return cast(ubyte)(clamp(scaled, 0, 255));
    }

    const size = pic.blocks[0].dim;
    auto block = pic.blocks[0];

    ubyte[] picBuffer;
    picBuffer.length = size.w * size.h * 4;

    for(int y = 0; y < size.h; ++y)
      for(int x = 0; x < size.w; ++x)
      {
        auto pel = block(x, y);
        picBuffer[(x + y * size.w) * 4 + 0] = convertPixel(pel.r);
        picBuffer[(x + y * size.w) * 4 + 1] = convertPixel(pel.g);
        picBuffer[(x + y * size.w) * 4 + 2] = convertPixel(pel.b);
        picBuffer[(x + y * size.w) * 4 + 3] = 255;
      }

    glBindTexture(GL_TEXTURE_2D, m_Texture);
    glTexImage2D(GL_TEXTURE_2D,
                 0,
                 GL_RGBA,
                 size.w, size.h,
                 0,
                 GL_RGBA,
                 GL_UNSIGNED_BYTE,
                 picBuffer.ptr);

    return true;
  }

  void render(int programId)
  {
    const nx = 0.0f;
    const ny = 0.0f;
    const nz = 1.0f;

    immutable GLfloat[] lines =
    [
      -1, -1, 0, nx, ny, nz, 0, 0,
      +1, -1, 0, nx, ny, nz, 1, 0,
      +1, +1, 0, nx, ny, nz, 1, 1,

      +1, +1, 0, nx, ny, nz, 1, 1,
      -1, +1, 0, nx, ny, nz, 0, 1,
      -1, -1, 0, nx, ny, nz, 0, 0,
    ];

    const positionLoc = glGetAttribLocation(programId, "a_position");
    const texCoordLoc = glGetAttribLocation(programId, "a_texCoord");

    glBindTexture(GL_TEXTURE_2D, m_Texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    glBindBuffer(GL_ARRAY_BUFFER, m_Vbo);

    glBufferData(GL_ARRAY_BUFFER, lines.length * float.sizeof, lines.ptr, GL_STATIC_DRAW);
    // glVertexAttribPointer(0, 4, GL_FLOAT, GL_FALSE, 0, null);

    (glEnableVertexAttribArray(positionLoc));
    (glVertexAttribPointer(positionLoc, 3, GL_FLOAT, GL_FALSE, VERTEX_SIZE * GLfloat.sizeof, null));

    // connect the uv coords to the "v_texCoord" attribute of the vertex shader
    (glEnableVertexAttribArray(texCoordLoc));
    (glVertexAttribPointer(texCoordLoc, 2, GL_FLOAT, GL_TRUE, VERTEX_SIZE * GLfloat.sizeof,
                           cast(GLvoid*)(6 * GLfloat.sizeof)));

    glDrawArrays(GL_TRIANGLES, 0, cast(int)lines.length / VERTEX_SIZE);
    glBindTexture(GL_TEXTURE_2D, 0);
  }

private:
  GLuint m_Vbo, m_Texture;
}

class SoundRenderer : IRenderer
{
public:
  void createBuffers()
  {
    glGenBuffers(1, &m_Vbo);
    glGenTextures(1, &m_Texture);

    glBindTexture(GL_TEXTURE_2D, m_Texture);

    // glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, PIC_DIM.w, PIC_DIM.h, 0, GL_RGBA, GL_UNSIGNED_BYTE, m_picBuffer.ptr);

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  }

  bool update(Dashboard p)
  {
    auto sound = cast(Sound)p;

    if(!sound)
      return false;

    static ubyte convertPixel(float v)
    {
      const scaled = v * 255.0f;
      return cast(ubyte)(min(scaled, 255.0f));
    }

    ubyte[] picBuffer;
    picBuffer.length = DIM.w * DIM.h * 4;
    picBuffer[] = 255;

    int last_y = DIM.h / 2;

    for(int x = 0; x < DIM.w; ++x)
    {
      const fx = cast(float)x / DIM.w;
      const N = sound.samples.length;
      const sampleIdx = cast(int)(fx * N);

      const fy = (sound.samples[sampleIdx] + 1.0) / 2.0f * DIM.h;
      const new_y = clamp(cast(int)fy, 0, DIM.h - 1);

      const val = 0;
      int y1 = last_y;
      int y2 = new_y;
      order(y1, y2);

      for(int y = y1; y <= y2; ++y)
      {
        picBuffer[(x + y * DIM.w) * 4 + 0] = val;
        picBuffer[(x + y * DIM.w) * 4 + 1] = val;
        picBuffer[(x + y * DIM.w) * 4 + 2] = val;
        picBuffer[(x + y * DIM.w) * 4 + 3] = 255;
      }

      last_y = new_y;
    }

    glBindTexture(GL_TEXTURE_2D, m_Texture);
    glTexImage2D(GL_TEXTURE_2D,
                 0,
                 GL_RGBA,
                 DIM.w, DIM.h,
                 0,
                 GL_RGBA,
                 GL_UNSIGNED_BYTE,
                 picBuffer.ptr);

    return true;
  }

  void render(int programId)
  {
    const nx = 0.0f;
    const ny = 0.0f;
    const nz = 1.0f;
    immutable GLfloat[] lines =
    [
      // pos, normal, uv
      -1, -1, 0, nx, ny, nz, 0, 0,
      +1, -1, 0, nx, ny, nz, 1, 0,
      +1, +1, 0, nx, ny, nz, 1, 1,

      +1, +1, 0, nx, ny, nz, 1, 1,
      -1, +1, 0, nx, ny, nz, 0, 1,
      -1, -1, 0, nx, ny, nz, 0, 0,
    ];

    const positionLoc = glGetAttribLocation(programId, "a_position");
    const texCoordLoc = glGetAttribLocation(programId, "a_texCoord");

    glBindTexture(GL_TEXTURE_2D, m_Texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    glBindBuffer(GL_ARRAY_BUFFER, m_Vbo);

    glBufferData(GL_ARRAY_BUFFER, lines.length * float.sizeof, lines.ptr, GL_STATIC_DRAW);
    // glVertexAttribPointer(0, 4, GL_FLOAT, GL_FALSE, 0, null);

    (glEnableVertexAttribArray(positionLoc));
    (glVertexAttribPointer(positionLoc, 3, GL_FLOAT, GL_FALSE, VERTEX_SIZE * GLfloat.sizeof, null));

    // connect the uv coords to the "v_texCoord" attribute of the vertex shader
    (glEnableVertexAttribArray(texCoordLoc));
    (glVertexAttribPointer(texCoordLoc, 2, GL_FLOAT, GL_TRUE, VERTEX_SIZE * GLfloat.sizeof,
                           cast(GLvoid*)(6 * GLfloat.sizeof)));

    glDrawArrays(GL_TRIANGLES, 0, cast(int)lines.length / VERTEX_SIZE);
    glBindTexture(GL_TEXTURE_2D, 0);
  }

private:
  GLuint m_Vbo;
  GLuint m_Texture;
  enum DIM = Dimension(2048, 256);
}

class DefaultRenderer : IRenderer
{
public:
  void createBuffers()
  {
    glGenBuffers(1, &m_Vbo);
  }

  bool update(Dashboard p)
  {
    return true;
  }

  void render(int programId)
  {
    immutable GLfloat[] vertex_data =
    [
      -1.0f, -1.0f, 0.0f, 1.0f,
      +1.0f, +1.0f, 0.0f, 1.0f,

      -1.0f, +1.0f, 0.0f, 1.0f,
      +1.0f, -1.0f, 0.0f, 1.0f,
    ];

    glBindBuffer(GL_ARRAY_BUFFER, m_Vbo);
    glBufferData(GL_ARRAY_BUFFER, vertex_data.length * float.sizeof, vertex_data.ptr, GL_STATIC_DRAW);

    glVertexAttribPointer(0, 4, GL_FLOAT, GL_FALSE, 0, null);

    glDrawArrays(GL_LINES, 0, cast(int)vertex_data.length / 4);
    glFlush();
  }

  GLuint m_Vbo;
}

static this()
{
  g_renderers ~= new MeshRenderer;
  g_renderers ~= new PictureRenderer;
  g_renderers ~= new TileMapRenderer;
  g_renderers ~= new SoundRenderer;
  g_renderers ~= new DefaultRenderer;
}

private:
int createBasicTexture(int seed)
{
  uint texture;
  glGenTextures(1, &texture);

  glBindTexture(GL_TEXTURE_2D, texture);

  const W = 32;
  const H = 32;

  ubyte[H * W * 4] picBuffer;

  for(int y = 0; y < H; ++y)
    for(int x = 0; x < W; ++x)
    {
      int r, g, b, a;

      if(seed == 1234)
      {
        bool border = x == 0 || y == 0 || x == W - 1 || y == H - 1;
        r = ((x / 10) + (y / 10)) % 2 ? 0 : 0x80;
        g = 0xC0;
        b = 0xC0;
        a = 0xFF;
      }
      else
      {
        bool border = x == 0 || y == 0 || x == W - 1 || y == H - 1;
        r = border ? 0x00 : 0x80 * max(1, seed * 3);
        g = border ? 0x00 : 0x80 * max(1, seed * 3);
        b = border ? 0x00 : 0xC0 * max(1, seed * 3);
        a = 0xFF;
      }

      picBuffer[(x + y * W) * 4 + 0] = cast(ubyte)r;
      picBuffer[(x + y * W) * 4 + 1] = cast(ubyte)g;
      picBuffer[(x + y * W) * 4 + 2] = cast(ubyte)b;
      picBuffer[(x + y * W) * 4 + 3] = cast(ubyte)a;
    }

  glBindTexture(GL_TEXTURE_2D, texture);
  glTexImage2D(GL_TEXTURE_2D,
               0,
               GL_RGBA,
               W, H,
               0,
               GL_RGBA,
               GL_UNSIGNED_BYTE,
               picBuffer.ptr);
  return texture;
}

