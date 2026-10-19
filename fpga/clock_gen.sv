// clock_gen.sv: makes the CPU clock from the board's 100 MHz oscillator,
// using one of the FPGA's clock managers (an MMCM).
// Output frequency = 1000 MHz / DIVIDE (DIVIDE = 40 gives 25 MHz).
// Simulation uses clock_gen_sim.sv instead: Icarus has no MMCM model.
module clock_gen #(
    parameter real DIVIDE = 40.0
) (
    input  logic clk_in,      // 100 MHz
    output logic clk_out,
    output logic locked       // 1 once the output clock is stable
);

    logic clk_unbuffered;
    logic feedback;

    MMCME2_BASE #(
        .CLKIN1_PERIOD(10.0),          // 100 MHz input
        .CLKFBOUT_MULT_F(10.0),        // internal oscillator (VCO) runs at 1000 MHz
        .CLKOUT0_DIVIDE_F(DIVIDE)      // output = 1000 MHz / DIVIDE
    ) mmcm (
        .CLKIN1(clk_in),
        .CLKFBIN(feedback),
        .CLKFBOUT(feedback),
        .CLKOUT0(clk_unbuffered),
        .LOCKED(locked),
        .RST(1'b0),
        .PWRDWN(1'b0),
        .CLKFBOUTB(),
        .CLKOUT0B(),
        .CLKOUT1(),
        .CLKOUT1B(),
        .CLKOUT2(),
        .CLKOUT2B(),
        .CLKOUT3(),
        .CLKOUT3B(),
        .CLKOUT4(),
        .CLKOUT5(),
        .CLKOUT6()
    );

    // A global clock buffer carries the clock across the whole chip with little skew.
    BUFG clock_buffer (
        .I(clk_unbuffered),
        .O(clk_out)
    );

endmodule
