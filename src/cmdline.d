import std.string;
import std.stdio;
import options;

Config parseCmdLine(string[] args)
{
  Config cfg;

  auto optionParser = new CmdLineOptions;
  optionParser.addOption("h", "help", &cfg.bHelp, "shows this screen");
  optionParser.addOption("c", "chunks", &cfg.numChunks,
                         "sets the number of chunks per audio buffer. A higher number will increase latency.");

  optionParser.parse(args);

  auto files = optionParser.getFiles();

  if(files.length > 1)
    throw new Exception(format("Only one input file can be specified, got %s", files));

  if(files.length > 0)
    cfg.sFilename = files[0];

  if(cfg.bHelp)
  {
    writefln("Usage: %s [options] <file.arc>", args[0]);
    optionParser.showUsage();
  }

  return cfg;
}

struct Config
{
  bool bHelp;
  string sFilename;
  int numChunks = 1;
}

