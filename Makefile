AS = nasm
CC = gcc
LD = ld

ASFLAGS = -f elf64
CFLAGS = -m64 -ffreestanding -nostdlib -nostartfiles -Wall -Wextra -c

OBJS = boot.o load_idt.o keyboard.o vga.o idt.o scancode.o terminal.o kernel.o

all: myos.iso

boot.o: boot.asm
	$(AS) $(ASFLAGS) boot.asm -o boot.o

load_idt.o: load_idt.asm
	$(AS) $(ASFLAGS) load_idt.asm -o load_idt.o

keyboard.o: keyboard.asm
	$(AS) $(ASFLAGS) keyboard.asm -o keyboard.o

%.o: %.c
	$(CC) $(CFLAGS) $< -o $@

myos.elf: $(OBJS)
	$(LD) -n -o myos.elf -Ttext 0x1000 $(OBJS) --oformat elf64-x86-64

iso: myos.elf
	mkdir -p iso/boot/grub
	cp myos.elf iso/boot/myos.elf
	echo 'set timeout=0' > iso/boot/grub/grub.cfg
	echo 'set default=0' >> iso/boot/grub/grub.cfg
	echo 'menuentry "MyOS" {' >> iso/boot/grub/grub.cfg
	echo '  multiboot2 /boot/myos.elf' >> iso/boot/grub/grub.cfg
	echo '  boot' >> iso/boot/grub/grub.cfg
	echo '}' >> iso/boot/grub/grub.cfg
	grub-mkrescue -o myos.iso iso

myos.iso: iso

run: myos.iso
	qemu-system-x86_64 -cdrom myos.iso

clean:
	rm -rf *.o myos.elf iso myos.iso
