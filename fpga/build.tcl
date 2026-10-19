# build.tcl: build the CPU for the ZedBoard with Vivado (non-project mode).
# Run it through build.ps1. Argument: the program to put in instruction
# memory, a name from programs\ (default: led_counter).
# Output in fpga\build\: fpga_top.bit, utilization.txt, timing.txt

set program [expr {[llength $argv] > 0 ? [lindex $argv 0] : "led_counter"}]
set root    [file normalize [file join [file dirname [info script]] ..]]
set out     [file join $root fpga build]
set part    xc7z020clg484-1
set hex     [file join $root programs $program.hex]

if {![file exists $hex]} {
    puts "ERROR: $hex not found. Build it first with programs\\build.ps1"
    exit 1
}
file mkdir $out
cd $out

# ---------------- Sources ----------------
# The same design files the simulations use, plus the board files.
read_verilog -sv [list \
    $root/riscv_pkg.sv \
    $root/alu.sv \
    $root/register_file.sv \
    $root/program_counter.sv \
    $root/instruction_memory.sv \
    $root/instruction_fetch.sv \
    $root/instruction_decoder.sv \
    $root/immediate_generator.sv \
    $root/control_unit.sv \
    $root/data_memory.sv \
    $root/branch_unit.sv \
    $root/cpu.sv \
    $root/fpga/clock_gen.sv \
    $root/fpga/fpga_top.sv ]
read_xdc $root/fpga/zedboard.xdc

# ---------------- Synthesis ----------------
# Turns the SystemVerilog into the chip's building blocks (LUTs, flip-flops).
# The program's hex file is passed in as the PROGRAM parameter.
synth_design -top fpga_top -part $part -generic "PROGRAM=\"$hex\""

# ---------------- Implementation ----------------
# Optimize, place every block on the chip, then route the wires between them.
opt_design
place_design
route_design

# ---------------- Reports and bitstream ----------------
report_utilization    -file $out/utilization.txt
report_timing_summary -file $out/timing.txt
write_bitstream -force $out/fpga_top.bit

set wns [get_property SLACK [get_timing_paths -delay_type max]]
puts ""
puts "Program:     $program"
puts "Worst slack: $wns ns (must be >= 0)"
if {$wns < 0} {
    puts "TIMING FAILED: the design is too slow for its clock. See fpga\\build\\timing.txt"
} else {
    puts "Timing met. Bitstream: $out/fpga_top.bit"
}
