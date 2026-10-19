.section .text
.globl main

main:
    la t0, trap
    csrw mtvec, t0
    li t0, 1 << 13
    csrs mstatus, t0
    li t2, 0x10

    # fcvt.d.s of a single-precision signaling NaN raises NV.
    li t0, 0x7f800001
    fmv.w.x f0, t0
    csrw fflags, zero
    fcvt.d.s f1, f0
    csrr t1, fflags
    bne t1, t2, fail

    # fcvt.s.d of a double-precision signaling NaN raises NV.
    li t0, 0x7ff0000000000001
    fmv.d.x f0, t0
    csrw fflags, zero
    fcvt.s.d f1, f0
    csrr t1, fflags
    bne t1, t2, fail
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
