#ifndef VGA_H
#define VGA_H

#define VGA_MOD_LIGHT   8
#define VGA_MOD_BLINK   8

#define VGA_BLACK       0
#define VGA_BLUE        1
#define VGA_GREEN       2
#define VGA_CYAN        3
#define VGA_RED         4
#define VGA_MAGENTA     5
#define VGA_BROWN       6
#define VGA_LIGHT_GRAY  7

#define VGA_DARK_GRAY   (VGA_BLACK | VGA_MOD_LIGHT)
#define VGA_LIGHT_BLUE  (VGA_BLUE | VGA_MOD_LIGHT)
#define VGA_LIGHT_GREEN (VGA_GREEN | VGA_MOD_LIGHT)
#define VGA_LIGHT_CYAN  (VGA_CYAN | VGA_MOD_LIGHT)
#define VGA_LIGHT_RED   (VGA_RED | VGA_MOD_LIGHT)
#define VGA_PINK        (VGA_MAGENTA | VGA_MOD_LIGHT)
#define VGA_YELLOW      (VGA_BROWN | VGA_MOD_LIGHT)
#define VGA_WHITE       (VGA_LIGHT_GRAY | VGA_MOD_LIGHT)

#endif /* VGA_H */
