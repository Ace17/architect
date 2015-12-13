#version 130

in vec2 v_texCoord;
out vec4 v_color;
uniform sampler2D s_baseMap;

void main() {
  v_color = texture2D(s_baseMap, v_texCoord);
}

// vim: syntax=glsl
