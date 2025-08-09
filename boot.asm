; boot.asm - Multiboot2 header + switch to long mode
; Assemble with: nasm -f elf64 boot.asm -o boot.o

; -------------------------
; Multiboot2 header (minimal)
; -------------------------
SECTION .multiboot
ALIGN 8
multiboot_hdr:
    dd 0xe85250d6              ; magic
    dd 0                       ; architecture (0)
    dd multiboot_hdr_end - multiboot_hdr  ; header length
    dd -(0xe85250d6 + 0 + (multiboot_hdr_end - multiboot_hdr)) ; checksum

    ; minimal end tag
    dw 0
    dw 0
    dd 8

multiboot_hdr_end:

; -------------------------
; Actual code (start in 32-bit protected mode)
; -------------------------
SECTION .text
BITS 32
GLOBAL kernel_entry
EXTERN kernel_main
EXTERN idt_init

kernel_entry:
    ; We assume GRUB left us in protected mode with flat segments.
    ; Setup a basic GDT (we'll load it) then enable PAE, set up page tables,
    ; enable long mode LME via EFER MSR and enable paging, then far-jump into 64-bit.

    cli

    ; -------------------------
    ; Load a GDT describing 32-bit and 64-bit segments
    ; -------------------------
    lgdt [gdt_descriptor]

    ; Clear segment registers (use data selector 0x10)
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; -------------------------
    ; Prepare page tables (we placed them in the data below)
    ; -------------------------
    ; Enable PAE (CR4.PAE = bit 5)
    mov eax, cr4
    or eax, 1 << 5
    mov cr4, eax

    ; Load PML4 address into CR3
    mov eax, pml4       ; address of pml4 (linker resolves this to physical addr)
    mov cr3, eax

    ; Set EFER.LME (MSR 0xC0000080, bit 8)
    mov ecx, 0xC0000080
    mov eax, 1 << 8
    xor edx, edx
    wrmsr

    ; Enable paging (CR0.PG)
    mov eax, cr0
    or eax, 1 << 31      ; PG
    mov cr0, eax

    ; Far jump to 64-bit code segment selector (0x08)
    jmp 0x08:long_mode_entry

; -------------------------
; 64-bit entry point (we are now in long mode)
; -------------------------
BITS 64
long_mode_entry:
    ; Set up a stack for long mode
    mov rbp, 0
    mov rsp, stack_top

    call idt_init
    ; Call kernel_main (C function in 64-bit)
    extern kernel_main
    call kernel_main

    ; If kernel returns, halt forever
.halt:
    hlt
    jmp .halt

; -------------------------
; GDT (3 entries: null, 64-bit code, 64-bit data)
; We define descriptor bytes directly.
; -------------------------
SECTION .data
ALIGN 8
gdt_table:
    dq 0x0000000000000000        ; null

    ; 64-bit code segment descriptor (base=0, limit=0, flags for 64-bit code)
    ; descriptor: 0x00AF9A000000FFFF (constructed)
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 0x9A
    db 0xAF
    db 0x00

    ; 64-bit data segment descriptor (base=0, limit=0, flags)
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 0x92
    db 0xAF
    db 0x00

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_table - 1   ; limit
    dd gdt_table                 ; base

; -------------------------
; Page tables (identity map first 4 MiB using 2 MiB pages)
; Layout: pml4 -> pdpt -> pd (2MB pages)
; Entries are 8 bytes each (64-bit values).
; Flags used: present + rw + PS (for PDE) = 0x83 (P + RW + PS)
; For PML4 and PDPT entries we use flags present + rw = 0x3
; -------------------------
ALIGN 4096
pml4:
    dq pdpt + 0x3      ; entry 0 -> points to pdpt
    times 511 dq 0

ALIGN 4096
pdpt:
    dq pd + 0x3       ; entry 0 -> points to pd
    times 511 dq 0

ALIGN 4096
pd:
    ; Map first 2MB -> phys 0x00000000
    ; PDE for 2MB page: physical addr | flags; here flags = P(1)+RW(2)+PS(128) = 0x83
    dq 0x0000000000000000 | 0x83
    ; Map second 2MB -> phys 0x00200000
    dq 0x0000000000200000 | 0x83
    times 510 dq 0

; -------------------------
; Stack
; -------------------------
ALIGN 16


SECTION .bss
ALIGN 16
stack_bottom:
    resb 16384
stack_top:

; -------------------------
; .note.GNU-stack to silence executable stack warning (optional)
; -------------------------
SECTION .note.GNU-stack
