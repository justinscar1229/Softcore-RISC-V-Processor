`timescale 1ns/1ps

module immediate_generator_tb;
    reg  [31:0] instruction;
    wire [31:0] immediate;

    immediate_generator dut (
        .instruction(instruction),
        .immediate(immediate)
    );

    initial begin
        // addi x1, x0, 10  (small positive value)
        instruction = 32'h00A00093;
        #10;
        if (immediate !== 32'h0000000A)
            $fatal(1, "Positive immediate failed");

        // addi x2, x0, -3  (negative: the sign bit fills the upper 20 bits)
        instruction = 32'hFFD00113;
        #10;
        if (immediate !== 32'hFFFFFFFD)
            $fatal(1, "Negative immediate failed");

        // addi x3, x0, 2047  (largest positive 12-bit value)
        instruction = 32'h7FF00193;
        #10;
        if (immediate !== 32'h000007FF)
            $fatal(1, "Maximum immediate failed");

        // addi x4, x0, -2048  (most negative 12-bit value)
        instruction = 32'h80000213;
        #10;
        if (immediate !== 32'hFFFFF800)
            $fatal(1, "Minimum immediate failed");

        // addi x31, x31, 1  (all-ones register fields must not leak in)
        instruction = 32'h001F8F93;
        #10;
        if (immediate !== 32'h00000001)
            $fatal(1, "Field isolation failed");

        $display("All immediate generator tests passed!");
        $finish;
    end
endmodule
