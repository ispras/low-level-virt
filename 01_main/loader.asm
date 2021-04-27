/* Externally definable parameters */

#include "loader-params.h"

#ifndef BPB_START
#define BPB_START 0x0B
#endif /* BPB_START */

#ifndef BPB_SIZE
#define BPB_SIZE 79
#endif /* BPB_SIZE */

#ifndef STACK_TOP
/* Like GRUB. */
#define STACK_TOP 0x2000
#endif /* STACK_TOP */

#ifndef DATA_START
#define DATA_START STACK_TOP
#endif /* DATA_START */

/* Derived parameters and constants */

#define DATA(OFFSET) (DATA_START + OFFSET)

#define BPB_END (BPB_START + BPB_SIZE)

#define PARTITION_TABLE_OFFSET 0x1BE
#define BOOT_SIGNATURE_OFFSET 0x1FE

#define NOP 0x90

/* Runtime data */

#define BOOT_DRIVE      DATA(0)

/* Cache for int 13h */
#define CURRENT_SECTOR  DATA(2)
#define DST_ADDR        DATA(4)

#define CACHE           DATA(512)

/* Helper macros */

.macro PUTS STR
    leaw \STR, %si
    call puts
.endm

.macro PUTX HEX
    mov \HEX, %ax
    call putx
.endm

.macro PUTC CHAR
    mov \CHAR, %al
    call putc
.endm

.macro PUTNL
    PUTS s_nl
.endm

/* Start of MBR */

.text
.code16
.globl _start

entry:
    jmp _start

    .org BPB_START, NOP

/* BIOS parameter block */

    .org BPB_END, 0

/* Data constants */

s_bootloader:
    .asciz "Bootloader\r\n"
s_boot_drive:
    .asciz "Boot drive:"
s_nl:
    .asciz "\r\n"
s_read_error:
    .asciz "Read error"
s_load_text:
    .asciz "Load .text "
s_load_rodata:
    .asciz "Load .rodata "
s_load_data:
    .asciz "Load .data "
s_start_main:
    .asciz "Starting main at 0x"

/* Bootloader code */

_start:
    /* Not ready to be interrupted now. */
    cli

    /* Like GRUB, ensure CS = 0x0000. */
    ljmp $0, $real_start

real_start:
    /* Setup real mode stack */
    xorw %ax, %ax
    movw %ax, %ss
    movw $(STACK_TOP), %sp

    movw %ax, %ds

    /* Save boot drive reference (%dl) */
    mov %dx, DATA_START

    /* Now, can be interrupted. */
    sti

    /* Identify itself */
    PUTS s_bootloader

    /* Print boot drive number */
    PUTS s_boot_drive
    PUTC $' '
    PUTX BOOT_DRIVE
    PUTNL

    /* Init media reading */
    movw $1, CURRENT_SECTOR

    /* Load .text of main */
    PUTS(s_load_text)

    movw $(TEXT_SIZE), %ax

    push %ax
    call putx
    PUTNL
    pop %ax

    movw $0x8000, DST_ADDR /* see main.ld */

    call read_serctors

    /* Load .rodata of main */
    PUTS(s_load_rodata)

    movw $(RODATA_SIZE), %ax

    push %ax
    call putx
    PUTNL
    pop %ax

    movw $0x5000, DST_ADDR

    call read_serctors

    /* Load .data of main */
    PUTS(s_load_data)

    movw $(DATA_SIZE), %ax

    push %ax
    call putx
    PUTNL
    pop %ax

    movw $0x6000, DST_ADDR

    call read_serctors

    /* starting main */
    PUTS(s_start_main)

    movw $(MAIN), %ax

    push %ax
    call putx
    PUTNL
    pop %ax

    call MAIN

loop:
    jmp loop

/* Helper functions */
read_serctors:
    test %ax, %ax
    jz read_serctors_end

    push %ax
    call read

    /* dst: es:di */
    movw DST_ADDR, %di
    xor %ax, %ax
    movw %ax, %es

    /* src: ds:si */
    movw $(CACHE), %si
    movw %ax, %ds

    movw $(512 / 4), %cx
    rep movsd

    movw %di, DST_ADDR

    pop %ax
    sub $512, %ax
    jg read_serctors

read_serctors_end:
    ret

read:
    xorw %ax, %ax
    movw %ax, %es
    movb BOOT_DRIVE, %dl
    movb $0, %dh /* head */
    movb $0, %ch /* cylinder */
    movb CURRENT_SECTOR, %cl /* sector */
    inc %cl
    movb %cl, CURRENT_SECTOR
    movb $2, %ah /* read */
    movb $1, %al /* sectors amount */
    movw $(CACHE), %bx
    int $0x13

    jnc read_success
    PUTS s_read_error
read_success:
    ret

putc:
    movb $0x0e, %ah
    int $0x10
    ret

puts:
    lodsb
    orb %al, %al
    jz puts_out
    call putc
    jmp puts
puts_out:
    ret

putx:
    orw %ax, %ax
    jnz putx_recursion
    PUTC $'0'
    jmp putx_out
putx_recursion:
    push %ax
    shr $4, %ax
    orw %ax, %ax
    jz putx_recursion_end
    call putx_recursion
putx_recursion_end:
    pop %ax
    andb $0xF, %al
    cmp $9, %al
    jg putx_high
    add $'0', %al
    call putc
    jmp putx_out
putx_high:
    add $('A' - 10), %al
    call putc
putx_out:
    ret

    /* Not used space */
    .org PARTITION_TABLE_OFFSET, NOP

    /* Empty partition table */
    .org BOOT_SIGNATURE_OFFSET, 0

    /* MBR signature */
    .word 0xaa55
