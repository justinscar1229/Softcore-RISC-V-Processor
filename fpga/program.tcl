# program.tcl: load fpga\build\fpga_top.bit onto the ZedBoard over JTAG.
# Run it through program.ps1, with the board's PROG USB port connected.

set root [file normalize [file join [file dirname [info script]] ..]]
set bit  [file join $root fpga build fpga_top.bit]

open_hw_manager
connect_hw_server
open_hw_target

# The JTAG chain also has the ARM debug port; pick the FPGA (xc7z020).
set device [lindex [get_hw_devices xc7z020*] 0]
current_hw_device $device
set_property PROGRAM.FILE $bit $device
program_hw_devices $device

close_hw_target
disconnect_hw_server
close_hw_manager
puts "Programmed $bit"
