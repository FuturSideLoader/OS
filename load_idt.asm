; load_idt.asm - fonction pour charger l'IDT avec lidt

global load_idt
section .text

; void load_idt(idt_ptr_t* idt_ptr)
load_idt:
    lidt [rdi]   ; rdi contient l'adresse de idt_ptr (limit + base)
    ret
