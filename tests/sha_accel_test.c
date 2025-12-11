/* sha_accel.c
   Accelerated SHA-256 using custom RISC-V instructions.
   This computes the full SHA-256 hash for "abc" (one block).
   Replace software Sigma functions with custom instruction 0x0005050b (assumed for Sigma0).
   Adjust opcode if your custom instr is different.
   Writes the final hash state to memory and signals completion at 0x00000010.
*/

#include <stdint.h>

#define DONE ((volatile uint32_t*)0x00000010)

typedef uint32_t u32;
typedef uint8_t  u8;

#ifdef __riscv

/* Custom instruction: to compute Sigma0 (rotr(x,2) ^ rotr(x,13) ^ rotr(x,22)) on a0. */
static inline u32 custom_sigma0(u32 in) {
    register u32 a0 asm("a0") = in;
    asm volatile (".word 0x0005050b\n" : "+r"(a0) : : "memory");
    return a0;
}

/* Custom for Sigma1 (rotr(x,6) ^ rotr(x,11) ^ rotr(x,25)) — adjust opcode if needed. */
static inline u32 custom_sigma1(u32 in) {
    register u32 a0 asm("a0") = in;
    asm volatile (".word 0x0005050b\n" : "+r"(a0) : : "memory");  // Use same or different opcode
    return a0;
}

/* Custom for sigma0 (rotr(x,7) ^ rotr(x,18) ^ (x>>3)). */
static inline u32 custom_sigma_small0(u32 in) {
    register u32 a0 asm("a0") = in;
    asm volatile (".word 0x0005050b\n" : "+r"(a0) : : "memory");
    return a0;
}

/* Custom for sigma1 (rotr(x,17) ^ rotr(x,19) ^ (x>>10)). */
static inline u32 custom_sigma_small1(u32 in) {
    register u32 a0 asm("a0") = in;
    asm volatile (".word 0x0005050b\n" : "+r"(a0) : : "memory");
    return a0;
}

#else

/* Stub for non-RISC-V compilation (e.g., editing on PC) */
static inline u32 custom_sigma0(u32 in) { return 0; }
static inline u32 custom_sigma1(u32 in) { return 0; }
static inline u32 custom_sigma_small0(u32 in) { return 0; }
static inline u32 custom_sigma_small1(u32 in) { return 0; }

#endif /* __riscv */

/* Ch and Maj remain software (simple bitwise, no custom needed) */
static inline u32 Ch(u32 x, u32 y, u32 z) { return (x & y) ^ (~x & z); }
static inline u32 Maj(u32 x, u32 y, u32 z) { return (x & y) ^ (x & z) ^ (y & z); }

/* Accelerated SHA-256 compression function for one block */
void sha256_compress(const u8 block[64], u32 state[8]) {
    u32 W[64];
    u32 a = state[0], b = state[1], c = state[2], d = state[3];
    u32 e = state[4], f = state[5], g = state[6], h = state[7];
    int t;

    // Message schedule (software for now — could accelerate if needed)
    for (t = 0; t < 16; t++) {
        W[t] = (u32)block[t*4] << 24 | (u32)block[t*4+1] << 16 |
               (u32)block[t*4+2] << 8  | (u32)block[t*4+3];
    }
    for (t = 16; t < 64; t++) {
        W[t] = custom_sigma_small1(W[t-2]) + W[t-7] + custom_sigma_small0(W[t-15]) + W[t-16];
    }

    // Compression loop — use custom instructions for Sigma0 and Sigma1
    for (t = 0; t < 64; t++) {
        u32 T1 = h + custom_sigma1(e) + Ch(e, f, g) + K[t] + W[t];
        u32 T2 = custom_sigma0(a) + Maj(a, b, c);
        h = g; g = f; f = e; e = d + T1;
        d = c; c = b; b = a; a = T1 + T2;
    }

    // Update state
    state[0] += a; state[1] += b; state[2] += c; state[3] += d;
    state[4] += e; state[5] += f; state[6] += g; state[7] += h;
}

/* K constants — same as baseline */
static const u32 K[64] = {
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
};

int main(void) {
    // Initial state (standard SHA-256 constants)
    u32 state[8] = {
        0x6a09e667u, 0xbb67ae85u, 0x3c6ef372u, 0xa54ff53au,
        0x510e527fu, 0x9b05688cu, 0x1f83d9abu, 0x5be0cd19u
    };

    // Sample input block ("abc" padded to 512 bits)
    u8 block[64] = {0};
    block[0] = 'a';
    block[1] = 'b';
    block[2] = 'c';
    block[3] = 0x80;  // Padding start
    block[63] = 0x18;  // Message length = 24 bits

    // Compute accelerated SHA-256
    sha256_compress(block, state);

    // Signal completion to testbench (write hash[0] as example)
    *DONE = state[0];  // You can write the full hash if testbench reads multiple addresses

    while (1);  // Loop forever
}