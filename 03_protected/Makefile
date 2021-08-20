include ../common/rules.mak

%.16.o: %.S
	# --32 is used to make ld happy, real code archtecture is set using .code16
	as --32 -o $@ $<

main.16.elf: main.16.o protected.32.o main.ld
	ld -melf_i386 -static -Tmain.ld -nostdlib --nmagic -o $@ $^

GET_MAIN_CMD:= \
    readelf -s main.16.elf \
  | grep ' main$$' \
  | sed -e 's/.*: \+0*\([^ ]*\).*/\1/'

.PHONY: loader-params
loader-params: main.16.text.bin main.16.rodata.bin main.16.data.bin \
                 main.16.elf
	$(eval TEXT_SIZE:=$(shell stat -c %s main.16.text.bin))
	$(eval RODATA_SIZE:=$(shell stat -c %s main.16.rodata.bin))
	$(eval DATA_SIZE:=$(shell stat -c %s main.16.data.bin))
	$(eval MAIN:=0x$(shell ${GET_MAIN_CMD}))

loader.S: ../01_main/loader.asm
loader.S: ../common/i8086/bios-io.asm.inc
loader.S: loader-params
loader.S: CPPFLAGS+=-DBPB_SIZE=0 \
	-DTEXT_SIZE=${TEXT_SIZE} \
	-DRODATA_SIZE=${RODATA_SIZE} \
	-DDATA_SIZE=${DATA_SIZE} \
	-DMAIN=${MAIN}

loader.16.elf: loader.16.o
	ld -melf_i386 -Ttext 0x7c00 -o $@ $<

main.S: ../common/vga.h ../common/i8086/vga.asm.inc

protected.32.o: ../common/vga.h

# Parts are block aligned.
main.bin: loader.16.text.bin \
          main.16.text.bin main.16.rodata.bin main.16.data.bin
	dd if=loader.16.text.bin of=$@
	dd if=main.16.text.bin bs=512 of=$@ oflag=append conv=notrunc,sync
	dd if=main.16.rodata.bin bs=512 of=$@ oflag=append conv=notrunc,sync
	dd if=main.16.data.bin bs=512 of=$@ oflag=append conv=notrunc,sync

all: loader.disas protected.disas

local-clean:
	rm -f main.16.o main.16.elf main.S \
	      main.16.text.bin main.16.rodata.bin main.16.data.bin \
	      loader.S \
	      loader.16.o loader.16.elf loader.disas \
	      loader.16.text.bin \
	      protected.32.o protected.disas \
