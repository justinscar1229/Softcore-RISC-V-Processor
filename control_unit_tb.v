`timescale 1ns/1ps

module control_unit_tb;
    reg  [31:0] instruction;
    wire [6:0]  opcode;
    wire [4:0]  rd;
    wire [2:0]  funct3;
    wire [4:0]  rs1;
    wire [4:0]  rs2;
    wire [6:0]  funct7;
    wire        reg_write;
    wire        alu_src;
    wire [1:0]  alu_op;

    // The already-tested decoder turns real instructions into fields.
    instruction_decoder decoder (
        .instruction(instruction),
        .opcode(opcode),
        .rd(rd),
        .funct3(funct3),
        .rs1(rs1),
        .rs2(rs2),
        .funct7(funct7)
    );

    control_unit dut (
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .reg_write(reg_write),
        .alu_src(alu_src),
        .alu_op(alu_op)
    );

    // Apply one instruction, wait, and compare all three control outputs.
    task check (
        input [31:0] instr,
        input        expected_reg_write,
        input        expected_alu_src,
        input [1:0]  expected_alu_op
    );
        begin
            instruction = instr;
            #10;
            if (reg_write !== expected_reg_write ||
                alu_src   !== expected_alu_src   ||
                alu_op    !== expected_alu_op)
                $fatal(1, "Control mismatch for instruction %h", instr);
        end
    endtask

    initial begin
        //    instruction   write  src   alu_op
        // R-type: second operand from a register
        check(32'h002082B3, 1'b1, 1'b0, 2'b00);  // add  x5, x1, x2
        check(32'h40208333, 1'b1, 1'b0, 2'b01);  // sub  x6, x1, x2
        check(32'h0020F3B3, 1'b1, 1'b0, 2'b10);  // and  x7, x1, x2
        check(32'h0020E433, 1'b1, 1'b0, 2'b11);  // or   x8, x1, x2

        // I-type: second operand from the immediate
        check(32'h00A00093, 1'b1, 1'b1, 2'b00);  // addi x1, x0, 10
        check(32'h40000093, 1'b1, 1'b1, 2'b00);  // addi x1, x0, 1024 (not sub!)
        check(32'h0FF0F493, 1'b1, 1'b1, 2'b10);  // andi x9, x1, 255
        check(32'h0010E513, 1'b1, 1'b1, 2'b11);  // ori  x10, x1, 1

        // Not supported yet: must not write any register
        check(32'h0020C5B3, 1'b0, 1'b0, 2'b00);  // xor  x11, x1, x2
        check(32'h02208633, 1'b0, 1'b0, 2'b00);  // mul  x12, x1, x2
        check(32'h0000A683, 1'b0, 1'b0, 2'b00);  // lw   x13, 0(x1)
        check(32'h00000000, 1'b0, 1'b0, 2'b00);  // empty memory word

        $display("All control unit tests passed!");
        $finish;
    end
endmodule
