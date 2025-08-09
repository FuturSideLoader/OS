#ifndef KEYBOARD_H
#define KEYBOARD_H

#include <stdint.h>

extern const uint8_t scancode_map[0x5E];

extern volatile uint8_t shift_pressed;
extern volatile uint8_t ctrl_pressed;
extern volatile uint8_t alt_pressed;
extern volatile uint8_t capslock_on;

void keyboard_init(void);
int keyboard_buffer_has_char(void);
int keyboard_buffer_read_char(void);
void keyboard_buffer_flush(void);
void keyboard_buffer_push(char c); // appelée depuis ASM

#endif
