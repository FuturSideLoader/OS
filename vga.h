#ifndef VGA_H
#define VGA_H

#include <stddef.h>  // définit size_t
#include <stdint.h>  // définit uint8_t, uint16_t

#define VGA_WIDTH 80
#define VGA_HEIGHT 25

void vga_clear(void);
void vga_print(const char* str);
void vga_print_at(const char* str, size_t col, size_t row);
void vga_puts(const char* str);
void vga_putc(char c);

#endif
