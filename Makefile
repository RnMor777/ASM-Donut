NAME=donut

all: donut

donut: donut.asm
	nasm -f elf64 -F dwarf -g donut.asm
	gcc -g -m64 -o donut donut.o -static
	rm -rf donut.o
