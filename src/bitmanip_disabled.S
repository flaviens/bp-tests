.section .text
.globl main

# For configurations without bitmanip support (the default): misa.B is clear
# and Zba/Zbb/Zbs instructions raise an illegal-instruction exception.
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
    li s2, 0
    li s3, 0

    csrr t0, misa
    andi t0, t0, 1 << 1
    bnez t0, fail

.option push
.option arch, +zba, +zbb, +zbs
    expect_illegal add.uw a0, a1, a2
    expect_illegal sh1add a0, a1, a2
    expect_illegal sh3add.uw a0, a1, a2
    expect_illegal slli.uw a0, a1, 3
    expect_illegal andn a0, a1, a2
    expect_illegal clz a0, a1
    expect_illegal cpopw a0, a1
    expect_illegal max a0, a1, a2
    expect_illegal sext.b a0, a1
    expect_illegal zext.h a0, a1
    expect_illegal rol a0, a1, a2
    expect_illegal roriw a0, a1, 3
    expect_illegal orc.b a0, a1
    expect_illegal rev8 a0, a1
    expect_illegal bclr a0, a1, a2
    expect_illegal bexti a0, a1, 3
    expect_illegal binv a0, a1, a2
    expect_illegal bseti a0, a1, 3
.option pop

    j pass

.align 2
trap:
    csrr t0, mcause
    li t1, 2
    bne t0, t1, fail
    csrr t0, mepc
    bne t0, s1, fail
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
