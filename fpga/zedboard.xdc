## zedboard.xdc: pins and clock for fpga_top on the ZedBoard.
## Pin numbers and voltages are from Digilent's Zedboard-Master.xdc.

## 100 MHz oscillator (bank 13, fixed at 3.3 V)
set_property -dict {PACKAGE_PIN Y9 IOSTANDARD LVCMOS33} [get_ports GCLK]
create_clock -name gclk -period 10.000 [get_ports GCLK]

## LEDs LD0-LD7 (bank 33, fixed at 3.3 V)
set_property -dict {PACKAGE_PIN T22 IOSTANDARD LVCMOS33} [get_ports {LD[0]}]
set_property -dict {PACKAGE_PIN T21 IOSTANDARD LVCMOS33} [get_ports {LD[1]}]
set_property -dict {PACKAGE_PIN U22 IOSTANDARD LVCMOS33} [get_ports {LD[2]}]
set_property -dict {PACKAGE_PIN U21 IOSTANDARD LVCMOS33} [get_ports {LD[3]}]
set_property -dict {PACKAGE_PIN V22 IOSTANDARD LVCMOS33} [get_ports {LD[4]}]
set_property -dict {PACKAGE_PIN W22 IOSTANDARD LVCMOS33} [get_ports {LD[5]}]
set_property -dict {PACKAGE_PIN U19 IOSTANDARD LVCMOS33} [get_ports {LD[6]}]
set_property -dict {PACKAGE_PIN U14 IOSTANDARD LVCMOS33} [get_ports {LD[7]}]

## Switches SW0-SW7 (bank 35) and the center button BTNC (bank 34).
## These banks run at the VADJ voltage chosen by jumper J18: 1.8 V by default.
## If J18 is set to 2.5 V or 3.3 V, change LVCMOS18 to LVCMOS25 or LVCMOS33.
set_property -dict {PACKAGE_PIN F22 IOSTANDARD LVCMOS18} [get_ports {SW[0]}]
set_property -dict {PACKAGE_PIN G22 IOSTANDARD LVCMOS18} [get_ports {SW[1]}]
set_property -dict {PACKAGE_PIN H22 IOSTANDARD LVCMOS18} [get_ports {SW[2]}]
set_property -dict {PACKAGE_PIN F21 IOSTANDARD LVCMOS18} [get_ports {SW[3]}]
set_property -dict {PACKAGE_PIN H19 IOSTANDARD LVCMOS18} [get_ports {SW[4]}]
set_property -dict {PACKAGE_PIN H18 IOSTANDARD LVCMOS18} [get_ports {SW[5]}]
set_property -dict {PACKAGE_PIN H17 IOSTANDARD LVCMOS18} [get_ports {SW[6]}]
set_property -dict {PACKAGE_PIN M15 IOSTANDARD LVCMOS18} [get_ports {SW[7]}]
set_property -dict {PACKAGE_PIN P16 IOSTANDARD LVCMOS18} [get_ports BTNC]

## The switches, button, and LEDs aren't in step with the clock, and humans
## are slow: the inputs go through synchronizers, so don't time these paths.
set_false_path -from [get_ports {SW[*] BTNC}]
set_false_path -to [get_ports {LD[*]}]
