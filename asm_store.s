    .section .text
    .global _start
_start:
    lui   t0, 0x0        # t0 = 0x00000000
    addi  t0, t0, 16     # t0 = 16 (address 0x10)
    li    t1, 1          # t1 = 1
    sw    t1, 0(t0)      # store 1 -> [0x10]
1:  j     1b             # infinite loop
