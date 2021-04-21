all:

%.S: %.asm
	cpp ${CPPFLAGS} $< > $@

%.16.o: %.S
	as -o $@ $<

%.32.o: %.S
	as -o $@ $<

%.html: %.md
	pandoc -o $@ $<

%.32.o: %.c
	gcc -m32 -fno-pie -ffreestanding -c -g -O0 -Wall -Werror -o $@ $<

%.text.bin: %.elf
	objcopy -O binary -j .text $< $@

%.rodata.bin: %.elf
	objcopy -O binary -j .rodata $< $@

%.data.bin: %.elf
	objcopy -O binary -j .data $< $@

%.disas: %.32.elf
	objdump -M i386 -D $< > $@

%.disas: %.16.elf
	objdump -M i8086 -D $< > $@

main.32.elf: main.32.o main.ld
	ld -melf_i386 -static -Tmain.ld -nostdlib --nmagic -o $@ $<

GET_MAIN_CMD:= \
    readelf -s main.32.elf \
  | grep 'FUNC .*main' \
  | sed -e 's/.*: \+0*\([^ ]*\).*/\1/'

loader-params.h: main.32.text.bin main.32.rodata.bin main.32.data.bin \
                 main.32.elf
	echo "/* Auto generated. Don't modify. */" > loader-params.h
	echo "#define TEXT_SIZE $(shell stat -c %s main.32.text.bin)" \
	    >> loader-params.h
	echo "#define RODATA_SIZE $(shell stat -c %s main.32.rodata.bin)" \
	    >> loader-params.h
	echo "#define DATA_SIZE $(shell stat -c %s main.32.data.bin)" \
	    >> loader-params.h
	echo "#define MAIN 0x$(shell ${GET_MAIN_CMD})" \
	    >> loader-params.h

loader.S: loader-params.h
loader.S: CPPFLAGS+=-DBPB_SIZE=0

loader.16.elf: loader.16.o
	ld -Ttext 0x7c00 -o $@ $<

# Parts are block aligned.
img.bin: loader.16.text.bin \
         main.32.text.bin main.32.rodata.bin main.32.data.bin
	dd if=loader.16.text.bin of=$@
	dd if=main.32.text.bin cbs=512 of=$@ oflag=append conv=notrunc,block
	dd if=main.32.rodata.bin cbs=512 of=$@ oflag=append conv=notrunc,block
	dd if=main.32.data.bin cbs=512 of=$@ oflag=append conv=notrunc,block

all: img.bin main.disas loader.disas
all: readme.html

.PHONY: clean
clean:
	rm -f main.32.o main.32.elf main.disas \
	      main.32.text.bin main.32.rodata.bin main.32.data.bin \
	      loader-params.h loader.S \
	      loader.16.o loader.16.elf loader.disas \
	      loader.16.text.bin \
	      img.bin \
	      readme.html

.PHONY: qemu
qemu: img.bin
	qemu-system-i386 -hda $<

.PHONY: qemu-gdb
qemu-gdb: img.bin
	qemu-system-i386 -s -S -hda $<
