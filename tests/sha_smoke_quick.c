// fast smoke: do the W expansion and write progress and finish
#include <stdint.h>
volatile uint32_t * const DONE_ADDR = (volatile uint32_t *)0x00000010;
volatile uint32_t * const PROG_ADDR = (volatile uint32_t *)0x00000020;

int main() {
    // small fake "block"
    static const uint8_t block[64] = {0};
    static uint32_t W[64];
    // init first 16 words
    for (int i=0;i<16;i++) W[i] = i;
    for (int t=16;t<64;t++){
        // very simple op to avoid heavy math
        W[t] = W[t-16] + W[t-7] + t;
        // write progress on every iteration
        *PROG_ADDR = t;
    }
    // write done
    *DONE_ADDR = 1;
    for(;;);
    return 0;
}
