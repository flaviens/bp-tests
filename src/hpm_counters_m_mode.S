.section .text
.globl main

main:
    la t0, trap
    csrw mtvec, t0

    # The HPM counters and event selectors must be accessible from M-mode
    # (read-only zero is a legal implementation).
    li t0, -1
    csrr t1, mhpmcounter3
    csrr t1, mhpmcounter31
    csrr t1, hpmcounter3
    csrr t1, hpmcounter31
    csrw mhpmcounter3, t0
    csrw mhpmevent3, t0
    csrr t1, mhpmevent3
    csrw mhpmevent31, t0
    csrr t1, mhpmevent31
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
