root()
{
  let bgcolor = Vec3(0, 0.3, 1);
  picture(Vec2(160, 160));
  fill(bgcolor);
  gradient(Vec3(0, 1, 1), Vec3(0.9, 1, 0.8), Vec2(1, 1));
  fillrect(Vec3(1, 1, 0), Vec2(20, 20), Vec2(50, 50));
  fillrect(Vec3(1, 0, 0), Vec2(50, 50), Vec2(50, 50));
  fillrect(Vec3(0, 1, 1), Vec2(80, 80), Vec2(50, 50));
  
  redRect(flatRect, Vec2(10, 118));
  redRect(hollowRect, Vec2(47, 118));
}

redRect(rectType, pos)
{
  rectType(Vec3(1, 0, 0), pos, Vec2(30, 30));
  rectType(Vec3(1, 0.3, 0), pos + Vec2(3, 3), Vec2(24, 24));
}

flatRect(color, pos, size)
{
  fillrect(color, pos, size);
}

hollowRect(color, pos, size)
{
  fillrect(color, pos, size);
  fillrect(color - Vec3(0.1, 0.1, 0.1), pos + size * 0.1, size * 0.8);
}
