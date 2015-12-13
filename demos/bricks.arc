root()
{
  picture(Vec2(384, 384));
  
  let blue = Vec3(0.4, 0.8, 1);
  gradient(blue * 0.5, blue, Vec2(1, 1));

  brickWall(Vec2(12, 12));
}

brickWall(pos)
{
  repeat4(pos, Vec2(32, 24), Vec2(0, 48), brickRows);
}

brickRows()
{
  brickRow(Vec2(0, 0));
  brickRow(Vec2(16, 24));
}

brickRow(pos)
{
  repeat8(pos, Vec2(32, 24), Vec2(32, 0), brick);
}

brick()
{
  let brickColor1 = Vec3(1, 0.3, 0.3);
  let brickColor2 = Vec3(0.4, 0.1, 0.2);
  gradient(brickColor1, brickColor2, Vec2(1, 1));
  emptyrect(Vec3(0.5, 0.5, 0.5));
}

repeat8(pos, size, step, f)
{
  repeat4(pos, size, step, f);
  repeat4(pos+step*4, size, step, f);
}

repeat4(pos, size, step, f)
{
  repeat2(pos, size, step, f);
  repeat2(pos+step*2, size, step, f);
}

repeat2(pos, size, step, f)
{
  subArea(pos, size, f);
  subArea(pos+step, size, f);
}

subArea(pos, size, operateOnArea)
{
  select(pos, size);
  operateOnArea();
  deselect();
}

