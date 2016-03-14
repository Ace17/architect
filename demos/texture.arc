root()
{
  picture(Vec2(256, 256));
  texture(Vec2(256, 256));

  tnoise(5, 5, 5, 0.9);
  tstore(1);

  tvoronoi(4.1, 220, 0.05);
  tstore(2);
  
  tload(1);
  
  let ambient = Vec3(0.2, 0.5, 0.3);
  let diffuse = Vec3(0.5, 0.1, 0.1);
  let p = Vec3(1, 0.5, 0.1);
  let d = Vec3(1, 0.5, 0.4);
  tbump(2, 1, p, d, ambient, diffuse);
//  tblur(0.01, 0.01, 5, 0.1);
  trect(0.5, 0.5, 0.2, 0, 0, 0.2, 0.8, 0.8);
  display();
}
