root()
{
  picture(Vec2(128, 128));
  
  let blue = Vec3(0.4, 0.8, 1);
  gradient(blue * 0.5, blue, Vec2(1, 1));

  brickWall(Vec2(4, 4));
}

brickWall(pos)
{
  repeat4(pos, Vec2(8, 8), Vec2(0, 20), brickRow);
}

brickRow()
{
  repeat8(Vec2(0, 0), Vec2(10, 10), Vec2(10, 0), brick);
  repeat8(Vec2(5, 10), Vec2(10, 10), Vec2(10, 0), brick);
}

brick()
{
  let brickColor = Vec3(1, 0.3, 0.3);
  let brickColor2 = Vec3(0.4, 0.1, 0.2);
  gradient(brickColor, brickColor2, Vec2(1, 1));
}

subArea(pos, size, operateOnArea)
{
  select(pos, size);
  operateOnArea();
  deselect();
}

repeat8(pos, size, step, f)
{
  repeat4(pos+step*0, size, step, f);
  repeat4(pos+step*4, size, step, f);
}

repeat4(pos, size, step, f)
{
  let sub = size;
  subArea(pos+step*0, sub, f);
  subArea(pos+step*1, sub, f);
  subArea(pos+step*2, sub, f);
  subArea(pos+step*3, sub, f);
}

