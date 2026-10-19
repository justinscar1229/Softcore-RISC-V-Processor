# Run every built rv32ui test on the CPU and print a summary.
# Usage (from anywhere):  .\tests\riscv-tests\run.ps1
# Build the hex files first with .\tests\riscv-tests\build.ps1

$iv   = 'C:\Engineering Software\iverilog\bin\iverilog.exe'
$vvp  = 'C:\Engineering Software\iverilog\bin\vvp.exe'
$here = $PSScriptRoot
$root = Resolve-Path "$here\..\.."

Push-Location $root
try {
    # Compile once. Each test is then a run with a different +hex file.
    & $iv -g2012 -s riscv_tests_tb -o riscv_tests_sim riscv_pkg.sv alu.sv register_file.sv `
        program_counter.sv instruction_memory.sv instruction_fetch.sv instruction_decoder.sv `
        immediate_generator.sv control_unit.sv data_memory.sv branch_unit.sv cpu.sv riscv_tests_tb.sv
    if ($LASTEXITCODE -ne 0) { Write-Host "Compile failed"; exit 1 }

    $passed = 0
    $failed = @()
    foreach ($hex in Get-ChildItem "$here\hex\*.hex" | Sort-Object Name) {
        $out = & $vvp -n riscv_tests_sim "+hex=tests/riscv-tests/hex/$($hex.Name)" | Out-String
        $line = ($out -split "`n" | Where-Object { $_ -match 'PASS|FAIL|TIMEOUT|ERROR|MISALIGNED|X ' } | Select-Object -First 1)
        if ($out -match 'PASS ') {
            $passed++
            Write-Host ("PASS  {0,-7} {1}" -f $hex.BaseName, ($line -replace '.*\(', '(').Trim())
        } else {
            $failed += $hex.BaseName
            Write-Host ("FAIL  {0,-7} {1}" -f $hex.BaseName, "$line".Trim())
        }
    }

    Write-Host ""
    Write-Host "$passed passed, $($failed.Count) failed"
    if ($failed.Count -ne 0) { Write-Host "Failed: $($failed -join ', ')"; exit 1 }
}
finally {
    Pop-Location
}
