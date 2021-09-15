all:
.PHONY: all

AS=as ${ASFLAGS}

# .asm files are .S files with C preprocessor macroses
%.S: %.asm
	cpp ${CPPFLAGS} $< > $@

# objects from assembly
%.16.o: %.S
	${AS} -o $@ $<

%.32.o: %.S
	${AS} -o $@ $<

# objects from C
%.32.o: %.c
	gcc -m32 -fno-pie -ffreestanding -c -g -O0 -Wall -Werror -o $@ $<

# ELF from objects
%.32.elf: %.32.o
	ld -melf_i386 -static -nostdlib --nmagic -o $@ $^

# data from ELF
%.bin: %.16.elf
	objcopy -O binary $< $@

%.bin: %.32.elf
	objcopy -O binary $< $@

%.text.bin: %.elf
	objcopy -O binary -j .text $< $@

%.rodata.bin: %.elf
	objcopy -O binary -j .rodata $< $@

%.data.bin: %.elf
	objcopy -O binary -j .data $< $@

# disassembly
%.disas: %.16.elf
	objdump -M i8086 -D $< > $@

%.disas: %.32.elf
	objdump -M i386 -D $< > $@

# docs
%.html: %.md
	pandoc -o $@ $<

# testing in Qemu
.PHONY: qemu
qemu: main.bin
	qemu-system-i386 -hda $<

.PHONY: qemu-floppy
qemu-floppy: main.bin
	qemu-system-i386 -fda $<

.PHONY: qemu-gdb
qemu-gdb: main.bin
	qemu-system-i386 -s -S -hda $< &

main.log: main.bin
	qemu-system-i386 -d in_asm,exec,cpu,int -D $@ -hda $<

.PHONY: log
log: main.log

.PHONY: debug
debug: qemu-gdb main.16.elf
	gdb \
	    -ix common/gdbinit.i8086 \
	    --symbols main.16.elf \
	    -ex 'target remote localhost:1234' \

# default cleaning
.PHONY: clean local-clean
clean: local-clean
	rm -f main.bin main.disas readme.html
	rm -f main.log

# default targets
all: main.bin main.disas readme.html
