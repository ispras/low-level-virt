include ../common/rules.mak

main.16.elf: mbr.16.o
	ld -Ttext 0x7c00 -o $@ $<

local-clean:
	rm -f mbr.16.o main.16.elf
