.section .text
.globl main

main:
    la t0, trap
    csrw mtvec, t0
    li t0, 1 << 13
    csrs mstatus, t0
    li s0, 0

    # Reserved static rounding modes 101 and 110 (fadd.d).
    .insn r 0x53, 5, 0x01, f0, f1, f2
    .insn r 0x53, 6, 0x01, f0, f1, f2

    # Dynamic rounding mode with an invalid frm.
    li t0, 5
    csrw frm, t0
    fadd.d f0, f1, f2
    csrw frm, zero

    li t0, 3
    bne s0, t0, fail

    # A valid frm must not trap.
    fadd.d f0, f1, f2
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
