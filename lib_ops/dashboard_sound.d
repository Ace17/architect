import dashboard;

class Sound : Dashboard
{
  this()
  {
    samples.length = SAMPLE_RATE * 10;
    samples[] = 0;
  }

  float[] samples;
}

enum SAMPLE_RATE = 48000;

