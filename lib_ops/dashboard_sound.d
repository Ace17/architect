import dashboard;

class Sound : Dashboard
{
  this()
  {
    samples.length = SAMPLE_RATE * 10;
    samples[] = 0;
  }

  Block currBlock()
  {
    return blocks[$ - 1];
  }

  Block[] blocks;
  float[] samples;
}

struct Block
{
  float[] samples;
}

enum SAMPLE_RATE = 48000;

