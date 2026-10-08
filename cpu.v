module cpu (
    input  wire        clk,
    input  wire        reset,
    output wire [31:0] pc,
    output wire [31:0] instruction
);

    // ---------------- Fetch ----------------
    // The PC advances every cycle; memory returns the instruction at PC.
    instruction_fetch fetch (
        .clk(clk),
        .reset(reset),
        .enable(1'b1),
        .pc(pc),
        .instruction(instruction)
    );

    // ---------------- Decode ----------------
    wire [6:0] opcode;
    wire [4:0] rd;
    wire [2:0] funct3;
    wire [4:0] rs1;
    wire [4:0] rs2;
    wire [6:0] funct7;

    instruction_decoder decoder (
        .instruction(instruction),
        .opcode(opcode),
        .rd(rd),
        .funct3(funct3),
        .rs1(rs1),
        .rs2(rs2),
        .funct7(funct7)
    );

    wire [31:0] immediate;

    immediate_generator imm_gen (
        .instruction(instruction),
        .immediate(immediate)
    );

    wire       reg_write;
    wire       alu_src;
    wire [1:0] alu_op;

    control_unit control (
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .reg_write(reg_write),
        .alu_src(alu_src),
        .alu_op(alu_op)
    );

    // ---------------- Registers ----------------
    wire [31:0] rs1_value;
    wire [31:0] rs2_value;
    wire [31:0] alu_result;

    register_file registers (
        .clk(clk),
        .read_addr1(rs1),
        .read_addr2(rs2),
        .read_data1(rs1_value),
        .read_data2(rs2_value),
        .write_enable(reg_write && !reset),  // no writes during reset
        .write_addr(rd),
        .write_data(alu_result)
    );

    // ---------------- Execute ----------------
    // alu_src picks the ALU's second operand: register rs2 or the immediate.
    wire [31:0] alu_b;
    assign alu_b = alu_src ? immediate : rs2_value;

    alu arithmetic (
        .a(rs1_value),
        .b(alu_b),
        .alu_op(alu_op),
        .result(alu_result)
    );

endmodule
