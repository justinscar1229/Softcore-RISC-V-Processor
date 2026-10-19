module datapath
    import riscv_pkg::*;
(
    input  logic        clk,
    input  logic [4:0]  read_addr1,
    input  logic [4:0]  read_addr2,
    input  logic [4:0]  write_addr,
    input  logic        write_enable,
    input  alu_op_t     alu_op,

    input  logic        load_external,
    input  logic [31:0] external_data,

    output logic [31:0] alu_result
);

    logic [31:0] operand_a;
    logic [31:0] operand_b;
    logic [31:0] write_data;

    assign write_data = load_external ? external_data : alu_result;

    register_file registers (
        .clk(clk),
        .read_addr1(read_addr1),
        .read_addr2(read_addr2),
        .read_data1(operand_a),
        .read_data2(operand_b),
        .write_enable(write_enable),
        .write_addr(write_addr),
        .write_data(write_data),
        .debug_addr(5'd0),          // debug port not used here
        .debug_data()
    );

    alu arithmetic (
        .a(operand_a),
        .b(operand_b),
        .alu_op(alu_op),
        .result(alu_result)
    );

endmodule
