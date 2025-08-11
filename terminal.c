#include "terminal.h"
#include "vga.h"
#include "keyboard.h"
#include <string.h>

#define TERMINAL_MAX_INPUT 128

static char input_buffer[TERMINAL_MAX_INPUT];
static uint32_t input_length = 0;

static void terminal_prompt() {
    vga_puts("myos> ");
}

void terminal_init() {
    input_length = 0;
    memset(input_buffer, 0, sizeof(input_buffer));
    terminal_prompt();
}

static void terminal_execute_command(const char* cmd) {
    if (strcmp(cmd, "help") == 0) {
        vga_puts("Available commands:\n");
        vga_puts("help    - Show this help message\n");
        vga_puts("clear   - Clear the screen\n");
        vga_puts("echo    - Print text\n");
        vga_puts("version - Show OS version\n");
    }
    else if (strcmp(cmd, "clear") == 0) {
        vga_clear();
    }
    else if (strncmp(cmd, "echo ", 5) == 0) {
        vga_puts(cmd + 5);
        vga_putc('\n');
    }
    else if (strcmp(cmd, "version") == 0) {
        vga_puts("MyOS version 0.1\n");
    }
    else if (strlen(cmd) == 0) {
        // do nothing
    }
    else {
        vga_puts("Unknown command. Type 'help'.\n");
    }
}

void terminal_handle_char(char c) {
    if (c == '\n') {
        vga_putc('\n');
        input_buffer[input_length] = '\0';
        terminal_execute_command(input_buffer);
        input_length = 0;
        memset(input_buffer, 0, sizeof(input_buffer));
        terminal_prompt();
    }
    else if (c == '\b') {
        if (input_length > 0) {
            input_length--;
            vga_putc('\b');
        }
    }
    else if (input_length < TERMINAL_MAX_INPUT - 1) {
        input_buffer[input_length++] = c;
        vga_putc(c);
    }
}
