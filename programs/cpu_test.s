# cpu_test.s: the main CPU test program, checked by cpu_tb.sv.
# Build:  .\programs\build.ps1 programs\cpu_test.s   (writes programs\cpu_test.hex)

    .text
    .globl _start
_start:
    # Arithmetic and logic
    addi  x1, x0, 10
    addi  x2, x0, 3
    add   x3, x1, x2
    sub   x4, x1, x2
    and   x5, x1, x2
    or    x6, x1, x2
    sub   x7, x2, x1
    addi  x8, x7, -1
    andi  x9, x8, 255
    ori   x10, x2, 12
    add   x0, x1, x1            # writes to x0 are ignored
    add   x11, x0, x3

    # XOR, shifts, and comparisons
    xor   x12, x1, x2
    sll   x13, x1, x2
    srl   x14, x7, x2
    sra   x15, x7, x2
    slt   x16, x7, x1
    sltu  x17, x7, x1
    slti  x18, x2, 5
    sltiu x19, x2, -1
    xori  x20, x1, -1
    slli  x21, x2, 4
    srli  x22, x8, 28
    srai  x23, x8, 1

    # Word loads and stores
    sw    x3, 0(x0)
    sw    x7, 4(x0)
    sw    x20, -4(x21)
    lw    x24, 0(x0)
    lw    x25, 4(x0)
    lw    x26, 44(x0)
    add   x27, x24, x25
    sw    x27, 0(x21)
    lw    x28, 48(x0)

    # Byte and halfword loads and stores
    sw    x0, 52(x0)
    sb    x9, 52(x0)
    sb    x13, 53(x0)
    sh    x20, 54(x0)
    lw    x29, 52(x0)
    lb    x30, 52(x0)
    lbu   x31, 52(x0)
    lb    x5, 53(x0)
    lh    x6, 54(x0)
    lhu   x7, 54(x0)
    lh    x8, 52(x0)

    # A loop: sum of 1..10 into x10
    addi  x10, x0, 0            # sum = 0
    addi  x11, x0, 1            # i = 1
    addi  x12, x0, 11           # limit = 11
sum_loop:
    add   x10, x10, x11         # sum += i
    addi  x11, x11, 1           # i++
    blt   x11, x12, sum_loop    # repeat while i < 11

    # Every branch type. Each branch jumps to the label just past the addi after it.
    # x30 counts taken branches that wrongly fell through (should stay 0).
    # x31 counts not-taken branches that correctly fell through (should reach 6).
    addi  x30, x0, 0
    addi  x31, x0, 0
    beq   x1, x1, b1            # taken
    addi  x30, x30, 1
b1: beq   x1, x2, b2            # not taken
    addi  x31, x31, 1
b2: bne   x1, x2, b3            # taken
    addi  x30, x30, 1
b3: bne   x1, x1, b4            # not taken
    addi  x31, x31, 1
b4: blt   x6, x1, b5            # taken (-11 < 10)
    addi  x30, x30, 1
b5: blt   x1, x6, b6            # not taken
    addi  x31, x31, 1
b6: bge   x1, x6, b7            # taken (10 >= -11)
    addi  x30, x30, 1
b7: bge   x1, x1, b8            # taken (equal)
    addi  x30, x30, 1
b8: bge   x6, x1, b9            # not taken
    addi  x31, x31, 1
b9: bltu  x1, x6, b10           # taken (FFFFFFF5 is huge unsigned)
    addi  x30, x30, 1
b10: bltu x6, x1, b11           # not taken
    addi  x31, x31, 1
b11: bgeu x6, x1, b12           # taken
    addi  x30, x30, 1
b12: bgeu x2, x1, b13           # not taken (3 < 10)
    addi  x31, x31, 1
b13:

    # Upper immediates
    lui   x5, 0x12345           # x5 = 12345000
    addi  x5, x5, 0x678         # x5 = 12345678
    auipc x6, 0x1               # x6 = this address + 4096
    auipc x7, 0                 # x7 = this address

    # A function call with jal and jalr
    addi  x10, x0, 5            # argument = 5
    jal   x1, double            # call: x1 = return address
    addi  x11, x10, 0           # x11 = result
    jal   x0, after_double      # jump over the function
double:
    add   x10, x10, x10         # x10 = x10 * 2
    jalr  x0, 0(x1)             # return
after_double:
    addi  x12, x0, 1            # marker: got here
    jalr  x13, 29(x1)           # go to (x1 + 29) with bit 0 cleared
    addi  x15, x0, 99           # must be skipped
    addi  x14, x0, 7            # jalr lands here
    lui   x16, 0xFFFFF          # x16 = FFFFF000
