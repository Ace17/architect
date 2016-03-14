import ktg;
import std.math;

extern(C++) :
void Rotozoom(Texture* dest, ref const(Texture)in_, float angle, float zoom, int filterMode)
{
  const cosTheta = cast(float) cos(angle);
  const sinTheta = cast(float) sin(angle);

  Matrix44 mat = [
    [cosTheta * zoom, -sinTheta * zoom, 0.0f, 0.0f],
    [sinTheta * zoom, cosTheta * zoom, 0.0f, 0.0f],
    [0.0f, 0.0f, 1.0f, 0.0f],
    [0.0f, 0.0f, 0.0f, 1.0f],
  ];
  CoordMatrixTransform(dest, in_, mat, filterMode);
}

