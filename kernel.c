#include <stdint.h>
#include "vga.h"
#include "idt.h"
#include "keyboard.h"

void kernel_main() {
    vga_clear();

    vga_puts("Hello from MyOS 64-bit!\n");
    vga_puts("Base system initialized successfully.\n");
    vga_puts("Keyboard test: Type something...\n");

    idt_init();
    keyboard_init();

    while(1) {
        asm volatile ("hlt");
        if(keyboard_buffer_has_char()) {
            int c = keyboard_buffer_read_char();
            if(c != -1) {
                vga_putc((char)c);
            }
        }
    }
}
