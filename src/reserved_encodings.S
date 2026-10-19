.section .text
.globl main

# Each instruction must raise an illegal-instruction exception at its own pc.
.macro expect_illegal insn:vararg
    la s1, 1f
    addi s2, s2, 1
1:
    \insn
    bne s2, s3, fail
.endm

main:
    la t0, trap
    csrw mtvec, t0
    li t0, 1 << 13
    csrs mstatus, t0
    li s2, 0
    li s3, 0

    # FMADD/FMSUB/FNMSUB/FNMADD with fmt=H or Q (Zfh and Q are not implemented)
    expect_illegal .insn r4 0x43, 0, 2, f0, f1, f2, f3
    expect_illegal .insn r4 0x43, 0, 3, f0, f1, f2, f3
    expect_illegal .insn r4 0x47, 0, 3, f0, f1, f2, f3
    expect_illegal .insn r4 0x4b, 0, 2, f0, f1, f2, f3
    expect_illegal .insn r4 0x4f, 0, 3, f0, f1, f2, f3

    # packw (Zbkb), which shares the zext.h encoding except for rs2
    expect_illegal .insn r 0x3b, 4, 0x04, a0, a1, a2

    # slliw/srliw/sraiw with imm[5]=1
    expect_illegal .insn r 0x1b, 1, 0x01, a0, a1, x0
    expect_illegal .insn r 0x1b, 5, 0x01, a0, a1, x0
    expect_illegal .insn r 0x1b, 5, 0x21, a0, a1, x0

    # c.jr x0 and c.addiw x0
    expect_illegal .hword 0x8002
    expect_illegal .hword 0x2005

    j pass

.align 2
trap:
    csrr t0, mcause
    li t1, 2
    bne t0, t1, fail
    csrr t0, mepc
    bne t0, s1, fail
    lhu t1, 0(t0)
    andi t1, t1, 3
    li t2, 3
    addi t0, t0, 2
    bne t1, t2, 1f
    addi t0, t0, 2
1:
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
