module register (
    input  logic        clk,
    input  logic        reset,
    input  logic        write_enable,
    input  logic [31:0] d,
    output logic [31:0] q
);

    always_ff @(posedge clk) begin
        if (reset)
            q <= 32'd0;
        else if (write_enable)
            q <= d;
    end

endmodule
