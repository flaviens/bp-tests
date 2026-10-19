.section .text
.globl main

# VA 0x40000000 maps gadget_page (R/X). VA 0x40001000 is invalid.
#   test 1: a 32-bit instruction at 0x40000ffe faults on its second half:
#           mepc = 0x40000ffe, mtval = 0x40001000
#   test 2: an instruction at 0x40001000 faults on its first half:
#           mepc = mtval = 0x40001000
main:
    la t0, trap
    csrw mtvec, t0

    la t1, root_page_table
    la t0, l1_page_table
    srli t0, t0, 12
    slli t0, t0, 10
    ori t0, t0, 0x1
    sd t0, 8(t1)
    li t0, 0x200000cf
    sd t0, 16(t1)

    la t1, l1_page_table
    la t0, l0_page_table
    srli t0, t0, 12
    slli t0, t0, 10
    ori t0, t0, 0x1
    sd t0, 0(t1)

    la t1, l0_page_table
    la t0, gadget_page
    srli t0, t0, 12
    slli t0, t0, 10
    ori t0, t0, 0x4b
    sd t0, 0(t1)

    la t0, root_page_table
    srli t0, t0, 12
    li t1, 8
    slli t1, t1, 60
    or t0, t0, t1
    csrw satp, t0
    sfence.vma

    csrr t0, mstatus
    li t1, 3 << 11
    not t1, t1
    and t0, t0, t1
    li t1, 1 << 11
    or t0, t0, t1
    csrw mstatus, t0
    la t0, supervisor_mode
    csrw mepc, t0
    li s0, 0
    mret

supervisor_mode:
    li t0, 0x40000ffe
    jr t0
supervisor_mode_2:
    li t0, 0x40001000
    jr t0

.align 2
trap:
    csrr t0, mcause
    li t1, 12
    bne t0, t1, fail
    bnez s0, 1f

    csrr t0, mepc
    li t1, 0x40000ffe
    bne t0, t1, fail
    csrr t0, mtval
    li t1, 0x40001000
    bne t0, t1, fail
    li s0, 1
    la t0, supervisor_mode_2
    csrw mepc, t0
    mret

1:
    csrr t0, mepc
    li t1, 0x40001000
    bne t0, t1, fail
    csrr t0, mtval
    bne t0, t1, fail

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
.balign 4096
root_page_table:
    .zero 4096
l1_page_table:
    .zero 4096
l0_page_table:
    .zero 4096
gadget_page:
    .zero 4094
    # Lower half of a 32-bit addi.
    .hword 0x0013
