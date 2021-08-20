#include "../common/vga.h"

/* Helper code */

#include "../common/i8086/vga.asm.inc"

/* Main code */
.text
.code16

.globl main
main:
    VGA_RESET

    VGA_PUTS $s_main

#define VGA_COLOR(NAME) VGA_##NAME

#define COLOR(NAME) VGA_PUTS_COLORED $(VGA_COLOR(NAME)), $(S_##NAME)
#include "colors.inc"

    VGA_SET_FG $(VGA_BLACK)

#define COLOR(NAME) VGA_PUTS_BG_COLORED $(VGA_COLOR(NAME)), $(S_##NAME)
#include "colors.inc"

#undef COLOR
#undef VGA_COLOR

    ret


/* Main data */
.section .rodata

s_main:
    .asciz "main\r\n"

#define COLOR(NAME) S_##NAME: .ascii #NAME; .asciz " "
#include "colors.inc"
#undef COLOR

