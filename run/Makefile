.SUFFIXES: .asm
LIB=diy
CC=gcc -m32 # produce elf32 code in 64-bit machines
CFLAGS=-g -Dunderscore -fno-stack-protector # when __stack_chk_fail in Ubuntu
RUNTIME=lib$(LIB).a # stand-alone runtime
DIY_RUN=../diy_run # diy runtime dir
AS=nasm -felf32 # assembler command

all:: diy_runtime $(RUNTIME)

diy_runtime::
	make -C $(DIY_RUN)

$(RUNTIME): dbl.o linux.o lib.o sys.o rand.o recurs.o string.o
	ar crl $@ $^
.asm.o:
	$(AS) $< -o $@

install:: $(RUNTIME)
	cp $(RUNTIME) ..

clean::
	rm -f $(RUNTIME) *.o a.out core
