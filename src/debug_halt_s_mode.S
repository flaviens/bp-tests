.option norvc

.section .text.init
.globl _start
_start:
    j entry
    j fail
    j fail
    nop

entry:
    la t0, debug_entered
    ld t1, 0(t0)
    bnez t1, debug_main

    li t1, 1
    sd t1, 0(t0)
    fence rw, rw

    la t0, fail
    csrw mtvec, t0

    csrr t0, mstatus
    li t1, 3 << 11
    not t1, t1
    and t0, t0, t1
    li t1, 1 << 11
    or t0, t0, t1
    csrw mstatus, t0
    la t0, supervisor_mode
    csrw mepc, t0
    mret

supervisor_mode:
    # Raise the local debug interrupt from S-mode. Debug entry returns to _start.
    li t0, 0x0030d000
    li t1, 1
    sd t1, 0(t0)
1:
    j 1b

debug_main:
    li t0, 0x0030d000
    sd zero, 0(t0)

    # Debug Mode runs at M privilege, so debug and M-mode CSRs must not raise
    # a debug exception.
    li t0, 0x5a5a
    csrw dscratch0, t0
    csrr t1, dscratch0
    bne t0, t1, fail
    csrr t0, dcsr
    csrr t0, mstatus

pass:
    li t0, 0x00102000
    sw zero, 0(t0)
2:
    wfi
    j 2b

.align 2
fail:
    li t0, 0x00102000
    li t1, 1
    sw t1, 0(t0)
3:
    wfi
    j 3b

.section .data
.balign 8
debug_entered:
    .dword 0
