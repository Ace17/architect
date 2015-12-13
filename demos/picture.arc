root()
{
  let bgcolor = Vec3(0, 0.3, 1);
  picture(Vec2(160, 160));
  fill(bgcolor);
  fillrect(Vec3(1, 1, 0), Vec2(20, 20), Vec2(50, 50));
  fillrect(Vec3(1, 0, 0), Vec2(50, 50), Vec2(50, 50));
  fillrect(Vec3(0, 1, 1), Vec2(80, 80), Vec2(50, 50));
}

