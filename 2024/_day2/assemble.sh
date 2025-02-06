nasm -f elf64 -F dwarf -g code.asm -o code.o
ld code.o -o code.elf
rm code.o