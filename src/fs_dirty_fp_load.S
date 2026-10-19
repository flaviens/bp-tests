.section .text
.globl main

main:
    la t0, trap
    csrw mtvec, t0
    la a0, value
    li a1, 3 << 13
    li a2, 2 << 13
    li a3, 3

    # An FP load sets FS to Dirty before a following CSR read.
    csrc mstatus, a1
    csrs mstatus, a2
    fld f0, 0(a0)
    csrr t0, mstatus
    srli t0, t0, 13
    andi t0, t0, 3
    bne t0, a3, fail

    # A following CSR read-modify-write must not write FS back as Clean.
    csrc mstatus, a1
    csrs mstatus, a2
    li t1, 0
    fld f1, 8(a0)
    csrrs zero, mstatus, t1
    csrr t0, mstatus
    srli t0, t0, 13
    andi t0, t0, 3
    bne t0, a3, fail
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

.section .data
.balign 8
value:
    .dword 0x3ff0000000000000
    .dword 0x4000000000000000
