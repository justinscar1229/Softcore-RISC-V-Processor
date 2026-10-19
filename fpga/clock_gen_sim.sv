// clock_gen_sim.sv: simulation stand-in for clock_gen.sv (same module name).
// Icarus can't simulate the FPGA's MMCM, so this passes the clock straight
// through and reports "locked" after 8 cycles. Compile this file or
// clock_gen.sv, never both.
module clock_gen #(
    parameter real DIVIDE = 40.0
) (
    input  logic clk_in,
    output logic clk_out,
    output logic locked
);

    logic [2:0] count = 3'd0;

    always_ff @(posedge clk_in) begin
        if (count != 3'd7)
            count <= count + 3'd1;
    end

    assign clk_out = clk_in;
    assign locked  = (count == 3'd7);

endmodule
