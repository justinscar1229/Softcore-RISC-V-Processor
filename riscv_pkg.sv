// Shared definitions for the whole processor. Any module that needs them
// imports this package, so each code is defined in exactly one place.
package riscv_pkg;

    // Opcodes: instruction bits 6:0
    typedef enum logic [6:0] {
        OP_REG    = 7'b0110011,  // R-type: register-register arithmetic
        OP_IMM    = 7'b0010011,  // I-type: register-immediate arithmetic
        OP_LOAD   = 7'b0000011,  // I-type: loads (lb, lh, lw, lbu, lhu)
        OP_STORE  = 7'b0100011,  // S-type: stores (sb, sh, sw)
        OP_BRANCH = 7'b1100011,  // B-type: branches (beq, bne, blt, bge, bltu, bgeu)
        OP_JAL    = 7'b1101111,  // J-type: jump and link
        OP_JALR   = 7'b1100111,  // I-type: jump and link register
        OP_LUI    = 7'b0110111,  // U-type: load upper immediate
        OP_AUIPC  = 7'b0010111   // U-type: add upper immediate to PC
    } opcode_t;

    // ALU operations: the code is {funct7 bit 5, funct3} from the instruction
    typedef enum logic [3:0] {
        ALU_ADD  = 4'b0000,
        ALU_SLL  = 4'b0001,
        ALU_SLT  = 4'b0010,
        ALU_SLTU = 4'b0011,
        ALU_XOR  = 4'b0100,
        ALU_SRL  = 4'b0101,
        ALU_OR   = 4'b0110,
        ALU_AND  = 4'b0111,
        ALU_SUB  = 4'b1000,
        ALU_SRA  = 4'b1101
    } alu_op_t;

    // Where the ALU's first operand comes from
    typedef enum logic [1:0] {
        A_RS1  = 2'b00,  // register rs1 (most instructions)
        A_PC   = 2'b01,  // the PC (auipc)
        A_ZERO = 2'b10   // zero (lui)
    } a_src_t;

    // What gets written into register rd
    typedef enum logic [1:0] {
        RES_ALU = 2'b00,  // the ALU result
        RES_MEM = 2'b01,  // the value loaded from data memory
        RES_PC4 = 2'b10   // PC + 4, the return address (jal, jalr)
    } result_src_t;

endpackage
