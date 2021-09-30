#include "../common/vga.h"
#include "../common/types.h"

typedef u8 VGATextColor;

extern VGATextColor vga_text_color;
extern u16 vga_text_pos;

static void vga_set_foreground(VGATextColor color)
{
    color &= 0xF;
    vga_text_color &= 0xF0;
    vga_text_color |= color;
}

static void vga_set_background(VGATextColor color)
{
    color &= 0x7;
    color <<= 4;
    vga_text_color &= 0x8F;
    vga_text_color |= color;
}

static void vga_puts(const char *s)
{
    /* VGA text buffer is at 0xB8000.
     * In real mode it's addressed as 0B80:vga_text_pos, i.e. DS = 0B80.
     * But, it's in protected mode.
     * */

    u16 c = (((u16) vga_text_color) << 8);

    while (*s) {
        *(u16 *)(0xB8000 + vga_text_pos) = ((u16) *s) | c;
        vga_text_pos += 2;
        s++;
    }
}

void protected(void)
{
    vga_set_foreground(VGA_RED);
    vga_set_background(VGA_LIGHT_GREEN);
    vga_puts("Protected mode");
}
