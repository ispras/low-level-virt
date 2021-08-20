#include "../common/vga.h"

/* Helper code */

#include "../common/i8086/vga.asm.inc"

.globl protected /* protected.c */

.text
.code16

.globl main
main:
    VGA_RESET
    VGA_CLEAR

    VGA_PUTS $s_main

    VGA_PUTS $s_calling_protected_at
    VGA_PUTX $protected
    VGA_NL

    call protected

    ret


.section .rodata

s_main:
    .asciz "main\r\n"
s_calling_protected_at:
    .asciz "Calling `protected` at 0x"
