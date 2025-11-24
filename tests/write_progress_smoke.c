// tests/write_progress_smoke.c
#include <stdint.h>

volatile uint32_t * const PROG_ADDR = (volatile uint32_t *)0x00000020;
volatile uint32_t * const DONE_ADDR = (volatile uint32_t *)0x00000010;

int main() {
    for (uint32_t i = 0; i < 20; ++i) {
        *PROG_ADDR = i;
        for (volatile int j=0;j<1000;++j) { } // small delay
    }
    *DONE_ADDR = 1;
    for(;;);
    return 0;
}
