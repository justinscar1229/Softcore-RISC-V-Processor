`timescale 1ns/1ps

// Runs one official riscv-tests program on the CPU.
// Usage: vvp riscv_tests_sim +hex=tests/riscv-tests/hex/add.hex
// tests\riscv-tests\run.ps1 runs every test this way.
module riscv_tests_tb;
    logic        clk;
    logic        reset;
    logic [31:0] pc;
    logic [31:0] instruction;

    // PROGRAM("") = instruction memory starts empty; this testbench loads it.
    cpu #(.PROGRAM("")) dut (
        .clk(clk),
        .reset(reset),
        .enable(1'b1),
        .pc(pc),
        .instruction(instruction),
        .debug_reg(5'd0),
        .debug_value()
    );

    initial clk = 0;
    always #5 clk = ~clk;

    // Every test ends in "j ." (jal x0, 0), a jump to itself.
    localparam logic [31:0] HALT       = 32'h0000006F;
    localparam int          MAX_CYCLES = 10000;

    string hex;   // the test's hex file, from +hex=<file>

    // Checks on every cycle. Without them, some bugs slip through:
    // - An unknown (x) value usually means something read memory that was
    //   never loaded. A branch on x acts as "not taken", so a test could skip
    //   its jump to the failure code and still report a pass.
    // - Instructions are 4 bytes, so the PC must always be a multiple of 4.
    always @(posedge clk) begin
        if (!reset) begin
            if (dut.reg_write && dut.rd != 5'd0 && $isunknown(dut.write_back))
                $fatal(1, "X %s: unknown value written to x%0d at pc=%0d", hex, dut.rd, pc);
            if ($isunknown(dut.take_jump))
                $fatal(1, "X %s: unknown branch decision at pc=%0d", hex, pc);
            if (pc[1:0] != 2'b00)
                $fatal(1, "MISALIGNED %s: pc=%0d is not a multiple of 4", hex, pc);
        end
    end

    initial begin
        int          cycles;
        logic [31:0] result;

        // The test to run comes from the command line: +hex=<file>
        if (!$value$plusargs("hex=%s", hex))
            $fatal(1, "No test given. Run with +hex=<file>");

        reset = 1;

        // Backdoor load: put the test image straight into both memories.
        // Code and data share one image, so data memory gets a copy too.
        // Wait 1 ns first, so instruction memory has finished clearing itself.
        #1;
        $readmemh(hex, dut.fetch.memory.mem);
        $readmemh(hex, dut.dmem.mem);

        repeat (3) @(posedge clk);
        @(negedge clk);
        reset = 0;

        // Run until the halt loop (give up after MAX_CYCLES).
        cycles = 0;
        while (instruction !== HALT) begin
            @(posedge clk);
            #1;
            cycles++;
            if (cycles > MAX_CYCLES)
                $fatal(1, "TIMEOUT %s: no halt after %0d cycles (pc = %0d)", hex, MAX_CYCLES, pc);
        end

        // The test leaves its result in gp (x3): 1 = pass,
        // otherwise (failing test number << 1) | 1.
        result = dut.registers.regs[3];
        if (result !== 32'd1)
            $fatal(1, "FAIL %s: test %0d failed (gp = %h, pc = %0d)", hex, result >> 1, result, pc);

        $display("PASS %s (%0d cycles)", hex, cycles);
        $finish;
    end
endmodule
