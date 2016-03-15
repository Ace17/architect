root()
{
  picture(Vec2(256, 256));
  texture(Vec2(256, 256));
  tstore(0);

  flatPanels();
  tstore(2);
  
  tnoise(2, 2, 6, 0.8);
  tstore(1);

  tbump(1, 2,
      Vec3(0, 0, 0), // p
      Vec3(-2, 0.8, -3.7), // d
      Vec3(0.1, 0.1, 0.1), // ambient
      Vec3(1, 1, 1)); // diffuse

  tmix(3, 0.06);
  //tload(2);
  display();
}

flatPanels()
{
  tload(0);
  repeat(rectRow, 0);
  trect(0.49, 0.49, 0.33, 0, 0, 0.33, 1, 1);
  tstore(3);
  tderive(1, 0.4);
  tmul(2);
}

rectRow(row, arg)
{
  repeat(myRect, row);
}

myRect(i, j)
{
  trect(
    0.07 + i * 0.12,
    0.07 + j * 0.12,
    0.05, 0, 0, 0.05, 1, 1);
}

repeat(f, arg)
{
  f(0, arg);
  f(1, arg);
  f(2, arg);
  f(3, arg);
  f(4, arg);
  f(5, arg);
  f(6, arg);
  f(7, arg);
}