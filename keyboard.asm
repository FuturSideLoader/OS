BITS 64
default rel

section .text
global keyboard_handler
extern scancode_map
extern scancode_map_shift
extern keyboard_buffer_push
extern shift_pressed
extern ctrl_pressed
extern alt_pressed
extern scancode
extern handle_space
extern print_space

keyboard_handler:
    push rbp
    mov rbp, rsp

    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi

    ; Lire le scancode
    in al, 0x60
    movzx rsi, al

    ; Gérer appuis / relâchement Shift gauche (0x2A) et droit (0x36)
    cmp rsi, 0x2A
    je .shift_down
    cmp rsi, 0x36
    je .shift_down
    cmp rsi, 0xAA
    je .shift_up
    cmp rsi, 0xB6
    je .shift_up

    ; Gérer Ctrl gauche (0x1D) press / release
    cmp rsi, 0x1D
    je .ctrl_down
    cmp rsi, 0x9D
    je .ctrl_up

    ; Gérer Alt gauche (0x38) press / release
    cmp rsi, 0x38
    je .alt_down
    cmp rsi, 0xB8
    je .alt_up

    ; Gérer la touche espace
    cmp byte [scancode], 0x39
    je .call_handle_space
    cmp byte [scancode], 0xB9
    jne .coninue
    .call_handle_space:
    call handle_space
    jmp .end_interrupt


    ; Filtrer si scancode > table
    cmp rsi, 0x5E
    ja .end_interrupt

    ; Choisir table selon Shift
    mov rdi, scancode_map
    cmp dword [shift_pressed], 0
    je .map_chosen
    mov rdi, scancode_map_shift

.map_chosen:
    movzx rbx, byte [rdi + rsi]
    cmp bl, 0
    je .end_interrupt

    movzx edi, bl
    call keyboard_buffer_push

.end_interrupt:
    mov al, 0x20
    out 0x20, al
    jmp .restore

.shift_down:
    mov dword [shift_pressed], 1
    jmp .end_interrupt

.shift_up:
    mov dword [shift_pressed], 0
    jmp .end_interrupt

.ctrl_down:
    mov dword [ctrl_pressed], 1
    jmp .end_interrupt

.ctrl_up:
    mov dword [ctrl_pressed], 0
    jmp .end_interrupt

.alt_down:
    mov dword [alt_pressed], 1
    jmp .end_interrupt

.alt_up:
    mov dword [alt_pressed], 0
    jmp .end_interrupt

.handle_space:
    call print_space

.restore:
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    leave
    iretq
