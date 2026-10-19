.section .text
.globl main

# M-mode accesses whose low 40 bits are a valid DRAM address but whose upper
# bits are set raise an access fault. mtval may hold the address or another
# invalid address, but never the valid alias in the low 40 bits.
.macro expect_fault cause, insn:vararg
    la s1, 1f
    li s4, \cause
    addi s2, s2, 1
1:
    \insn
    bne s2, s3, fail
.endm

main:
    la t0, trap
    csrw mtvec, t0
    li s2, 0
    li s3, 0

    la a0, buffer
    li t0, 1
    slli t0, t0, 63
    or a1, a0, t0
    li t0, 1
    slli t0, t0, 40
    or a2, a0, t0

    expect_fault 5, ld t1, 0(a1)
    expect_fault 7, sd t1, 0(a1)
    expect_fault 5, ld t1, 0(a2)
    j pass

.align 2
trap:
    csrr t0, mcause
    bne t0, s4, fail
    csrr t0, mepc
    bne t0, s1, fail
    csrr t0, mtval
    srli t0, t0, 40
    beqz t0, fail
    csrr t0, mepc
    addi t0, t0, 4
    csrw mepc, t0
    addi s3, s3, 1
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

.section .data
.balign 8
buffer:
    .dword 0
