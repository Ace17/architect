root()
{
  picture(Vec2(256, 256));
  texture(Vec2(256, 256));
  tvoronoi(4.3, 181, 0.05);
  tstore(1);
  tnoise(3,3,5,0.6);
  tload(1);
//  tderive(1, 6);
  display();
}
