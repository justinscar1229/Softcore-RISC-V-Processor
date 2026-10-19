# Load the built bitstream onto the ZedBoard.
# Usage (from anywhere):  .\fpga\program.ps1
# Connect the board's PROG micro-USB port and switch the board on first.

$vivado = 'C:\Xilinx\Vivado\2023.2\bin\vivado.bat'
$build  = Join-Path $PSScriptRoot 'build'
New-Item -ItemType Directory -Force $build | Out-Null

& $vivado -mode batch -nojournal -log "$build\program.log" `
    -source "$PSScriptRoot\program.tcl"
