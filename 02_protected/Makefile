all:

%.S: %.asm
	cpp ${CPPFLAGS} $< > $@

%.16.o: %.S
	# --32 is used to make ld happy, real code archtecture is set using .code16
	as --32 -o $@ $<

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

%.disas: %.16.elf
	objdump -M i8086 -D $< > $@

%.disas: %.32.elf
	objdump -M i386 -D $< > $@

%.disas: %.elf
	objdump -D $< > $@

main.elf: main.16.o protected.32.o main.ld
	ld -melf_i386 -static -Tmain.ld -nostdlib --nmagic -o $@ $^

GET_MAIN_CMD:= \
    readelf -s main.elf \
  | grep ' main$$' \
  | sed -e 's/.*: \+0*\([^ ]*\).*/\1/'

loader-params.h: main.text.bin main.rodata.bin main.data.bin \
                 main.elf
	echo "/* Auto generated. Don't modify. */" > loader-params.h
	echo "#define TEXT_SIZE $(shell stat -c %s main.text.bin)" \
	    >> loader-params.h
	echo "#define RODATA_SIZE $(shell stat -c %s main.rodata.bin)" \
	    >> loader-params.h
	echo "#define DATA_SIZE $(shell stat -c %s main.data.bin)" \
	    >> loader-params.h
	echo "#define MAIN 0x$(shell ${GET_MAIN_CMD})" \
	    >> loader-params.h

loader.S: loader-params.h
loader.S: CPPFLAGS+=-DBPB_SIZE=0

loader.16.elf: loader.16.o
	ld -melf_i386 -Ttext 0x7c00 -o $@ $<

main.S: vga.h

# Parts are block aligned.
img.bin: loader.16.text.bin \
         main.text.bin main.rodata.bin main.data.bin
	dd if=loader.16.text.bin of=$@
	dd if=main.text.bin bs=512 of=$@ oflag=append conv=notrunc,sync
	dd if=main.rodata.bin bs=512 of=$@ oflag=append conv=notrunc,sync
	dd if=main.data.bin bs=512 of=$@ oflag=append conv=notrunc,sync

all: img.bin main.disas loader.disas
all: readme.html

.PHONY: clean
clean:
	rm -f main.16.o main.elf main.disas main.S \
	      main.text.bin main.rodata.bin main.data.bin \
	      loader-params.h loader.S \
	      loader.16.o loader.16.elf loader.disas \
	      loader.16.text.bin \
	      protected.32.o protected.disas \
	      img.bin \
	      readme.html \
	      qemu.log \

.PHONY: qemu
qemu: img.bin
	qemu-system-i386 -hda $<

.PHONY: qemu-gdb
qemu-gdb: img.bin
	qemu-system-i386 -s -S -hda $< &

.PHONY: debug
debug: qemu-gdb
	gdb \
	    -ix gdbtarget \
	    --symbols main.16.elf \
	    -ex 'target remote localhost:1234' \

qemu.log: img.bin
	qemu-system-i386 -d in_asm,exec,cpu,int -D qemu.log -hda $<
