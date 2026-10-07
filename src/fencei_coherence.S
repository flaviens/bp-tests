.section .text
.globl main

# Disable compressed instructions to ensure predictable 4-byte instruction widths
.option norvc

main:
    # Load the address of the target instruction we want to overwrite
    la t1, target_inst

    # Load the new instruction ("li t3, 1") into t2
    la t0, payload_inst
    lw t2, 0(t0)

    # Initialize our verification register to 0 (failure state)
    li t3, 0

    # Overwrite the target instruction (initially a 'nop')
    sw t2, 0(t1)

    # Flush the instruction cache to ensure the core sees the modified memory
    fence.i

    # Immediately execute target
    jalr t1
    .balign 256
    .skip 128               # <-- forces target_inst to a different 64B line, cache index >=2

.align 2
target_inst:
    # This instruction is overwritten by "li t3, 1" before execution.
    # If fence.i fails and the core executes stale i-cache data, t3 remains 0.
    nop

    # Verify if the new instruction executed successfully
    li t4, 1
    beq t3, t4, pass
    j fail

.align 2
payload_inst:
    # The payload instruction we copy to target_inst
    li t3, 1

pass:
    li t0, 0x00102000
    sw zero, 0(t0)
1:
    wfi
    j 1b

fail:
    li t0, 0x00102000
    li t1, 1
