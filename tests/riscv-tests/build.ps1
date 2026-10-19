# Build the official RISC-V rv32ui tests into hex files the CPU can load.
# Usage (from anywhere):  .\tests\riscv-tests\build.ps1
# Output: tests\riscv-tests\hex\<test>.hex, one per test in isa\rv32ui

# Toolchain location: change this if GCC is moved.
$rv   = 'C:\Engineering Software\xpack-riscv-none-elf-gcc-15.2.0-1\bin\riscv-none-elf-'
$here = $PSScriptRoot
$failed = 0

New-Item -ItemType Directory -Force "$here\hex" | Out-Null

foreach ($src in Get-ChildItem "$here\isa\rv32ui\*.S") {
    $elf = "$here\hex\$($src.BaseName).elf"
    $hex = "$here\hex\$($src.BaseName).hex"

    # .S files go through the C preprocessor first, which expands the test macros.
    # -I tells it where riscv_test.h (ours) and test_macros.h (official) are.
    # -T uses our memory layout. The -Wl option silences a linker warning about
    # code and data sharing one region, which is how this CPU's tests are laid out.
    & "${rv}gcc.exe" -march=rv32i -mabi=ilp32 -nostdlib -nostartfiles `
        -T "$here\env\link.ld" -I "$here\env" -I "$here\isa\macros\scalar" `
        '-Wl,--no-warn-rwx-segments' -o $elf $src.FullName
    if ($LASTEXITCODE -ne 0) { Write-Host "FAILED to build $($src.Name)"; $failed++; continue }

    & "${rv}objcopy.exe" -O verilog --verilog-data-width=4 $elf $hex
    if ($LASTEXITCODE -ne 0) { Write-Host "FAILED to convert $($src.Name)"; $failed++ }
    Remove-Item $elf
}

$count = (Get-ChildItem "$here\hex\*.hex").Count
Write-Host "Built $count tests, $failed failed"
if ($failed -ne 0) { exit 1 }
