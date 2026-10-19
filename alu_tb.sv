`timescale 1ns/1ps

module alu_tb;
    import riscv_pkg::*;

    logic [31:0] a, b;
    alu_op_t     alu_op;
    logic [31:0] result;

    alu dut (
        .a(a),
        .b(b),
        .alu_op(alu_op),
        .result(result)
    );

    // Apply one operation, wait, and compare the result.
    task check (
        input alu_op_t op,
        input [31:0] in_a,
        input [31:0] in_b,
        input [31:0] expected
    );
        begin
            alu_op = op;
            a = in_a;
            b = in_b;
            #10;
            if (result !== expected)
                $fatal(1, "alu_op %b with %h, %h gave %h, expected %h",
                       op, in_a, in_b, result, expected);
        end
    endtask

    initial begin
        //    op        a             b             expected
        check(ALU_ADD,  32'd10,       32'd3,        32'd13);        // ADD
        check(ALU_ADD,  32'hFFFFFFFF, 32'd1,        32'd0);         // ADD wraps around
        check(ALU_SUB,  32'd10,       32'd3,        32'd7);         // SUB
        check(ALU_SUB,  32'd3,        32'd10,       32'hFFFFFFF9);  // SUB, negative result (-7)
        check(ALU_AND,  32'd10,       32'd3,        32'd2);         // AND
        check(ALU_OR,   32'd10,       32'd3,        32'd11);        // OR
        check(ALU_XOR,  32'd10,       32'd3,        32'd9);         // XOR: 1010 ^ 0011 = 1001
        check(ALU_SLL,  32'd1,        32'd4,        32'd16);        // SLL
        check(ALU_SLL,  32'd1,        32'd31,       32'h80000000);  // SLL by the maximum, 31
        check(ALU_SLL,  32'd1,        32'd33,       32'd2);         // SLL uses only b[4:0]: 33 acts as 1
        check(ALU_SRL,  32'h80000000, 32'd4,        32'h08000000);  // SRL fills with zeros
        check(ALU_SRA,  32'h80000000, 32'd4,        32'hF8000000);  // SRA copies the sign bit
        check(ALU_SRA,  32'h00000040, 32'd2,        32'h00000010);  // SRA of a positive value
        check(ALU_SLT,  32'hFFFFFFFF, 32'd1,        32'd1);         // SLT: -1 < 1 (signed)
        check(ALU_SLT,  32'd1,        32'hFFFFFFFF, 32'd0);         // SLT: 1 < -1 is false
        check(ALU_SLT,  32'd5,        32'd5,        32'd0);         // SLT: equal is not less
        check(ALU_SLTU, 32'hFFFFFFFF, 32'd1,        32'd0);         // SLTU: 4294967295 < 1 is false
        check(ALU_SLTU, 32'd1,        32'hFFFFFFFF, 32'd1);         // SLTU: 1 < 4294967295
        check(alu_op_t'(4'b1111), 32'd10, 32'd3, 32'd0);  // Unused code (cast to the enum type) gives 0

        $display("All ALU tests passed!");
        $finish;
    end
endmodule
