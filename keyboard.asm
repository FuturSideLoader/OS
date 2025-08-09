BITS 64
default rel

section .text
global keyboard_handler
extern scancode_map
extern keyboard_buffer_push

; Variables externes pour état des touches shift/ctrl si besoin
extern shift_pressed
extern ctrl_pressed
extern alt_pressed

; Interrupt handler clavier
keyboard_handler:
    push rbp
    mov rbp, rsp

    ; Sauvegarder registres utilisés
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi

    ; Lire le scancode du port 0x60
    in al, 0x60
    movzx rsi, al          ; rsi = scancode

    ; Vérifier si scancode < taille table (0x5E ici)
    cmp rsi, 0x5E
    ja .no_key             ; si au-delà, aucune action

    ; Récupérer le pointeur sur scancode_map (table char en C)
    mov rdi, scancode_map

    ; Charger le caractère correspondant : scancode_map[scancode]
    movzx rbx, byte [rdi + rsi]

    ; Si caractère nul (0), ne rien faire
    cmp bl, 0
    je .no_key

    ; Appeler keyboard_buffer_push(caractère)
    movzx edi, bl          ; caractère dans edi (int/char)
    call keyboard_buffer_push

.no_key:
    ; Lire le port 0x61 pour reset du contrôleur clavier (non obligatoire)
    in al, 0x61
    or al, 0x80
    out 0x61, al
    and al, 0x7F
    out 0x61, al

    ; Signal EOI au PIC (important !)
    mov al, 0x20
    out 0x20, al

    ; Restaurer registres
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax

    leave
    iretq
