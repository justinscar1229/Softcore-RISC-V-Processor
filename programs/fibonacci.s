# fibonacci.s: store the first 12 Fibonacci numbers in data memory
# (0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89 at addresses 0, 4, 8, ... 44),
# then halt. Checked by fibonacci_tb.sv.
# Build:  .\programs\build.ps1 programs\fibonacci.s

    .text
    .globl _start
_start:
    li    x1, 0                 # a = 0
    li    x2, 1                 # b = 1
    li    x3, 0                 # address = 0
    li    x4, 12                # count = 12
loop:
    sw    x1, 0(x3)             # mem[address] = a
    add   x5, x1, x2            # next = a + b
    mv    x1, x2                # a = b
    mv    x2, x5                # b = next
    addi  x3, x3, 4             # address += 4
    addi  x4, x4, -1            # count -= 1
    bnez  x4, loop              # repeat until count is 0
done:
    j     done                  # halt: jump to itself forever
