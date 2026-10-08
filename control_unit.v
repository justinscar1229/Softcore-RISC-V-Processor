module control_unit (
    input  wire [6:0] opcode,
    input  wire [2:0] funct3,
    input  wire [6:0] funct7,
    output reg        reg_write,
    output reg        alu_src,
    output reg  [1:0] alu_op
);

    // Opcodes handled so far
    localparam OP     = 7'b0110011;  // R-type: register-register arithmetic
    localparam OP_IMM = 7'b0010011;  // I-type: register-immediate arithmetic

    // ALU operations (must match alu.v)
    localparam ALU_ADD = 2'b00;
    localparam ALU_SUB = 2'b01;
    localparam ALU_AND = 2'b10;
    localparam ALU_OR  = 2'b11;

    always @(*) begin
        // Defaults: write nothing. Every output gets a value on every path.
        reg_write = 1'b0;
        alu_src   = 1'b0;
        alu_op    = ALU_ADD;

        case (opcode)
            OP: begin
                // Second operand comes from register rs2.
                alu_src = 1'b0;
                case ({funct7, funct3})
                    10'b0000000_000: begin reg_write = 1'b1; alu_op = ALU_ADD; end  // add
                    10'b0100000_000: begin reg_write = 1'b1; alu_op = ALU_SUB; end  // sub
                    10'b0000000_111: begin reg_write = 1'b1; alu_op = ALU_AND; end  // and
                    10'b0000000_110: begin reg_write = 1'b1; alu_op = ALU_OR;  end  // or
                    default:         reg_write = 1'b0;  // not supported yet
                endcase
            end

            OP_IMM: begin
                // Second operand comes from the immediate.
                // Bits 31:25 belong to the immediate here, so funct7 is ignored.
                alu_src = 1'b1;
                case (funct3)
                    3'b000:  begin reg_write = 1'b1; alu_op = ALU_ADD; end  // addi
                    3'b111:  begin reg_write = 1'b1; alu_op = ALU_AND; end  // andi
                    3'b110:  begin reg_write = 1'b1; alu_op = ALU_OR;  end  // ori
                    default: reg_write = 1'b0;  // not supported yet
                endcase
            end

            default: reg_write = 1'b0;  // opcode not supported yet
        endcase
    end

endmodule
