# Assemble a RISC-V program into a hex file the CPU can load with $readmemh.
# Usage (from the project folder):  .\programs\build.ps1 programs\fibonacci.s
# Output: the same name with .hex (programs\fibonacci.hex)

param([Parameter(Mandatory)] [string] $Source)

# Toolchain location: change this if GCC is moved.
$rv  = 'C:\Engineering Software\xpack-riscv-none-elf-gcc-15.2.0-1\bin\riscv-none-elf-'
$elf = [IO.Path]::ChangeExtension($Source, '.elf')
$hex = [IO.Path]::ChangeExtension($Source, '.hex')

# Assemble and link. rv32i = base integer instructions only, placed at address 0,
# with no C library or startup code.
& "${rv}gcc.exe" -march=rv32i -mabi=ilp32 -nostdlib -Ttext=0 -o $elf $Source
if ($LASTEXITCODE -ne 0) { exit 1 }

# Convert to hex: one 32-bit word (one instruction) per entry.
& "${rv}objcopy.exe" -O verilog --verilog-data-width=4 $elf $hex
$ok = ($LASTEXITCODE -eq 0)
Remove-Item $elf
if (-not $ok) { exit 1 }

Write-Host "Built $hex"
