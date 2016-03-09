import std.random;
import std.math;
import std.algorithm;
import ktg;

const WHITE_MASK = Color(0xff, 0xff, 0xff, 0xff);
const BLACK_MASK = Color(0, 0, 0, 0);

extern(C++):
void Voronoi(Texture* dest, float intensity, int maxCount, float minDist)
{
  Random gen;

  maxCount = min(256, maxCount);
  CellCenter centers[256];

  auto grad = Texture(2, 1);
  grad.Data[0] = WHITE_MASK;
  grad.Data[1] = BLACK_MASK;

  // generate random center points
  for(int i = 0; i < maxCount; i++)
  {
    int intens = uniform(0, cast(int)(intensity * 256), gen);

    centers[i].x = uniform(0.0f, 1.0f, gen);
    centers[i].y = uniform(0.0f, 1.0f, gen);
    centers[i].color = Color(intens, intens, intens, 255);
  }

  // remove points too close together
  const minDistSq = minDist * minDist;

  for(int i = 1; i < maxCount;)
  {
    const x = centers[i].x;
    const y = centers[i].y;

    // try to find a point closer than minDist
    int j;

    for(j = 0; j < i; j++)
    {
      const dx = abs(centers[j].x - x);
      const dy = abs(centers[j].y - y);

      if(dx * dx + dy * dy < minDistSq) // point is too close, stop
        break;
    }

    if(j < i) // we found such a point
      centers[i] = centers[--maxCount]; // remove this one
    else // accept this one
      i++;
  }

  // generate the image
  dest.Cells(grad, centers.ptr, maxCount, 0.0f, CellMode.Inner);
}

