ifeq ($(THIS),)
  $(error THIS is not defined)
endif

DFLAGS+=-J$(THIS)

DFLAGS+=$(shell pkg-config gtkd-3 --cflags)
LDFLAGS+=$(shell pkg-config gtkdsv-3 gtkd-3 glu --static --libs)

architect-gui.srcs:=\
  $(THIS)/cmdline.d\
  $(THIS)/glshader.d\
  $(THIS)/gtkmain.d\
  $(THIS)/gtkscope.d\
  $(THIS)/i_renderer.d\
  $(THIS)/renderer.d\

architect.srcs:=\
  $(THIS)/exe_architect.d\
  $(THIS)/bmp_writer.d\

