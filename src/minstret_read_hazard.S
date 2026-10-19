.section .text
.globl main

main:
    la t0, trap
    csrw mtvec, t0
    csrw mcountinhibit, zero
    nop
    nop
    nop

    # minstret must count all four addi retired before the read.
    csrw minstret, zero
    addi t1, zero, 1
    addi t1, t1, 1
    addi t1, t1, 1
    addi t1, t1, 1
    csrr t0, minstret
    li t1, 4
    bne t0, t1, fail
    j pass

.align 2
trap:
    j fail

pass:
    li t0, 0x00102000
    sw zero, 0(t0)
1:
    wfi
    j 1b

fail:
    li t0, 0x00102000
    li t1, 1
    sw t1, 0(t0)
2:
    wfi
    j 2b
