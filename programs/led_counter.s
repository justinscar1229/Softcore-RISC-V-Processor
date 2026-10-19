# led_counter.s: count up in x10, about 4 times per second at 25 MHz.
# On the board: SW[4:0] = 01010 (x10), SW[6:5] = 00 (low byte), SW7 = 1 (full speed).
# Build:  .\programs\build.ps1 programs\led_counter.s

    .text
    .globl _start
_start:
    li    x10, 0                # count = 0
next:
    addi  x10, x10, 1           # count += 1
    li    x5, 3125000           # delay: 3,125,000 loops x 2 instructions
delay:                          #        = 6,250,000 cycles = 0.25 s at 25 MHz
    addi  x5, x5, -1
    bnez  x5, delay
    j     next
