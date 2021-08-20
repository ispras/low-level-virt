#include "../common/vga.h"

/* Helper code */

#include "../common/i8086/vga.asm.inc"

/* Interrupt Descriptor Table Register (IDTR) in memory */

.section .bss
legacy_idtr:
legacy_idtr_limit:
    .word 0
legacy_idtr_base_lo:
    .word 0
legacy_idtr_base_hi:
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
    VGA_RESET
    VGA_CLEAR

    VGA_PUTS $s_main

    VGA_PUTS $s_idtr_limit
    VGA_PUTX legacy_idtr_limit
    VGA_PUTS $s_base_lo
    VGA_PUTX legacy_idtr_base_lo
    VGA_PUTS $s_base_hi
    VGA_PUTX legacy_idtr_base_hi
    VGA_NL

    /* Print interrupt information */

.macro PRINT_INT_INFO N, PRETTY, ORIG_CS, ORIG_IP, CNT, LABEL
\LABEL: /* The label is for debug purposess. */
    VGA_PUTU $(\N)
    VGA_PUTC $' '
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
    PRINT_INT_INFO N, s_vec##N, vec_##N##_orig_cs, \
                   vec_##N##_orig_ip, vec_##N##_cnt, print_##N
#include "vectors.inc"
#undef VEC

    hlt /* Need update counter after next interrupt. */
    jmp mainloop

    ret


/* Interrupt interceptors */

.macro INT_INTERCEPTOR NAME, CNT, ORIG_CS, ORIG_IP
\NAME:
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
