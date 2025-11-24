/* tests/sha_baseline_2.c
   Minimal guaranteed-to-run program for RISC-V simulation.
   It writes 1 to 0x10 (so the testbench detects completion) and loops forever.
*/

#include <stdint.h>

typedef uint32_t u32;

/* address observed by the testbench */
volatile u32 * const DONE_ADDR = (volatile u32*)0x00000010;

int main(void) {
    /* write the completion marker */
    *DONE_ADDR = 1u;

    /* infinite loop so simulation can observe the write */
    while (1) {
        /* keep the CPU occupied but do nothing harmful */
        volatile u32 x = 0;
        (void)x;
    }

    return 0;
}
