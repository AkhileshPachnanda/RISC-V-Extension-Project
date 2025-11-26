#include <stdint.h>
#define DONE_ADDR ((volatile uint32_t*)0x00000010)

int main() {
    *DONE_ADDR = 0x12345678;
    while(1);
    return 0;
}