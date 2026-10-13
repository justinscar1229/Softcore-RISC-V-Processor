`timescale 1ns/1ps

module control_unit_tb;
    import riscv_pkg::*;

    logic [31:0] instruction;
    logic [6:0]  opcode;
    logic [4:0]  rd;
    logic [2:0]  funct3;
    logic [4:0]  rs1;
    logic [4:0]  rs2;
    logic [6:0]  funct7;
    logic        reg_write;
    a_src_t      a_src;
    logic        alu_src;
    alu_op_t     alu_op;
    logic        mem_write;
    result_src_t result_src;
    logic        branch;
    logic        jump;
    logic        jalr;

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
        .a_src(a_src),
        .alu_src(alu_src),
        .alu_op(alu_op),
        .mem_write(mem_write),
        .result_src(result_src),
        .branch(branch),
        .jump(jump),
        .jalr(jalr)
    );

    // Apply one instruction and compare the control outputs.
    // The five "action" outputs are always checked: nothing may be written,
    // branched, or jumped by accident.
    // The ALU settings are checked only when the ALU result is actually used:
    // for a register result, a memory address, or a jalr target.
    // result_src is checked only when a register is written.
    task check (
        input [31:0]       instr,
        input              expected_reg_write,
        input              expected_mem_write,
        input              expected_branch,
        input              expected_jump,
        input              expected_jalr,
        input a_src_t      expected_a_src,
        input              expected_alu_src,
        input alu_op_t     expected_alu_op,
        input result_src_t expected_result_src
    );
        logic alu_used;
        begin
            instruction = instr;
            #10;
            if (reg_write !== expected_reg_write || mem_write !== expected_mem_write ||
                branch !== expected_branch || jump !== expected_jump || jalr !== expected_jalr)
                $fatal(1, "write/branch/jump outputs wrong for instruction %h", instr);
            alu_used = (expected_reg_write && expected_result_src != RES_PC4) ||
                       expected_mem_write || expected_jalr;
            if (alu_used && (a_src !== expected_a_src || alu_src !== expected_alu_src ||
                             alu_op !== expected_alu_op))
                $fatal(1, "ALU settings wrong for instruction %h", instr);
            if (expected_reg_write && result_src !== expected_result_src)
                $fatal(1, "result_src wrong for instruction %h", instr);
        end
    endtask

    initial begin
        //    instruction   reg   mem   br    jump  jalr  a_src   src   alu_op    result
        // R-type: second operand from a register
        check(32'h002082B3, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, A_RS1,  1'b0, ALU_ADD,  RES_ALU);  // add   x5, x1, x2
        check(32'h402082B3, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, A_RS1,  1'b0, ALU_SUB,  RES_ALU);  // sub   x5, x1, x2
        check(32'h002092B3, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, A_RS1,  1'b0, ALU_SLL,  RES_ALU);  // sll   x5, x1, x2
        check(32'h0020A2B3, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, A_RS1,  1'b0, ALU_SLT,  RES_ALU);  // slt   x5, x1, x2
        check(32'h0020B2B3, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, A_RS1,  1'b0, ALU_SLTU, RES_ALU);  // sltu  x5, x1, x2
        check(32'h0020C2B3, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, A_RS1,  1'b0, ALU_XOR,  RES_ALU);  // xor   x5, x1, x2
        check(32'h0020D2B3, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, A_RS1,  1'b0, ALU_SRL,  RES_ALU);  // srl   x5, x1, x2
        check(32'h4020D2B3, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, A_RS1,  1'b0, ALU_SRA,  RES_ALU);  // sra   x5, x1, x2
        check(32'h0020E2B3, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, A_RS1,  1'b0, ALU_OR,   RES_ALU);  // or    x5, x1, x2
        check(32'h0020F2B3, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, A_RS1,  1'b0, ALU_AND,  RES_ALU);  // and   x5, x1, x2

        // I-type: second operand from the immediate
        check(32'h00A08293, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, A_RS1,  1'b1, ALU_ADD,  RES_ALU);  // addi  x5, x1, 10
        check(32'h40008293, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, A_RS1,  1'b1, ALU_ADD,  RES_ALU);  // addi  x5, x1, 1024 (not sub!)
        check(32'hFFF0A293, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, A_RS1,  1'b1, ALU_SLT,  RES_ALU);  // slti  x5, x1, -1
        check(32'h0010B293, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, A_RS1,  1'b1, ALU_SLTU, RES_ALU);  // sltiu x5, x1, 1
        check(32'hFFF0C293, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, A_RS1,  1'b1, ALU_XOR,  RES_ALU);  // xori  x5, x1, -1
        check(32'h0FF0E293, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, A_RS1,  1'b1, ALU_OR,   RES_ALU);  // ori   x5, x1, 255
        check(32'h0FF0F293, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, A_RS1,  1'b1, ALU_AND,  RES_ALU);  // andi  x5, x1, 255
        check(32'h00409293, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, A_RS1,  1'b1, ALU_SLL,  RES_ALU);  // slli  x5, x1, 4
        check(32'h0040D293, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, A_RS1,  1'b1, ALU_SRL,  RES_ALU);  // srli  x5, x1, 4
        check(32'h4040D293, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, A_RS1,  1'b1, ALU_SRA,  RES_ALU);  // srai  x5, x1, 4

        // Loads: address = rs1 + offset, register gets the memory value
        check(32'h0000A683, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, A_RS1,  1'b1, ALU_ADD,  RES_MEM);  // lw    x13, 0(x1)
        check(32'h0080A283, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, A_RS1,  1'b1, ALU_ADD,  RES_MEM);  // lw    x5, 8(x1)
        check(32'h00008283, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, A_RS1,  1'b1, ALU_ADD,  RES_MEM);  // lb    x5, 0(x1)
        check(32'h00009283, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, A_RS1,  1'b1, ALU_ADD,  RES_MEM);  // lh    x5, 0(x1)
        check(32'h0000C283, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, A_RS1,  1'b1, ALU_ADD,  RES_MEM);  // lbu   x5, 0(x1)
        check(32'h0000D283, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, A_RS1,  1'b1, ALU_ADD,  RES_MEM);  // lhu   x5, 0(x1)

        // Stores: address = rs1 + offset, memory gets rs2, no register written
        check(32'h0020A423, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, A_RS1,  1'b1, ALU_ADD,  RES_ALU);  // sw    x2, 8(x1)
        check(32'hFF4AAE23, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, A_RS1,  1'b1, ALU_ADD,  RES_ALU);  // sw    x20, -4(x21)
        check(32'h00208023, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, A_RS1,  1'b1, ALU_ADD,  RES_ALU);  // sb    x2, 0(x1)
        check(32'h00209023, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, A_RS1,  1'b1, ALU_ADD,  RES_ALU);  // sh    x2, 0(x1)

        // Branches: nothing written, branch = 1 (the branch unit decides if it's taken)
        check(32'h00208463, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, A_RS1,  1'b0, ALU_ADD,  RES_ALU);  // beq   x1, x2, +8
        check(32'h00209463, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, A_RS1,  1'b0, ALU_ADD,  RES_ALU);  // bne   x1, x2, +8
        check(32'h0060C463, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, A_RS1,  1'b0, ALU_ADD,  RES_ALU);  // blt   x1, x6, +8
        check(32'h0060D463, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, A_RS1,  1'b0, ALU_ADD,  RES_ALU);  // bge   x1, x6, +8
        check(32'h0060E463, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, A_RS1,  1'b0, ALU_ADD,  RES_ALU);  // bltu  x1, x6, +8
        check(32'h00117463, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, A_RS1,  1'b0, ALU_ADD,  RES_ALU);  // bgeu  x2, x1, +8

        // Upper immediates
        check(32'h123452B7, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, A_ZERO, 1'b1, ALU_ADD,  RES_ALU);  // lui   x5, 0x12345
        check(32'h00001317, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, A_PC,   1'b1, ALU_ADD,  RES_ALU);  // auipc x6, 0x1

        // Jumps: rd gets PC + 4
        check(32'h00C000EF, 1'b1, 1'b0, 1'b0, 1'b1, 1'b0, A_RS1,  1'b0, ALU_ADD,  RES_PC4);  // jal   x1, +12
        check(32'h01D086E7, 1'b1, 1'b0, 1'b0, 1'b1, 1'b1, A_RS1,  1'b1, ALU_ADD,  RES_PC4);  // jalr  x13, 29(x1)

        // Invalid or not supported: must not write, branch, or jump.
        // (The last four values are not checked here; they are placeholders.)
        check(32'h4020F2B3, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, A_RS1,  1'b0, ALU_ADD,  RES_ALU);  // "and" with bit 30 set: invalid
        check(32'h022082B3, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, A_RS1,  1'b0, ALU_ADD,  RES_ALU);  // mul   x5, x1, x2 (M extension)
        check(32'h40409293, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, A_RS1,  1'b0, ALU_ADD,  RES_ALU);  // "slli" with bit 30 set: invalid
        check(32'h0000B283, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, A_RS1,  1'b0, ALU_ADD,  RES_ALU);  // ld    x5, 0(x1)  (64-bit RISC-V only)
        check(32'h0000E283, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, A_RS1,  1'b0, ALU_ADD,  RES_ALU);  // lwu   x5, 0(x1)  (64-bit RISC-V only)
        check(32'h0020B023, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, A_RS1,  1'b0, ALU_ADD,  RES_ALU);  // sd    x2, 0(x1)  (64-bit RISC-V only)
        check(32'h0020A463, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, A_RS1,  1'b0, ALU_ADD,  RES_ALU);  // branch with funct3 010: invalid
        check(32'h0020B463, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, A_RS1,  1'b0, ALU_ADD,  RES_ALU);  // branch with funct3 011: invalid
        check(32'h01D096E7, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, A_RS1,  1'b0, ALU_ADD,  RES_ALU);  // jalr with funct3 001: invalid
        check(32'h00000000, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, A_RS1,  1'b0, ALU_ADD,  RES_ALU);  // empty memory word

        $display("All control unit tests passed!");
        $finish;
    end
endmodule
