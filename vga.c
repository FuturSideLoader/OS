#include "vga.h"
#include <stdint.h> // pour uint8_t, uint16_t

#define VGA_WIDTH 80
#define VGA_HEIGHT 25
#define VGA_ADDRESS 0xB8000

static uint16_t* const VGA_MEMORY = (uint16_t*) VGA_ADDRESS;
static size_t cursor_row = 0;
static size_t cursor_col = 0;
static uint8_t color = 0x0F; // blanc sur noir

static uint16_t vga_entry(unsigned char uc, uint8_t color) {
    return (uint16_t)uc | (uint16_t)color << 8;
}

void vga_clear(void) {
    for (size_t y = 0; y < VGA_HEIGHT; y++) {
        for (size_t x = 0; x < VGA_WIDTH; x++) {
            VGA_MEMORY[y * VGA_WIDTH + x] = vga_entry(' ', color);
        }
    }
    cursor_row = 0;
    cursor_col = 0;
}

void vga_print(const char* str) {
    while (*str) {
        if (*str == '\n') {
            cursor_col = 0;
            cursor_row++;
        } else {
            VGA_MEMORY[cursor_row * VGA_WIDTH + cursor_col] = vga_entry(*str, color);
            cursor_col++;
            if (cursor_col >= VGA_WIDTH) {
                cursor_col = 0;
                cursor_row++;
            }
        }
        str++;
    }
}

void vga_puts(const char* str) {
    vga_print(str);
}

void vga_putc(char c) {
    char str[2] = {c, 0};
    vga_puts(str);
}

void vga_print_at(const char* str, size_t col, size_t row) {
    cursor_col = col;
    cursor_row = row;
    vga_print(str);
}

void print_space(void) {
    // Affiche un espace à la position actuelle du curseur
    VGA_MEMORY[cursor_row * VGA_WIDTH + cursor_col] = vga_entry(' ', color);
    cursor_col++;
    if (cursor_col >= VGA_WIDTH) {
        cursor_col = 0;
        cursor_row++;
        if (cursor_row >= VGA_HEIGHT) {
            cursor_row = 0;  // Ou implémenter scroll si besoin
        }
    }
}
