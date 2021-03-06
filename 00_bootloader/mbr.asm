/* Externally definable parameters */

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

#define BOOT_DRIVE DATA(0)

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
    .asciz "Bootloader"
s_boot_drive:
    .asciz "Boot drive:"

/* Helper code */

#include "../common/i8086/bios-io.asm.inc"

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
    PUTNL

    /* Print boot drive number */
    PUTS s_boot_drive
    PUTC $' '
    PUTX BOOT_DRIVE
    PUTNL

    /* Some tests  */
    PUTX $0x1234
    PUTNL
    PUTX $0xDAED
    PUTNL
    PUTX $0xBEEF
    PUTNL

loop:
    jmp loop

    /* Not used space */
    .org PARTITION_TABLE_OFFSET, NOP

    /* Empty partition table */
    .org BOOT_SIGNATURE_OFFSET, 0

    /* MBR signature */
    .word 0xaa55
