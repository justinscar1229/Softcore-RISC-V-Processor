# Build the FPGA bitstream for the ZedBoard.
# Usage (from anywhere):  .\fpga\build.ps1 [program]     e.g.  .\fpga\build.ps1 led_counter
# Takes a few minutes. Output and logs: fpga\build\

param([string] $Program = 'led_counter')

$vivado = 'C:\Xilinx\Vivado\2023.2\bin\vivado.bat'
$build  = Join-Path $PSScriptRoot 'build'
New-Item -ItemType Directory -Force $build | Out-Null

& $vivado -mode batch -nojournal -log "$build\vivado.log" `
    -source "$PSScriptRoot\build.tcl" -tclargs $Program
