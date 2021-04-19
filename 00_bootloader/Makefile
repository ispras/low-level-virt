all:
.PHONE: all

%.S: %.asm
	cpp $< > $@

%.o: %.S
	as -o $@ $<

%.bin: %.elf
	objcopy -O binary $< $@

%.disas: %.elf
	objdump -M i8086 -D $< > $@

%.html: %.md
	pandoc -o $@ $<

all: mbr.disas mbr.bin readme.html

mbr.elf: mbr.o
	ld -Ttext 0x7c00 -o $@ $<

clean:
	rm -f mbr.o mbr.elf mbr.disas mbr.bin readme.html

.PHONY: qemu
qemu: mbr.bin
	qemu-system-i386 -hda $<

.PHONY: qemu-floppy
qemu-floppy: mbr.bin
	qemu-system-i386 -fda $<
