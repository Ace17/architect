import dashboard;

interface IRenderer
{
  void createBuffers();
  bool update(Dashboard b);
  void render(int programId);
}

IRenderer[] g_renderers;

