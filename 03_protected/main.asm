#include "../common/vga.h"

/* Helper code */

#include "../common/i8086/vga.asm.inc"
#include "../common/i8086/a20.asm.inc"

.globl protected /* protected.c */

.data
a20_before:
    .byte 0x00

.text
.code16

.globl main
main:
    /* Interrupts are not supported by this example. */
    cli

    VGA_RESET
    VGA_CLEAR

    VGA_PUTS $s_main

    /* On modern HW (even on Qemu 2.1) A20 is enabled at this moment.
       Try to disable it first. */
    VGA_PUTS $s_dis_A20
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
s_dis_A20:
    .asciz "Disabling A20...\r\n"
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
