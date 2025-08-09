OUTPUT_FORMAT(elf64-x86-64)
ENTRY(kernel_entry)
SECTIONS {
  . = 0x00100000; /* link at 1 MiB */
  .multiboot : { *(.multiboot) }
  .text : { *(.text*) }
  .rodata : { *(.rodata*) }
  .data : { *(.data*) }
  .bss : { *(.bss*) *(COMMON) }
  /DISCARD/ : { *(.note.GNU-stack) }
}
