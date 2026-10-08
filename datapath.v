module datapath(
    input wire clk,
    input wire [4:0] read_addr1,
    input wire [4:0] read_addr2,
    input wire [4:0] write_addr,
    input wire write_enable,
    input wire [1:0] alu_op,

    input wire load_external,
    input wire [31:0] external_data,

    output wire [31:0] alu_result
);

    wire [31:0] operand_a;
    wire [31:0] operand_b;
    wire [31:0] write_data;

    assign write_data = load_external ? external_data : alu_result;

    register_file registers(
        .clk(clk),
        .read_addr1(read_addr1),
        .read_addr2(read_addr2),
        .read_data1(operand_a),
        .read_data2(operand_b),
        .write_enable(write_enable),
        .write_addr(write_addr),
        .write_data(write_data)
    );

    alu arithmetic (
        .a(operand_a),
        .b(operand_b),
        .alu_op(alu_op),
        .result(alu_result)
    );
    
endmodule