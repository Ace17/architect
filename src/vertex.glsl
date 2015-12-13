#version 130

in vec3 a_position;
in vec2 a_texCoord;
out vec2 v_texCoord;

uniform mat4 mvp;

void main()
{
  gl_Position = mvp * vec4(a_position, 1.0);
  v_texCoord = a_texCoord;
}

// vim: syntax=glsl
