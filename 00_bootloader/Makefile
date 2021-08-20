include ../common/rules.mak

mbr.S: ../common/i8086/bios-io.asm.inc

main.16.elf: mbr.16.o
	ld -Ttext 0x7c00 -o $@ $<

local-clean:
	rm -f mbr.16.o mbr.S main.16.elf
