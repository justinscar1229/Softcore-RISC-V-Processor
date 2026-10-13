module immediate_generator
    import riscv_pkg::*;
(
    input  logic [31:0] instruction,
    output logic [31:0] immediate
);

    // Build the immediate for every format at once, then pick one by opcode.
    // Bit 31 is always the sign bit.
    logic [6:0]  opcode;
    logic [31:0] imm_i;   // I-type (addi, loads, jalr): imm[11:0] in bits 31:20
    logic [31:0] imm_s;   // S-type (stores): imm[11:5] in bits 31:25, imm[4:0] in bits 11:7
    logic [31:0] imm_b;   // B-type (branches): imm[12|10:5] in bits 31:25, imm[4:1|11] in bits 11:7
    logic [31:0] imm_u;   // U-type (lui, auipc): imm[31:12] in bits 31:12, low 12 bits zero
    logic [31:0] imm_j;   // J-type (jal): imm[20|10:1|11|19:12] in bits 31:12

    assign opcode = instruction[6:0];
    assign imm_i  = {{20{instruction[31]}}, instruction[31:20]};
    assign imm_s  = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
    // imm[0] is always 0 for branches and jumps: targets are an even number of bytes away.
    assign imm_b  = {{19{instruction[31]}}, instruction[31], instruction[7],
                     instruction[30:25], instruction[11:8], 1'b0};
    assign imm_u  = {instruction[31:12], 12'b0};
    assign imm_j  = {{11{instruction[31]}}, instruction[31], instruction[19:12],
                     instruction[20], instruction[30:21], 1'b0};

    always_comb begin
        case (opcode)
            OP_STORE:  immediate = imm_s;
            OP_BRANCH: immediate = imm_b;
            OP_LUI:    immediate = imm_u;
            OP_AUIPC:  immediate = imm_u;
            OP_JAL:    immediate = imm_j;
            default:   immediate = imm_i;   // OP_IMM, OP_LOAD, OP_JALR
        endcase
    end

endmodule
