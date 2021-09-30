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

#define VGA_LIGHT(BASE_COLOR) ((BASE_COLOR) | VGA_MOD_LIGHT)

#define VGA_DARK_GRAY    VGA_LIGHT(VGA_BLACK)
#define VGA_LIGHT_BLUE   VGA_LIGHT(VGA_BLUE)
#define VGA_LIGHT_GREEN  VGA_LIGHT(VGA_GREEN)
#define VGA_LIGHT_CYAN   VGA_LIGHT(VGA_CYAN)
#define VGA_LIGHT_RED    VGA_LIGHT(VGA_RED)
#define VGA_PINK         VGA_LIGHT(VGA_MAGENTA)
#define VGA_YELLOW       VGA_LIGHT(VGA_BROWN)
#define VGA_WHITE        VGA_LIGHT(VGA_LIGHT_GRAY)

#endif /* VGA_H */
