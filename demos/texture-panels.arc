root()
{
  picture(Vec2(256, 256));
  texture(Vec2(256, 256));
  tstore(0);

  tnoise(5, 6, 5, 3);
  tmul(0.1);
  tstore(1);


  tload(0);
  repeat(rectRow, 0);
  tderive(1, 0.8);
 // tmul(10);
//  tstore(2);
  
//  tload(1);
//  tbump(2,
//    Vec3(1.5, 1.5, 0.1), // p
//    Vec3(1, 1, 1), // d
//    Vec3(0.4, 0.4, 0.4), // ambient
//    Vec3(0.4, 0.4, 0.4)); // diffuse
    
//  tload(1);
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