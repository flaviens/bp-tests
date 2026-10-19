.section .text
.globl main

# With FS=Off, c.fld fa0, 8(a0) (0x2508) is illegal. mtval must hold the
# 16-bit instruction, not its 32-bit expansion.
.macro expect_illegal_cfld
    la s1, 1f
    addi s2, s2, 1
1:
    .hword 0x2508
    bne s2, s3, fail
.endm

main:
    la t0, trap
    csrw mtvec, t0
    li t0, 3 << 13
    csrc mstatus, t0
    la a0, value
    li s2, 0
    li s3, 0

    .balign 4
    expect_illegal_cfld
    .balign 4
    c.nop
    expect_illegal_cfld
    j pass

.align 2
trap:
    csrr t0, mcause
    li t1, 2
    bne t0, t1, fail
    csrr t0, mepc
    bne t0, s1, fail
    csrr t0, mtval
    li t1, 0x2508
    bne t0, t1, fail
    csrr t0, mepc
    addi t0, t0, 2
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
value:
    .dword 0
    .dword 0
