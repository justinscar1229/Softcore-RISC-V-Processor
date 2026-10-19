module program_counter (
    input  logic        clk,
    input  logic        reset,
    input  logic        enable,
    input  logic        load,     // 1 = go to target instead of the next instruction
    input  logic [31:0] target,
    output logic [31:0] pc
);

    always_ff @(posedge clk) begin
        if (reset)
            pc <= 32'd0;
        else if (enable) begin
            if (load)
                pc <= target;
            else
                pc <= pc + 32'd4;
        end
    end

endmodule
