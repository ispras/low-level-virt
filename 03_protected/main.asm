#include "../common/vga.h"

/* Helper code */

#include "../common/i8086/vga.asm.inc"
#include "../common/i8086/a20.asm.inc"

#define MASK(BITS) ((1 << (BITS)) - 1)

#define BITFIELD(VALUE, BITSIZE, OFFSET) \
    (((VALUE) & MASK(BITSIZE)) << (OFFSET))

#define CODE_DESCRIPTOR(BASE, LIMIT, R, C, DPL, P, AVL, D, G) \
( \
    BITFIELD(       LIMIT,  16,  0)   \
  | BITFIELD(        BASE,  24, 16)   \
    /* accessed, 1 bit, set by CPU */ \
  | BITFIELD(           R,   1, 41)   \
  | BITFIELD(           C,   1, 42)   \
  | BITFIELD(/* code */ 1,   1, 43)   \
  | BITFIELD(/* user */ 1,   1, 44)   \
  | BITFIELD(         DPL,   2, 45)   \
  | BITFIELD(           P,   1, 47)   \
  | BITFIELD( LIMIT >> 16,   4, 48)   \
  | BITFIELD(         AVL,   1, 52)   \
    /* reserved 1 bit */              \
  | BITFIELD(           D,   1, 54)   \
  | BITFIELD(           G,   1, 55)   \
  | BITFIELD(  BASE >> 24,   8, 56)   \
)

#define DATA_DESCRIPTOR(BASE, LIMIT, W, E, DPL, P, AVL, D, G) \
( \
    BITFIELD(       LIMIT,  16,  0)   \
  | BITFIELD(        BASE,  24, 16)   \
    /* accessed, 1 bit, set by CPU */ \
  | BITFIELD(           W,   1, 41)   \
  | BITFIELD(           E,   1, 42)   \
  | BITFIELD(/* data */ 0,   1, 43)   \
  | BITFIELD(/* user */ 1,   1, 44)   \
  | BITFIELD(         DPL,   2, 45)   \
  | BITFIELD(           P,   1, 47)   \
  | BITFIELD( LIMIT >> 16,   4, 48)   \
  | BITFIELD(         AVL,   1, 52)   \
    /* reserved 1 bit */              \
  | BITFIELD(           D,   1, 54)   \
  | BITFIELD(           G,   1, 55)   \
  | BITFIELD(  BASE >> 24,   8, 56)   \
)

#define SELECTOR(INDEX, LDT, RPL) \
( \
    BITFIELD(  RPL,  2, 0) \
  | BITFIELD(  LDT,  1, 2) \
  | BITFIELD(INDEX, 13, 3) \
)


.data
a20_before:
    .byte 0x00

gdtr:
gdtr_limit:
    .word 0
gdtr_addr:
    .quad 0 /* in legacy protected mode only first 4 bytes are used */

.text
.code16

.globl main
main:
    /* Interrupts are not supported by this example. */
    cli

    VGA_RESET
    VGA_CLEAR

    VGA_PUTS $s_main

    /* On some modern HW (even on Qemu 2.1) A20 is enabled at this moment.
       Try to disable it first. */
    VGA_PUTS $s_dis_A20
    VGA_NL

    call disable_a20_port92

    /* Get status of A20 */
    VGA_PUTS $s_A20

    call check_a20

    mov %al, a20_before

    test %al, %al
    jz a20_is_disabled
    VGA_PUTS $s_enabled
    jmp a20_end
a20_is_disabled:
    VGA_PUTS $s_disabled
    a20_end:
    VGA_NL

    mov a20_before, %al
    test %al, %al
    jnz enable_segmentation

    VGA_PUTS $s_en_A20
    call enable_a20_port92
    call check_a20

    test %al, %al
    jnz a20_is_enabled

    VGA_PUTS $s_cant_A20
    ret

a20_is_enabled:
    VGA_PUTS $s_ok

enable_segmentation:

    VGA_NL

    /* fill GDTR in memory */

    /* 1. addres of GDT*/
    mov %ds, %ax
    shl $4, %ax
    mov %ds, %bx
    shr $12, %bx
    add $gdt, %ax
    adc $0, %bx /* possible carry */
    mov %ax, gdtr_addr
    mov %bx, (gdtr_addr + 2)

    xor %ax, %ax
    mov %ax, (gdtr_addr + 4)
    mov %ax, (gdtr_addr + 6)

    VGA_PUTS $s_gdt
    VGA_PUTX (gdtr_addr + 2)
    VGA_PUTX gdtr_addr

    /* 2. limit of GDT */
    mov $gdt_end, %ax
    sub $gdt, %ax
    dec %ax
    mov %ax, gdtr_limit

    VGA_PUTC $' '
    VGA_PUTX gdtr_limit

    VGA_NL

    /* load GDTR from memory */
    lgdt gdtr

    VGA_PUTS $s_entering_protected_mode
    VGA_NL

    /* set CR0.PE flag */
    movl %cr0, %eax
    orb $0x01, %al
    movl %eax, %cr0

    jmp $ SELECTOR(1, 0, 0), $entering_protected

entering_protected:
.code32

    /* default data segment (DS) */
    movw $ SELECTOR(2, 0, 0), %ax
    movw %ax, %ds

    /* other data segments */
    movw %ax, %es
    movw %ax, %fs
    movw %ax, %gs

    /* stack segment (SS) */
    movw %ax, %ss
    /* stack is at 2-nd MiB */
    mov $0x00200000, %esp

    /* give control to payload */
    call protected

    /* real mode must be re-entered to `ret`urn to the caller (loader) */
no_return:
    jmp no_return


.section .rodata

s_main:
    .asciz "main\r\n"
s_entering_protected_mode:
    .asciz "Entering protected mode..."
s_dis_A20:
    .asciz "Disabling A20..."
s_A20:
    .asciz "A20 line is "
s_enabled:
    .asciz "enabled"
s_disabled:
    .asciz "disabled"
s_en_A20:
    .asciz "Enabling A20... "
s_cant_A20:
    .asciz "FAILED, exiting"
s_ok:
    .asciz "OK"
s_gdt:
    .asciz "GDT: "


gdt:
    .quad 0 /* null descriptor */
    .quad CODE_DESCRIPTOR(0, 0xFFFFF, 1, 1, 0, 1, 0, 1, 1)
    .quad DATA_DESCRIPTOR(0, 0xFFFFF, 1, 0, 0, 1, 0, 1, 1)
gdt_end:
