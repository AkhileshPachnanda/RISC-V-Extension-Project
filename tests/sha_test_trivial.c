// tests/sha_test_trivial.c
// Simple test program: write a magic value at 0x10 then spin forever.
// Uses a single, legal RISC-V inline asm instruction inside the spin loop.

#include <stdint.h>

typedef uint32_t u32;
volatile u32 * const DONE_ADDR = (volatile u32*)0x00000010u;

int main(void) {
    // Write a known value so the testbench can detect completion.
    DONE_ADDR[0] = 0x12345678u; // store to address 0x10

    // Infinite loop: execute a single legal RISC-V ADDI to x0 (acts as NOP).
    // Using inline asm volatile ensures the compiler emits the instruction and
    // doesn't optimize or remove the loop.
    for (;;) {
        __asm__ volatile ("addi x0, x0, 0");
    }

    // unreachable
    return 0;
}
