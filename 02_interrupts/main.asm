#include "vga.h"

.section .bss
legacy_idtr:
legacy_idtr_limit:
    .word 0
legacy_idtr_base_lo:
    .word 0
legacy_idtr_base_hi:
    .word 0

.data
vga_text_color:
    .byte 0
vga_text_pos:
    .word 0

/* Interrupt counters */

#define VEC(N, MNEMONIC, PRETTY) vec_##N##_cnt: .word 0
#include "vectors.inc"
#undef VEC

/* Original interrupt handlers */
#define VEC(N, MNEMONIC, PRETTY) \
    vec_##N##_orig_ip: .word 0; \
    vec_##N##_orig_cs: .word 0
orig_vectors:
#include "vectors.inc"
#undef VEC

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

vga_putu:
    orw %ax, %ax
    jnz vga_putu_recursion
    VGA_PUTC $'0'
    jmp vga_putu_out
vga_putu_recursion:
    xor %dx, %dx
    mov $10, %cx

    div %cx /* Quotient: %ax, Remainder: %dx */

    push %dx /* preserve remainder */

    orw %ax, %ax
    jz vga_putu_recursion_end

    call vga_putu_recursion

vga_putu_recursion_end:
    pop %ax /* remainder */

    add $'0', %al
    call vga_putc

vga_putu_out:
    ret

.macro VGA_PUTU U
    mov \U, %ax
    call vga_putu
.endm

.macro VGA_NL
    VGA_PUTS $s_nl
.endm

s_nl:
    .asciz "\r\n"

.globl main
main:
    sidt legacy_idtr

    /* Copy original interrupt handlers */
    mov $orig_vectors, %di
    xor %ax, %ax
    movw %ax, %es

    mov legacy_idtr_base_lo, %si
    movw %ax, %ds

    mov legacy_idtr_limit, %cx
    rep movsb

    /* Intercept interrupts */

.macro INTERCEPT_INT N, INTERCEPTOR
    mov $(\N), %ax
    shl $2, %ax
    push %bp
    mov legacy_idtr_base_lo, %bp
    add %ax, %bp
    movw $(\INTERCEPTOR), (%bp) /* IP */
    movw $0, 2(%bp) /* CS */
    pop %bp
.endm

#define VEC(N, MNEMONIC, PRETTY) INTERCEPT_INT N, int_##N##_interceptor
#include "vectors.inc"
#undef VEC

    xor %ax, %ax
    push %ax

mainloop:
    call vga_reset
    call vga_clear

    VGA_PUTS $s_main

    VGA_PUTS $s_idtr_limit
    VGA_PUTX legacy_idtr_limit
    VGA_PUTS $s_base_lo
    VGA_PUTX legacy_idtr_base_lo
    VGA_PUTS $s_base_hi
    VGA_PUTX legacy_idtr_base_hi
    VGA_NL

    /* Print interrupt information */

.macro PRINT_INT_INFO PRETTY, ORIG_CS, ORIG_IP, CNT, LABEL
\LABEL: /* The label is for debug purposess. */
    VGA_PUTS $(\PRETTY)
    VGA_PUTS $s_handler
    VGA_PUTX \ORIG_CS
    VGA_PUTC $':'
    VGA_PUTX \ORIG_IP
    VGA_PUTS $s_cnt
    VGA_PUTU \CNT
    VGA_NL
.endm

#define VEC(N, MNEMONIC, PRETTY) \
    PRINT_INT_INFO s_vec##N, vec_##N##_orig_cs, \
                   vec_##N##_orig_ip, vec_##N##_cnt, print_##N
#include "vectors.inc"
#undef VEC

    hlt /* Need update counter after next interrupt. */
    jmp mainloop

    ret


/* Interrupt interceptors */

.macro INT_INTERCEPTOR NAME, CNT, ORIG_CS, ORIG_IP
\NAME:
    cli
    incw \CNT
    /* Call original handler (BIOS) */
    ljmp \ORIG_IP
.endm

#define VEC(N, MNEMONIC, PRETTY) \
    INT_INTERCEPTOR int_##N##_interceptor, vec_##N##_cnt, \
                    vec_##N##_orig_cs, vec_##N##_orig_ip
#include "vectors.inc"
#undef VEC


.section .rodata

s_main:
    .asciz "main\r\n"
s_idtr_limit:
    .asciz "IDTR: Limit: "
s_base_lo:
    .asciz ", Base low word: "
s_base_hi:
    .asciz ", Base high word: "
s_cnt:
    .asciz ", Count: "
s_handler:
    .asciz ", Handler: "

#define _(X) X
#define SHARP #
#define __STR(X) #X
#define STR(X) __STR(X)

/* Interrupt vector pretty strings */
#define VEC(N, MNEMONIC, PRETTY) \
    s_vec##N: .asciz STR(PRETTY _(SHARP)(MNEMONIC))
#include "vectors.inc"
#undef VEC
