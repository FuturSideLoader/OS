# Assembleur NASM
ASM=nasm
ASMFLAGS=-f elf64

# Compilateur GCC
CC=gcc
CFLAGS=-m64 -ffreestanding -nostdlib -nostartfiles -c

# Linker
LD=ld
LDFLAGS=-T linker.ld

# Fichiers sources
ASM_SRC=boot.asm load_idt.asm keyboard.asm
C_SRC=kernel.c vga.c idt.c keyboard_init.c scancode.c

# Objets
OBJ=$(ASM_SRC:.asm=.o) $(C_SRC:.c=.o)

# Nom binaire final
TARGET=myos.elf

# Règles

all: $(TARGET) iso myos.iso

$(TARGET): $(OBJ)
	$(LD) $(LDFLAGS) -o $@ $^

# Règle explicite pour boot.o
boot.o: boot.asm
	$(ASM) $(ASMFLAGS) $< -o $@

# Règle explicite pour les autres ASM (évite conflit ou erreur)
load_idt.o: load_idt.asm
	$(ASM) $(ASMFLAGS) $< -o $@

keyboard.o: keyboard.asm
	$(ASM) $(ASMFLAGS) $< -o $@

# Règle pour les fichiers C
%.o: %.c
	$(CC) $(CFLAGS) $< -o $@

iso:
	mkdir -p iso/boot/grub
	cp $(TARGET) iso/boot/
	cp grub.cfg iso/boot/grub/

myos.iso: iso
	grub-mkrescue -o myos.iso iso

run: myos.iso
	qemu-system-x86_64 -cdrom myos.iso -m 512M -boot d

clean:
	rm -rf *.o $(TARGET) iso myos.iso

.PHONY: all clean iso run
