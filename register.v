module register(
    input wire clk,
    input wire reset,
    input wire write_enable,
    input wire [31:0] d,
    output reg [31:0] q
);

    always @(posedge clk) begin
        if (reset)
        q <= 32'd0;
    else if (write_enable)
        q <= d;
    end
    
endmodule
