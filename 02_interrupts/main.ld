ENTRY(main)
SECTIONS
{
    . = 0x4000;
    .bss :
    {
        *(.bss);
    }
    . = 0x5000;
    .rodata :
    {
        *(.rodata);
    }
    . = 0x6000;
    .data :
    {
        *(.data);
    }
    . = 0x8000;
    .text :
    {
        *(.text);
    }
}