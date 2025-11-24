/* crt0.S - minimal crt for bare-metal RISC-V (rv32i) */
    .section .text
    .global _start
    .option norvc

_start:
    /* load address of stack top into sp (symbol provided by linker) */
    la    sp, _stack_top

    /* optional: write sp (low 32 bits) to debug MMIO at byte addr 0x20
       so testbench can see initial SP value early */
    li    t0, 0x20
    sw    sp, 0(t0)

    /* call main */
    call  main

    /* fallback: infinite loop */
1:  j     1b
