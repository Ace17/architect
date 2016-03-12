root()
{
  picture(Vec2(256, 256));
  texture(Vec2(256, 256));
  tstore(0);

  tnoise(5, 6, 5, 3);
  tblur(0.01, 0.01, 0.7, 0);
  tstore(1);


  tload(0);
  repeat(rectRow, 0);
  trotozoom(0.03, 2);
  tderive(1, 0.8);
  tmul(2);
  tstore(2);
  
  tbump(1, 2,
    Vec3(0, 0, 0), // p
    Vec3(-2, 0.8, -3.6), // d
    Vec3(0.1, 0.1, 0.1), // ambient
    Vec3(1, 1, 1)); // diffuse
    
  display();
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