@'
ENTRY(_start)

SECTIONS
{
  . = 0x00000000;

  .text   : { *(.text*) }
  .rodata : { *(.rodata*) }
  .data   : { *(.data*) }
  .sdata  : { *(.sdata*) }
  .bss    : { *(.bss*) }

  /DISCARD/ : { *(.eh_frame*) *(.comment*) }
}
'@ > linker.ld
