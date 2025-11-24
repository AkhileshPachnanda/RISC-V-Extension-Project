/* tests/sha_accel_test.c
   Test the PCPI SHA accelerator:
   - Put input in a0, execute a single custom instruction (encoded via .word),
     read back the result from a0 and write it to address 0x10 so the TB detects completion.

   This file is guarded so it won't break when parsed by non-RISC-V host toolchains.
*/

#include <stdint.h>

typedef uint32_t u32;
volatile u32 * const DONE_ADDR = (volatile u32*)0x00000010;

#ifdef __riscv

/* Emit a single custom 32-bit instruction. We load 'in' in a0 and let the
   custom .word instruction operate on a0 and return value in a0.
   - "+r"(a0) tells the compiler 'a0' is read/write.
   - we include a trailing newline in the asm string which some assemblers expect.
*/
static inline u32 sha_accel_instr(u32 in) {
    register u32 a0 asm("a0") = in;
    asm volatile (".word 0x0005050b\n" : "+r"(a0) : : "memory");
    return a0;
}

#else

/* If not building with a RISC-V toolchain (e.g. VSCode IntelliSense), provide
   a harmless fallback so the editor/compiler doesn't error. */
static inline u32 sha_accel_instr(u32 in) {
    (void)in;
    return 0;
}

#endif /* __riscv */

int main(void) {
    u32 input = 0x01234567u;
    u32 out = sha_accel_instr(input);

    /* write the result so TB detects completion */
    *DONE_ADDR = out;

    /* hang forever so TB can see the write */
    for (;;);
    return 0;
}
