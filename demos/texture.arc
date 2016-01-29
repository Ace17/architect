root()
{
  picture(Vec2(256, 256));
  texture(Vec2(256, 256));
  tnoise(2, 2, 5, 0.6);
  tderive(1, 10);
  save();
}
