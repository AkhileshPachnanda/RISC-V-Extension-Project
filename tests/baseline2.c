#define FINISH (*((volatile unsigned int*)0x00000010))

int main(void)
{
    // Tiny delay using a plain C loop (compiler can't optimize it away because volatile)
    volatile unsigned int delay = 0;
    for (int i = 0; i < 100; i++) {
        delay += i;
    }

    // Signal success
    FINISH = 0xCAFEBABE;

    // Infinite loop
    while (1) {
        // Do nothing
    }
}

