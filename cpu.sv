module cpu
    import riscv_pkg::*;
#(
    parameter PROGRAM = "program.hex"   // hex file for instruction memory
) (
    input  logic        clk,
    input  logic        reset,
    input  logic        enable,        // 0 = freeze: the PC holds and nothing is written
    output logic [31:0] pc,
    output logic [31:0] instruction,

    // Read any register from outside (for the board's LEDs).
    input  logic [4:0]  debug_reg,
    output logic [31:0] debug_value
);

    // Jump signals are used by the fetch unit here, but computed further
    // down, so they must be declared first.
    logic        take_jump;
    logic [31:0] jump_target;

    // ---------------- Fetch ----------------
    // While enabled, the PC advances every cycle: to PC + 4, or to the
    // target of a taken branch or a jump.
    instruction_fetch #(.PROGRAM(PROGRAM)) fetch (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .load(take_jump),
        .target(jump_target),
        .pc(pc),
        .instruction(instruction)
    );

    logic [31:0] pc_plus4;
    assign pc_plus4 = pc + 32'd4;

    // ---------------- Decode ----------------
    logic [6:0] opcode;
    logic [4:0] rd;
    logic [2:0] funct3;
    logic [4:0] rs1;
    logic [4:0] rs2;
    logic [6:0] funct7;

    instruction_decoder decoder (
        .instruction(instruction),
        .opcode(opcode),
        .rd(rd),
        .funct3(funct3),
        .rs1(rs1),
        .rs2(rs2),
        .funct7(funct7)
    );

    logic [31:0] immediate;

    immediate_generator imm_gen (
        .instruction(instruction),
        .immediate(immediate)
    );

    logic        reg_write;
    a_src_t      a_src;
    logic        alu_src;
    alu_op_t     alu_op;
    logic        mem_write;
    result_src_t result_src;
    logic        branch;
    logic        jump;
    logic        jalr;

    control_unit control (
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

    // ---------------- Registers ----------------
    logic [31:0] rs1_value;
    logic [31:0] rs2_value;
    logic [31:0] write_back;

    register_file registers (
        .clk(clk),
        .read_addr1(rs1),
        .read_addr2(rs2),
        .read_data1(rs1_value),
        .read_data2(rs2_value),
        .write_enable(reg_write && enable && !reset),  // no writes while frozen or in reset
        .write_addr(rd),
        .write_data(write_back),
        .debug_addr(debug_reg),
        .debug_data(debug_value)
    );

    // ---------------- Execute ----------------
    // a_src picks the ALU's first operand: rs1, the PC (auipc), or zero (lui).
    // alu_src picks the second operand: register rs2 or the immediate.
    logic [31:0] alu_a;
    logic [31:0] alu_b;
    logic [31:0] alu_result;

    always_comb begin
        case (a_src)
            A_PC:    alu_a = pc;
            A_ZERO:  alu_a = 32'd0;
            default: alu_a = rs1_value;
        endcase
    end

    assign alu_b = alu_src ? immediate : rs2_value;

    alu arithmetic (
        .a(alu_a),
        .b(alu_b),
        .alu_op(alu_op),
        .result(alu_result)
    );

    // ---------------- Branches and jumps ----------------
    // The branch unit compares rs1 with rs2.
    // Branches and jal go to PC + offset; jalr goes to (rs1 + offset) with bit 0 cleared.
    logic        branch_condition;
    logic [31:0] jalr_target;

    branch_unit compare (
        .a(rs1_value),
        .b(rs2_value),
        .funct3(funct3),
        .taken(branch_condition)
    );

    assign jalr_target = {alu_result[31:1], 1'b0};
    assign take_jump   = (branch && branch_condition) || jump;
    assign jump_target = jalr ? jalr_target : pc + immediate;

    // ---------------- Memory ----------------
    // Loads and stores use the ALU result (rs1 + offset) as the address.
    logic [31:0] mem_read_data;

    data_memory dmem (
        .clk(clk),
        .write_enable(mem_write && enable && !reset),  // no writes while frozen or in reset
        .funct3(funct3),                     // access size: byte, halfword, or word
        .address(alu_result),
        .write_data(rs2_value),
        .read_data(mem_read_data)
    );

    // ---------------- Write back ----------------
    // result_src picks what goes into rd: the ALU result, the loaded value,
    // or PC + 4 (the return address saved by jal and jalr).
    always_comb begin
        case (result_src)
            RES_MEM: write_back = mem_read_data;
            RES_PC4: write_back = pc_plus4;
            default: write_back = alu_result;
        endcase
    end

endmodule
