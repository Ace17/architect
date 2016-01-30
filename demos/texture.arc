root()
{
  picture(Vec2(256, 256));
  texture(Vec2(256, 256));
  tvoronoi(4.3, 181, 0.05);
  tstore(1);
  tnoise(3,3,5,0.6);
  tmix(1, 0.3);
  tstore(2);
  tderive(1, 6);
  tmix(2, 0.4);
  display();
}
