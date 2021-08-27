/* https://wiki.osdev.org/A20_Line */

.text
.code16

.globl check_a20
check_a20:
    pushf
    push %ds
    push %es
    push %di
    push %si

    // es = 0x0000
    xor %ax, %ax
    mov %ax, %es

    // ds = 0xFFFF
    not %ax
    mov %ax, %ds

    mov $0x0500, %di
    mov $0x0510, %si

    /* It's going to change data in memory.
       Preserve current values in stack. */

    // %al = *(char *)((0x0000 << 4) + 0x0500) // 0x000500
    mov %es:(%di), %al
    push %ax

    // %al = *(char *)((0xFFFF << 4) + 0x0510) // 0x100500
    mov %ds:(%si), %al
    push %ax

    /* When A20 is disabled both 0x000500 and 0x100500 do point to same
       byte because most significant 1 is in 20-th bit and have no effect. */

    // *(char *)0x000500 = 0x00
    movb $0x00, %es:(%di)
    // *(char *)0x100500 = 0xFF
    movb $0xFF, %ds:(%si)

    cmpb $0xFF, %es:(%di)

    /* Restore previous memory values. */
    pop %ax
    mov %al, %ds:(%si)

    pop %ax
    mov %al, %es:(%di)

    mov $0, %ax // Note, don't use `xor %ax, %ax`, it overrides flags.
    je check_a20__exit

    mov $1, %ax

check_a20__exit:
    pop %si
    pop %di
    pop %es
    pop %ds
    popf

    ret


.globl enable_a20_port92
enable_a20_port92:
    inb $0x92, %al
    or $2, %al
    and $0xFE, %al /* setting 0-th causes system reset, prevent it */
    outb %al, $0x92
    ret


.globl disable_a20_port92
disable_a20_port92:
    inb $0x92, %al
    /* Setting 0-th causes system reset. So, set 1-st bit (disable A20 and
       ensure 0-th bit is clear too. */
    and $0xFC, %al
    outb %al, $0x92
    ret
