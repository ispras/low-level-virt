#include "vga.h"

.globl protected /* protected.c */

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

.macro VGA_PUTC C
    mov \C, %al
    call vga_putc
.endm

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

vga_clear:
    mov vga_text_color, %ah
    mov $' ', %al
    mov $(24 * 80), %cx
    push $0xb800
    pop %es
    xor %di, %di
    rep stosw
    ret

vga_putx:
    orw %ax, %ax
    jnz vga_putx_recursion
    VGA_PUTC $'0'
    jmp vga_putx_out
vga_putx_recursion:
    push %ax
    shr $4, %ax
    orw %ax, %ax
    jz vga_putx_recursion_end
    call vga_putx_recursion
vga_putx_recursion_end:
    pop %ax
    andb $0xF, %al
    cmp $9, %al
    jg vga_putx_high
    add $'0', %al
    call vga_putc
    jmp vga_putx_out
vga_putx_high:
    add $('A' - 10), %al
    call vga_putc
vga_putx_out:
    ret

.macro VGA_PUTX X
    mov \X, %ax
    call vga_putx
.endm

.macro VGA_NL
    VGA_PUTS $s_nl
.endm

.globl main
main:
    call vga_reset
    call vga_clear

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
s_nl:
    .asciz "\r\n"
