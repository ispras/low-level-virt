#include "vga.h"

.data
vga_text_color:
    .byte 0
vga_text_pos:
    .word 0


.text
.code16

.macro VGA_SET_FG COLOR
    mov \COLOR, %ax
    call vga_set_foreground
.endm

vga_set_foreground:
    and $0xF, %al
    andb $0xF0, vga_text_color
    orb %al, vga_text_color
    ret

.macro VGA_SET_BG COLOR
    mov \COLOR, %ax
    call vga_set_background
.endm

vga_set_background:
    and $0x7, %al
    shl $4, %al
    andb $0x8F, vga_text_color
    orb %al, vga_text_color
    ret

vga_reset:
    movb $0, vga_text_color
    movw $0, vga_text_pos

    VGA_SET_FG $(VGA_WHITE)
    VGA_SET_BG $(VGA_BLACK)

    ret

vga_putc:
    cmp $'\n', %al
    jne vga_putc_is_cr
    addw $160, vga_text_pos
    ret

vga_putc_is_cr:
    cmp $'\r', %al
    jne vga_putc_normal
    mov vga_text_pos, %ax

    push %cx

    mov $160, %cl
    div %cl /* AL = AX / CL, AH = AX % CL */
    shr $8, %ax
    sub %ax, vga_text_pos

    pop %cx

    ret

vga_putc_normal:

    push %bx

    mov vga_text_color, %ah
    mov vga_text_pos, %bx

    /* preserve previous DS */
    push %ds

    /* VGA text buffer is at 0xB8000. Let DS = 0xB800. */
    push $0xb800
    pop %ds

    movw %ax, (%bx)

    pop %ds

    add $2, %bx
    cmp $(80 * 24 * 2), %bx
    jl vga_putc_ret
    mov $0, %bx

vga_putc_ret:
    mov %bx, vga_text_pos

    pop %bx
    ret

.macro VGA_PUTS STR
    mov \STR, %bx
    call vga_puts
.endm

vga_puts:
    mov (%bx), %al
    inc %bx
    test %al, %al
    jz vga_puts_ret
    call vga_putc
    jmp vga_puts
vga_puts_ret:
    ret

.globl main
main:
    call vga_reset

    VGA_PUTS $s_main

.macro PRINT_COLORED COLOR, STR
    VGA_SET_FG \COLOR
    VGA_PUTS \STR
.endm

.macro PRINT_BG_COLORED COLOR, STR
    VGA_SET_BG \COLOR
    VGA_PUTS \STR
.endm

#define VGA_COLOR(NAME) VGA_##NAME

#define COLOR(NAME) PRINT_COLORED $(VGA_COLOR(NAME)), $(S_##NAME)
#include "colors.inc"

    VGA_SET_FG $(VGA_BLACK)

#define COLOR(NAME) PRINT_BG_COLORED $(VGA_COLOR(NAME)), $(S_##NAME)
#include "colors.inc"

#undef COLOR
#undef VGA_COLOR

    ret


.section .rodata

s_main:
    .asciz "main\r\n"

#define COLOR(NAME) S_##NAME: .ascii #NAME; .asciz " "
#include "colors.inc"
#undef COLOR

