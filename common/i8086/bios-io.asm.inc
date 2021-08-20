/* Helper macros */

/* print a zero terminated ASCII STRing on screen */
.macro PUTS STR
    leaw \STR, %si
    call puts
.endm

/* print a 16-bit INTEGER on a screen in hexadecimal format */
.macro PUTX INTEGER
    mov \INTEGER, %ax
    call putx
.endm

/* print an ASCII CHARacter on screen */
.macro PUTC CHAR
    mov \CHAR, %al
    call putc
.endm

/* goto new line */
.macro PUTNL
    PUTC $'\r'
    PUTC $'\n'
.endm

.code16

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
