#-------------------------------------------------------------------------------
# Architect makefile
# Author: Sebastien Alaiwan
#-------------------------------------------------------------------------------
include build/common_head.mak

REPO_URL?=http://code.alaiwan.org/bzr

DFLAGS:=-funittest

CXXFLAGS+=-std=c++14
DFLAGS+=-g3 -O3
LDFLAGS+=-g -lstdc++

THIS:=src
include src/project.mk

#------------------------------------------------------------------------------
# Project: lib_ops
#------------------------------------------------------------------------------
include $(BIN)/lib_ops/project.mk
include $(BIN)/extra/lib_ktg/project.mk

#------------------------------------------------------------------------------
# Project: lib_algo
#------------------------------------------------------------------------------
include $(BIN)/extra/lib_algo/project.mk

extra/lib_algo/project.mk:
	bzr checkout --lightweight $(REPO_URL)/lib_algo -r 69 extra/lib_algo

#------------------------------------------------------------------------------
# Project: lib_sdl
#------------------------------------------------------------------------------
THIS:=extra/lib_sdl
include $(THIS)/project.mk

extra/lib_sdl/project.mk:
	bzr checkout lp:dlibsdl -r 9 extra/lib_sdl

# Solution targets
SRCS:=\
  $(architect-gui.srcs)\
  $(extra/lib_algo.srcs)\
  $(lib_ops.srcs)\
  $(extra/lib_ktg.srcs)\

GUI_OBJS:=$(SRCS:%.d=$(BIN)/%_d.o)
GUI_OBJS:=$(GUI_OBJS:%.cpp=$(BIN)/%_cpp.o)
$(BIN)/architect-gui.exe: $(GUI_OBJS)
TARGETS+=$(BIN)/architect-gui.exe

SRCS:=\
  $(architect.srcs)\
  $(extra/lib_algo.srcs)\
  $(lib_ops.srcs)\
  $(extra/lib_ktg.srcs)\

OBJS:=$(SRCS:%.d=$(BIN)/%_d.o)
OBJS:=$(OBJS:%.cpp=$(BIN)/%_cpp.o)
$(BIN)/architect.exe: $(OBJS)
TARGETS+=$(BIN)/architect.exe

#------------------------------------------------------------------------------

DFLAGS+=-Isrc
DFLAGS+=-Ilib_ops

DFLAGS+=-Iextra/lib_ktg
DFLAGS+=-Iextra/lib_sdl
DFLAGS+=-Iextra/lib_algo

THIS:=build
-include $(THIS)/common.mak

