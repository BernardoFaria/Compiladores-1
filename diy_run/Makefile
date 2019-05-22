.SUFFIXES: .$(EXT) .asm
COMP=../diy # compiler
EXT=diy # file extension: .$(EXT)
LIB=diy # runtime library: lib$(LIB).a
RUN=../run # runtime directory
AS=nasm -felf32 # assembler command
LD=ld -melf_i386 # loader command

RUNTIME=lib$(LIB).a # stand-alone runtime
SRC=rand.diy recurs.diy string.diy 
EXE=$(SRC:%.diy=%)

all:: compiler $(EXE) cp_run

compiler::
	make -C ..

%:%.$(EXT)
	$(COMP) -trace $<
	$(AS) $*.asm -o $*.o

cp_run::
	cp *.o $(RUN)

clean::
	rm -f *.o *.asm *.s *~ $(EXE)
