`timescale 1ns/1ps

module instruction_fetch_tb;
    logic clk;
    logic reset;
    logic enable;
    logic [31:0] pc;
    logic [31:0] instruction;

    instruction_fetch #(.PROGRAM("programs/cpu_test.hex")) dut (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .load(1'b0),         // no branches in this test
        .target(32'd0),
        .pc(pc),
        .instruction(instruction)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        reset = 1;
        enable = 0;

        // Reset selects the first word.
        @(posedge clk);
        #1;
        if (pc !== 32'd0 || instruction !== 32'h00A00093)
            $fatal(1, "Reset fetch failed");

        // Start advancing through memory.
        @(negedge clk);
        reset = 0;
        enable = 1;

        @(posedge clk);
        #1;
        if (pc !== 32'd4 || instruction !== 32'h00300113)
            $fatal(1, "Fetch at address 4 failed");

        @(posedge clk);
        #1;
        if (pc !== 32'd8 || instruction !== 32'h002081B3)
            $fatal(1, "Fetch at address 8 failed");

        // Pause: both address and word must stay unchanged.
        @(negedge clk);
        enable = 0;

        @(posedge clk);
        #1;
        if (pc !== 32'd8 || instruction !== 32'h002081B3)
            $fatal(1, "Fetch hold failed");

        // Resume advancing.
        @(negedge clk);
        enable = 1;

        @(posedge clk);
        #1;
        if (pc !== 32'd12 || instruction !== 32'h40208233)
            $fatal(1, "Fetch resume failed");

        // Address 16 holds the program's fifth instruction.
        @(posedge clk);
        #1;
        if (pc !== 32'd16 || instruction !== 32'h0020F2B3)
            $fatal(1, "Fetch at address 16 failed");

        // Reset while enabled: return to the first word.
        @(negedge clk);
        reset = 1;

        @(posedge clk);
        #1;
        if (pc !== 32'd0 || instruction !== 32'h00A00093)
            $fatal(1, "Fetch restart failed");

        $display("All instruction fetch tests passed!");
        $finish;
    end
endmodule
