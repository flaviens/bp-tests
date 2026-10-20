.section .text
.globl main

# Jumps to a target whose upper bits are not a sign extension of the 39-bit
# virtual address fault on the fetch: an access fault in M-mode bare, an
# instruction page fault in Sv39. They must not execute the code at the valid
# alias in the low bits. mepc and mtval may hold the target or another invalid
# address, but never the alias.
.macro expect_fetch_fault cause, bit
    la a0, landing
    li t0, 1
    slli t0, t0, \bit
    or a1, a0, t0
    li s4, \cause
    la s1, 1f
    addi s2, s2, 1
    li t2, 0
    jalr t2, 0(a1)
1:
    bne s2, s3, fail
.endm

.macro check_invalid csr
    csrr t0, \csr
    # the low bits of the target are kept
    xor t1, t0, a1
    slli t1, t1, 26
    bnez t1, fail
    # bits 63:38 are not all equal: not a canonical Sv39 address
    srai t1, t0, 38
    beqz t1, fail
    addi t1, t1, 1
    beqz t1, fail
    # in bare mode, bits 63:40 are not all zero: not a physical address
    beqz s5, 2f
    srli t1, t0, 40
    beqz t1, fail
2:
.endm

main:
    la t0, trap
    csrw mtvec, t0
    li s2, 0
    li s3, 0

    # M-mode, bare
    li s5, 1
    expect_fetch_fault 1, 63
    expect_fetch_fault 1, 40

    # S-mode, Sv39 with an identity gigapage at 0x80000000
    la t1, root_page_table
    li t0, 0x200000cf
    sd t0, 16(t1)
    srli t0, t1, 12
    li t1, 8
    slli t1, t1, 60
    or t0, t0, t1
    csrw satp, t0
    sfence.vma
    li t0, 3 << 11
    csrc mstatus, t0
    li t0, 1 << 11
    csrs mstatus, t0
    la t0, supervisor_mode
    csrw mepc, t0
    li s5, 0
    mret

supervisor_mode:
    expect_fetch_fault 12, 63
    expect_fetch_fault 12, 39
    ecall

.align 2
trap:
    csrr t0, mcause
    li t1, 9
    beq t0, t1, done
    bne t0, s4, fail
    # the jump itself retired
    bne t2, s1, fail
    check_invalid mepc
    check_invalid mtval
    csrw mepc, s1
    addi s3, s3, 1
    mret

done:
    li t0, 4
    bne s3, t0, fail

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

# Reached only through the alias of a faulting jump
.align 2
landing:
    j fail

.section .data
.balign 4096
root_page_table:
    .zero 4096
