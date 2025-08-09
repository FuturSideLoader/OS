#include "keyboard.h"
#include "vga.h"
#include <stdint.h>

volatile uint8_t shift_pressed = 0;
volatile uint8_t ctrl_pressed = 0;
volatile uint8_t alt_pressed = 0;
volatile uint8_t capslock_on = 0;

#define KEYBOARD_BUFFER_SIZE 256

static char keyboard_buffer[KEYBOARD_BUFFER_SIZE];
static volatile uint16_t buffer_head = 0;
static volatile uint16_t buffer_tail = 0;

void keyboard_buffer_push(char c) {
    uint16_t next = (buffer_head + 1) % KEYBOARD_BUFFER_SIZE;
    if(next != buffer_tail) { // espace dispo dans buffer
        keyboard_buffer[buffer_head] = c;
        buffer_head = next;
    }
}

int keyboard_buffer_has_char(void) {
    return buffer_head != buffer_tail;
}

int keyboard_buffer_read_char(void) {
    if(buffer_head == buffer_tail) return -1;
    char c = keyboard_buffer[buffer_tail];
    buffer_tail = (buffer_tail + 1) % KEYBOARD_BUFFER_SIZE;
    return c;
}

void keyboard_buffer_flush(void) {
    buffer_head = 0;
    buffer_tail = 0;
}

static inline void outb(uint16_t port, uint8_t val) {
    asm volatile ("outb %0, %1" : : "a"(val), "Nd"(port));
}

void keyboard_init(void) {
    // Désactive toutes les interruptions IRQ sauf IRQ1 (clavier)
    outb(0x21, 0xFD);

    // Activer interruption clavier (IRQ1)
    vga_print("Keyboard initialized.\n");
}
