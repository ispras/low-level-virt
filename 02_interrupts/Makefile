include ../common/rules.mak

main.16.elf: main.16.o
	ld -Tmain.ld -o $@ $<

GET_MAIN_CMD:= \
    readelf -s main.16.elf \
  | grep ' main$$' \
  | sed -e 's/.*: \+0*\([^ ]*\).*/\1/'

loader-params.h: main.16.text.bin main.16.rodata.bin main.16.data.bin \
                 main.16.elf
	echo "/* Auto generated. Don't modify. */" > loader-params.h
	echo "#define TEXT_SIZE $(shell stat -c %s main.16.text.bin)" \
	    >> loader-params.h
	echo "#define RODATA_SIZE $(shell stat -c %s main.16.rodata.bin)" \
	    >> loader-params.h
	echo "#define DATA_SIZE $(shell stat -c %s main.16.data.bin)" \
	    >> loader-params.h
	echo "#define MAIN 0x$(shell ${GET_MAIN_CMD})" \
	    >> loader-params.h

loader.S: loader-params.h
loader.S: CPPFLAGS+=-DBPB_SIZE=0

loader.16.elf: loader.16.o
	ld -Ttext 0x7c00 -o $@ $<

main.S: vga.h vectors.inc

# Parts are block aligned.
main.bin: loader.16.text.bin \
          main.16.text.bin main.16.rodata.bin main.16.data.bin
	dd if=loader.16.text.bin of=$@
	dd if=main.16.text.bin bs=512 of=$@ oflag=append conv=notrunc,sync
	dd if=main.16.rodata.bin bs=512 of=$@ oflag=append conv=notrunc,sync
	dd if=main.16.data.bin bs=512 of=$@ oflag=append conv=notrunc,sync

all: loader.disas

local-clean:
	rm -f main.16.o main.16.elf main.S \
	      main.16.text.bin main.16.rodata.bin main.16.data.bin \
	      loader-params.h loader.S \
	      loader.16.o loader.16.elf loader.disas \
	      loader.16.text.bin \
