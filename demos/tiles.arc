
root()
{
  building(); // create dashboard

  rect(Vec2(1, 13), Vec2(26, 13), 1);

  two_rooms(Vec2(6, 2), 4);
  two_rooms(Vec2(2, 12), 8);

  let row = 18;

  cube_room(Vec2(2, row));
  cube_room(Vec2(10, row));
  cube_room(Vec2(18, row));

  rect(Vec2(21, 8), Vec2(2, 6), 2);

  hallway(Vec2(20, 27));
  hallway(Vec2(35, 31));

  stairs(Vec2(29, 27), 1);
  stairs(Vec2(17, 27), -1);
  hallway(Vec2(5, 31));
  cube_room(Vec2(44, 28));

  metroid_room(Vec2(5, 41), Vec2(10, 8));
  metroid_room(Vec2(17, 41), Vec2(10, 8));
}

two_rooms(pos, w)
{
  hall(pos+Vec2(1, 1));
  hall(pos+Vec2(9+w, 1));
  rect(pos+Vec2(6, 3), Vec2(4+w, 2), 2);
}

hall(pos)
{
  rect(pos, Vec2(6, 6), 1);
  rect(pos + Vec2(1, 1), Vec2(4, 4), 2);
}

cube_room(pos)
{
  let TILE = 2;
  let hsize = Vec2(2, 1);
  let vsize = Vec2(1, 2);

  rect(pos + Vec2(3, 0), hsize, TILE);
  rect(pos + Vec2(3, 7), hsize, TILE);
  rect(pos + Vec2(7, 3), vsize, TILE);
  rect(pos + Vec2(0, 3), vsize, TILE);
  rect(pos + Vec2(1, 1), Vec2(6, 6), TILE);
  
  rect(pos + Vec2(3,4), Vec2(2,1), 0);
}

metroid_room(pos, size)
{
  rect(pos, size, 2);
  rect(pos+Vec2(0, 5), Vec2(1, 3), 1);
  rect(pos+Vec2(0, 0), Vec2(1, 3), 1);
  rect(pos+Vec2(9, 0), Vec2(1, 3), 1);
  rect(pos+Vec2(9, 5), Vec2(1, 3), 1);
  rect(pos, Vec2(10, 1), 1);
  rect(pos+Vec2(0, 7), Vec2(10, 1), 1);
}

hallway(pos)
{
  rect(pos-Vec2(1, 0), Vec2(10, 2), 2);
  rect(pos-Vec2(0, 1), Vec2(8, 4), 2);
  rect(pos + Vec2(3, -1), Vec2(2,1), 4);
}

stairs(pos, dy)
{
  repeat4(pos, Vec2(dy,1), my_rect);
}

my_rect(pos, size)
{
  rect(pos, Vec2(2, 3), 2);
}

repeat4(pos, step, op)
{
  op(pos+step*0, step);
  op(pos+step*1, step);
  op(pos+step*2, step);
  op(pos+step*3, step);
}

