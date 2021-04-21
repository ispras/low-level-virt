__asm__(".code16\n");

static char vga_text_color;
short *vga_text_pos;

typedef enum {
    BLACK = 0,
    BLUE,
    GREEN,
    CYAN,
    RED,
    MAGENTA,
    BROWN,
    LIGHT_GRAY,
    /* Foreground color only */
    DARK_GRAY,
    LIGHT_BLUE,
    LIGHT_GREEN,
    LIGHT_CYAN,
    LIGHT_RED,
    PINK,
    YELLOW,
    WHITE
} VGATextColor;


void vga_set_blink(int blink)
{
    if (blink) {
        vga_text_color |= 8;
    } else {
        vga_text_color &= ~8;
    }
}

void vga_set_foreground(VGATextColor color)
{
    color &= 0xF;
    vga_text_color &= 0xF0;
    vga_text_color |= color;
}

void vga_set_background(VGATextColor color)
{
    color &= 0x7;
    color <<= 4;
    vga_text_color &= 0x8F;
    vga_text_color |= color;
}


void vga_reset(void)
{
    vga_text_pos = (short *) 0xB8000;
    vga_set_blink(0);
    vga_set_foreground(WHITE);
    vga_set_background(BLACK);
}

void vga_puts(const char *s)
{
    /* VGA text buffer is at 0xB8000.
     * It's addressed as 0B80:vga_text_pos, i.e. DS = 0B80.
     * */

    while (*s) {
        *vga_text_pos = ((short) *s) | (((short) vga_text_color) << 8);
        s++;
    }
}

void main(void)
{
    vga_reset();

    vga_puts("white ");

    vga_set_background(LIGHT_GRAY);
    vga_set_foreground(DARK_GRAY);
    vga_puts("black ");

    vga_set_blink(1);
    vga_puts("blink ");
}
