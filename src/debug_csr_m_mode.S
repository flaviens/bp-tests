.section .text
.globl main

main:
    la t0, trap
    csrw mtvec, t0

    # dcsr, dpc and dscratch0/1 are only accessible in Debug Mode.
    li s0, 0
    csrr t0, dcsr
    csrr t0, dpc
    csrw dscratch0, zero
    csrr t0, dscratch1
    li t0, 4
    bne s0, t0, fail
    j pass

.align 2
trap:
    csrr t0, mcause
    li t1, 2
    bne t0, t1, fail
    addi s0, s0, 1
    csrr t0, mepc
    addi t0, t0, 4
    csrw mepc, t0
    mret

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
