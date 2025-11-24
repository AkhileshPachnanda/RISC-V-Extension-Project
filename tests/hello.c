// tests/hello_small.c
volatile unsigned int *DONE_ADDR = (unsigned int *)0x00000010;

int main() {
    *DONE_ADDR = 1;   // small immediate -> straightforward codegen
    while (1) { }     // hang so TB can see write
    return 0;
}
