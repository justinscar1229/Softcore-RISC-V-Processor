module instruction_fetch(
    input wire clk,
    input wire reset,
    input wire enable,
    output wire [31:0] pc,
    output wire [31:0] instruction
);

    program_counter pc_register(
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .pc(pc)
    );

    instruction_memory memory(
        .address(pc),
        .instruction(instruction)
    );

endmodule