module instruction_fetch (
    input  logic        clk,
    input  logic        reset,
    input  logic        enable,
    input  logic        load,       // 1 = jump to target (taken branch)
    input  logic [31:0] target,
    output logic [31:0] pc,
    output logic [31:0] instruction
);

    program_counter pc_register (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .load(load),
        .target(target),
        .pc(pc)
    );

    instruction_memory memory (
        .address(pc),
        .instruction(instruction)
    );

endmodule
