`timescale 1ns/1ps

module alu_tb;
    reg  [31:0] a, b;
    reg  [1:0]  alu_op;
    wire [31:0] result;

    alu dut (
        .a(a),
        .b(b),
        .alu_op(alu_op),
        .result(result)
    );

    initial begin
        $dumpfile("alu.vcd");
        $dumpvars(0, alu_tb);

        a = 32'd10;
        b = 32'd3;

        alu_op = 2'b00;
        #10;
        if (result !== 32'd13) $fatal(1, "ADD failed");

        alu_op = 2'b01;
        #10;
        if (result !== 32'd7) $fatal(1, "SUB failed");

        alu_op = 2'b10;
        #10;
        if (result !== 32'd2) $fatal(1, "AND failed");

        alu_op = 2'b11;
        #10;
        if (result !== 32'd11) $fatal(1, "OR failed");


        // Largest unsigned 32-bit value + 1
        a = 32'hFFFFFFFF;
        b = 32'd1;
        alu_op = 2'b00;
        #10;
        if (result !== 32'd0) $fatal(1, "ADD wraparound failed");

        // Subtract a larger number from a smaller one
        a = 32'd3;
        b = 32'd10;
        alu_op = 2'b01;
        #10;
        if (result !== 32'hFFFFFFF9) $fatal(1, "SUB negative result failed");
        $display("All ALU tests passed!");
        $finish;
    end
endmodule