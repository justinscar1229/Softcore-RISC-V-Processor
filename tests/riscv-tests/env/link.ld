/* link.ld: memory layout for the riscv-tests on this CPU.
   Code starts at address 0, where the PC resets, and data follows it.
   The testbench loads the same image into instruction memory and data
   memory, so the data addresses a test computes (with la) find its data. */

OUTPUT_ARCH("riscv")
ENTRY(_start)

SECTIONS
{
    . = 0x0;
    .text : { *(.text.init) *(.text) }
    . = ALIGN(16);
    .data : { *(.data) }
    .bss  : { *(.bss) }
}
