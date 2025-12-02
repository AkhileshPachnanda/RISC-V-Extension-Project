// tests/sha_baseline_2.c
// FINAL VERSION THAT WORKS ON YOUR TOOLCHAIN (gcc 10.2.0-2020.12.8)
// No memcpy, no memset, no large initializers → clean link every time

#include <stdint.h>

#define DONE ((volatile uint32_t*)0x00000010)

typedef uint32_t u32;
typedef uint8_t  u8;

static const u32 K[64] = {
    0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
    0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
    0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
    0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
    0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
    0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
    0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
    0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2
};

static inline u32 rotr(u32 x, u32 n) { return (x >> n) | (x << (32-n)); }
static inline u32 Ch (u32 x, u32 y, u32 z) { return (x&y) ^ (~x&z); }
static inline u32 Maj(u32 x, u32 y, u32 z) { return (x&y) ^ (x&z) ^ (y&z); }
static inline u32 Sigma0(u32 x) { return rotr(x,2) ^ rotr(x,13) ^ rotr(x,22); }
static inline u32 Sigma1(u32 x) { return rotr(x,6) ^ rotr(x,11) ^ rotr(x,25); }
static inline u32 sigma0(u32 x) { return rotr(x,7) ^ rotr(x,18) ^ (x>>3); }
static inline u32 sigma1(u32 x) { return rotr(x,17) ^ rotr(x,19) ^ (x>>10); }

void sha256_compress(const u8 block[64], u32 state[8])
{
    u32 W[64];
    u32 a,b,c,d,e,f,g,h;
    int t;

    for (t=0; t<16; t++) {
        W[t] = ((u32)block[t*4]     << 24) |
               ((u32)block[t*4 + 1] << 16) |
               ((u32)block[t*4 + 2] <<  8) |
                (u32)block[t*4 + 3];
    }
    for (t=16; t<64; t++)
        W[t] = sigma1(W[t-2]) + W[t-7] + sigma0(W[t-15]) + W[t-16];

    a=state[0]; b=state[1]; c=state[2]; d=state[3];
    e=state[4]; f=state[5]; g=state[6]; h=state[7];

    for (t=0; t<64; t++) {
        u32 T1 = h + Sigma1(e) + Ch(e,f,g) + K[t] + W[t];
        u32 T2 = Sigma0(a) + Maj(a,b,c);
        h=g; g=f; f=e; e=d+T1;
        d=c; c=b; b=a; a=T1+T2;
    }

    state[0]+=a; state[1]+=b; state[2]+=c; state[3]+=d;
    state[4]+=e; state[5]+=f; state[6]+=g; state[7]+=h;
}

int main(void)
{
    u32 state[8];

    // initialise state manually (8 words → GCC never emits memcpy)
    state[0] = 0x6a09e667u;
    state[1] = 0xbb67ae85u;
    state[2] = 0x3c6ef372u;
    state[3] = 0xa54ff53au;
    state[4] = 0x510e527fu;
    state[5] = 0x9b05688cu;
    state[6] = 0x1f83d9abu;
    state[7] = 0x5be0cd19u;

    u8 block[64];

    // initialise block manually → no memset, no memcpy
    for (int i = 0; i < 64; i++) block[i] = 0x00;

    block[0] = 'a';
    block[1] = 'b';
    block[2] = 'c';
    block[3] = 0x80;      // padding bit
    block[63] = 0x18;     // length = 24 bits

    sha256_compress(block, state);

    *DONE = 0xDEADBEEF;
    while(1);
}