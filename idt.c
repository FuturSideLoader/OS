#include "idt.h"
#include "io.h"      // <-- inclusion nouvelle

#define IDT_SIZE 256
static idt_entry_t idt[IDT_SIZE];
static idt_ptr_t idt_ptr;

extern void load_idt(idt_ptr_t*);

static void set_idt_entry(int vector, void (*handler)()) {
    uint64_t handler_addr = (uint64_t)handler;
    idt[vector].offset_low  = handler_addr & 0xFFFF;
    idt[vector].selector    = 0x08;  // Code segment selector
    idt[vector].ist         = 0;
    idt[vector].type_attr   = 0x8E;  // Interrupt gate, present, DPL=0
    idt[vector].offset_mid  = (handler_addr >> 16) & 0xFFFF;
    idt[vector].offset_high = (handler_addr >> 32) & 0xFFFFFFFF;
    idt[vector].zero        = 0;
}

void pic_remap(int offset1, int offset2) {
    // Save masks (on pourrait lire avec inb, ici on masque tout)
    uint8_t a1 = 0xFF;
    uint8_t a2 = 0xFF;

    // Init PICs in cascade mode
    outb(PIC1_COMMAND, 0x11);
    outb(PIC2_COMMAND, 0x11);

    outb(PIC1_DATA, offset1);
    outb(PIC2_DATA, offset2);

    outb(PIC1_DATA, 0x04);
    outb(PIC2_DATA, 0x02);

    outb(PIC1_DATA, 0x01);
    outb(PIC2_DATA, 0x01);

    // Restore masks
    outb(PIC1_DATA, a1);
    outb(PIC2_DATA, a2);
}

void idt_init() {
    idt_ptr.limit = sizeof(idt_entry_t) * IDT_SIZE - 1;
    idt_ptr.base  = (uint64_t)&idt;

    for (int i=0; i<IDT_SIZE; i++) {
        set_idt_entry(i, 0);
    }

    // Remap PIC to 0x20 and 0x28 (standard)
    pic_remap(0x20, 0x28);

    // Enable keyboard IRQ1 handler (interrupt vector 0x21)
    // Unmask IRQ1 (keyboard) - clear bit 1 on PIC1_DATA
    uint8_t mask = inb(PIC1_DATA);
    mask &= ~(1 << 1);
    outb(PIC1_DATA, mask);

    // Set keyboard interrupt handler vector 0x21
    extern void keyboard_handler();
    set_idt_entry(0x21, keyboard_handler);

    // Load IDT
    load_idt(&idt_ptr);

    // Enable interrupts
    asm volatile ("sti");
}
