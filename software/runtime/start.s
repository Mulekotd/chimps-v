.section .text.start
.globl _start

_start:
    la sp, __stack_top
    andi sp, sp, -16
    la t0, __bss_start
    la t1, __bss_end
0:
    bgeu t0, t1, 1f
    sw zero, 0(t0)
    addi t0, t0, 4
    j 0b
1:
    call main
    li t0, 0xffff0010
    li t1, 1
    sw t1, 0(t0)
2:  j 2b
