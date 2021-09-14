/* Cyclic redundancy check */

#ifndef CRC16_POLY
#define CRC16_POLY 0x1021
#endif

.text
.code16

/* Account next byte from bl to current CRC value in ax. New value is in ax. */
.globl crc16b
crc16b:
    push %bx
    push %cx

    shl $8, %bx
    xor %bx, %ax

    mov $8, %cx
    shl $1, %ax
crc16b__loop:
    jnc crc16b__next
    xor $ CRC16_POLY, %ax
crc16b__next:
    shl $1, %ax
    loop crc16b__loop

    pop %cx
    pop %bx
    ret

#undef POLY

/* Account next word from bx to current CRC value in ax, LSB first.
 * New value is in ax. */
.globl crc16w
crc16w:
    push %bx
    call crc16b
    mov %bh, %bl
    call crc16b
    pop %bx
    ret
