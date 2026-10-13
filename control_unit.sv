module control_unit
    import riscv_pkg::*;
(
    input  logic [6:0]  opcode,
    input  logic [2:0]  funct3,
    input  logic [6:0]  funct7,
    output logic        reg_write,
    output a_src_t      a_src,
    output logic        alu_src,
    output alu_op_t     alu_op,
    output logic        mem_write,
    output result_src_t result_src,
    output logic        branch,
    output logic        jump,
    output logic        jalr
);

    // alu_op is {bit30, funct3}: the instruction's own operation code.
    // bit30 (funct7 bit 5) picks sub over add, and sra over srl.
    // alu_op_t'(...) is a cast: it turns those 4 plain bits into the enum type.
    logic bit30;
    assign bit30 = funct7[5];

    always_comb begin
        // Defaults: write nothing, don't branch or jump.
        // Every output gets a value on every path.
        reg_write  = 1'b0;
        a_src      = A_RS1;
        alu_src    = 1'b0;
        alu_op     = ALU_ADD;
        mem_write  = 1'b0;
        result_src = RES_ALU;
        branch     = 1'b0;
        jump       = 1'b0;
        jalr       = 1'b0;

        case (opcode)
            OP_REG: begin
                // Second operand comes from register rs2.
                // funct7 must be 0000000, or 0100000 for sub (000) and sra (101).
                alu_src = 1'b0;
                if (funct7 == 7'b0000000 ||
                    (funct7 == 7'b0100000 && (funct3 == 3'b000 || funct3 == 3'b101))) begin
                    reg_write = 1'b1;
                    alu_op    = alu_op_t'({bit30, funct3});
                end
            end

            OP_IMM: begin
                // Second operand comes from the immediate.
                alu_src = 1'b1;
                case (funct3)
                    3'b001: begin  // slli: immediate bits 11:5 must be 0000000
                        if (funct7 == 7'b0000000) begin
                            reg_write = 1'b1;
                            alu_op    = ALU_SLL;
                        end
                    end
                    3'b101: begin  // srli (0000000) or srai (0100000)
                        if (funct7 == 7'b0000000 || funct7 == 7'b0100000) begin
                            reg_write = 1'b1;
                            alu_op    = alu_op_t'({bit30, funct3});
                        end
                    end
                    default: begin  // addi, slti, sltiu, xori, ori, andi
                        // Bits 31:25 are part of the immediate, so funct7 is ignored.
                        reg_write = 1'b1;
                        alu_op    = alu_op_t'({1'b0, funct3});
                    end
                endcase
            end

            OP_LOAD: begin
                // rd = memory value at rs1 + offset
                // funct3: lb 000, lh 001, lw 010, lbu 100, lhu 101
                if (funct3 == 3'b000 || funct3 == 3'b001 || funct3 == 3'b010 ||
                    funct3 == 3'b100 || funct3 == 3'b101) begin
                    reg_write  = 1'b1;
                    alu_src    = 1'b1;     // offset comes from the immediate
                    alu_op     = ALU_ADD;
                    result_src = RES_MEM;  // write back the memory value
                end
            end

            OP_STORE: begin
                // memory at rs1 + offset = rs2
                // funct3: sb 000, sh 001, sw 010
                if (funct3 == 3'b000 || funct3 == 3'b001 || funct3 == 3'b010) begin
                    mem_write = 1'b1;
                    alu_src   = 1'b1;      // offset comes from the immediate
                    alu_op    = ALU_ADD;
                end
            end

            OP_BRANCH: begin
                // Compare rs1 with rs2; if the branch unit says the condition holds,
                // the PC jumps to PC + offset. Nothing is written.
                // funct3: beq 000, bne 001, blt 100, bge 101, bltu 110, bgeu 111
                if (funct3 != 3'b010 && funct3 != 3'b011)
                    branch = 1'b1;
            end

            OP_LUI: begin
                // rd = immediate (upper 20 bits): the ALU adds 0 + immediate
                reg_write = 1'b1;
                a_src     = A_ZERO;
                alu_src   = 1'b1;
                alu_op    = ALU_ADD;
            end

            OP_AUIPC: begin
                // rd = PC + immediate (upper 20 bits)
                reg_write = 1'b1;
                a_src     = A_PC;
                alu_src   = 1'b1;
                alu_op    = ALU_ADD;
            end

            OP_JAL: begin
                // rd = PC + 4 (the return address); PC = PC + offset
                reg_write  = 1'b1;
                result_src = RES_PC4;
                jump       = 1'b1;
            end

            OP_JALR: begin
                // rd = PC + 4; PC = (rs1 + offset) with bit 0 cleared.
                // The ALU computes rs1 + offset. funct3 must be 000.
                if (funct3 == 3'b000) begin
                    reg_write  = 1'b1;
                    alu_src    = 1'b1;
                    alu_op     = ALU_ADD;
                    result_src = RES_PC4;
                    jump       = 1'b1;
                    jalr       = 1'b1;
                end
            end

            default: reg_write = 1'b0;  // opcode not supported
        endcase
    end

endmodule
