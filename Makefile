LANG=diy
INICIAL=diy
EXT=diy # file extension: .$(EXT)
LIB=lib # compiler library directory
UTIL=util # compiler library: lib$(LIB).a
RUN=run # runtime directory
DIY_RUN=diy_run
EXS=exs # examples directory
CC=gcc
CFLAGS=-g -DYYDEBUG


$(LANG): $(INICIAL).y $(LANG).l $(LANG).brg
	make -C $(LIB)
	byacc -dv $(INICIAL).y
	flex -l $(LANG).l
	pburg -T $(LANG).brg
	$(LINK.c) -o $(LANG) $(ARCH) -I$(LIB) lex.yy.c y.tab.c yyselect.c -L$(LIB) -l$(UTIL)
	make -C $(RUN)

examples:: $(LANG)
	make -C $(EXS)

build::
	nasm -felf32 -F dwarf -g out.asm
	ld -melf_i386 out.o run/libdiy.a

clean::
	make -C $(LIB) clean
	make -C $(RUN) clean
	make -C $(DIY_RUN) clean
	make -C $(EXS) clean
	rm -f *.o $(LANG) lex.yy.c y.tab.c y.tab.h y.output yyselect.c *.asm *~
