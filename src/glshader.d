/**
 * @author Sebastien Alaiwan
 * @date 2015-11-04
 */

/*
 * Copyright (C) 2015 - Sebastien Alaiwan
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 */

import core.exception;
import openglcore;

GLuint initShaders(uint* mvp_location_out)
{
  immutable VertShaderCode = cast(string)import ("vertex.glsl");

  const vertex = compileShader(GL_VERTEX_SHADER, VertShaderCode ~ "\0");
  scope(exit) glDeleteShader(vertex);

  immutable FragShaderCode = cast(string)import ("fragment.glsl");

  const fragment = compileShader(GL_FRAGMENT_SHADER, FragShaderCode ~ "\0");
  scope(exit) glDeleteShader(fragment);

  const program = glCreateProgram();

  glAttachShader(program, vertex);
  scope(exit) glDetachShader(program, vertex);

  glAttachShader(program, fragment);
  scope(exit) glDetachShader(program, fragment);

  glLinkProgram(program);

  int status = 0;
  glGetProgramiv(program, GL_LINK_STATUS, &status);

  if(status == GL_FALSE)
  {
    int log_len = 0;
    glGetProgramiv(program, GL_INFO_LOG_LENGTH, &log_len);

    char[] buffer;
    buffer.length = log_len + 1;
    glGetProgramInfoLog(program, log_len, null, buffer.ptr);

    glDeleteProgram(program);

    throw new Exception("Linking error: " ~ buffer.idup);
  }

  return program;
}

GLuint compileShader(int type, string source)
{
  const shader = glCreateShader(type);
  scope(failure) glDeleteShader(shader);

  const(char)*srcPtr = source.ptr;
  glShaderSource(shader, 1, &srcPtr, null);
  glCompileShader(shader);

  int status;
  glGetShaderiv(shader, GL_COMPILE_STATUS, &status);

  if(status == GL_FALSE)
  {
    int len;
    glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &len);

    char[] buffer;
    buffer.length = len + 1;
    glGetShaderInfoLog(shader, len, null, buffer.ptr);

    const sType = type == GL_VERTEX_SHADER ? "vertex" : "fragment";

    throw new Exception("Compilation error in " ~ sType ~ " shader: " ~ buffer.idup);
  }

  return shader;
}

