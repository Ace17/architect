#!/usr/bin/env bash
set -euo pipefail
gdc demo/main.d\
  -o demo.exe \
  -Ilib_ktg\
  ktg.d\
  ktg_generators.d\
  ktg_filters.d\
  -std=c++11 \
  ktg/*.cpp
./demo.exe
