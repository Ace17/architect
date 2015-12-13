#-------------------------------------------------------------------------------
# Architect makefile
# Author: Sebastien Alaiwan
#-------------------------------------------------------------------------------
include build/common_head.mak

REPO_URL?=http://code.alaiwan.org/bzr

DFLAGS:=-funittest

DFLAGS+=-g3
LDFLAGS+=-g

THIS:=src
include src/project.mk

#------------------------------------------------------------------------------
# Project: lib_ops
#------------------------------------------------------------------------------
include $(BIN)/lib_ops/project.mk

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

GUI_OBJS:=$(SRCS:%.d=$(BIN)/%_d.o)
$(BIN)/architect-gui.exe: $(GUI_OBJS)
TARGETS+=$(BIN)/architect-gui.exe

SRCS:=\
  $(architect.srcs)\
  $(extra/lib_algo.srcs)\
  $(lib_ops.srcs)\

OBJS:=$(SRCS:%.d=$(BIN)/%_d.o)
$(BIN)/architect.exe: $(OBJS)
TARGETS+=$(BIN)/architect.exe

#------------------------------------------------------------------------------

DFLAGS+=-Isrc
DFLAGS+=-Ilib_ops

DFLAGS+=-Iextra/lib_sdl
DFLAGS+=-Iextra/lib_algo

THIS:=build
-include $(THIS)/common.mak

