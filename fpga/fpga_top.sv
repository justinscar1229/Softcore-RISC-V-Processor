// fpga_top.sv: the CPU on the ZedBoard.
//
//   SW[4:0]  which register the LEDs show (0 shows the PC, since x0 is always 0)
//   SW[6:5]  which byte of it: 0 = bits 7:0, 1 = 15:8, 2 = 23:16, 3 = 31:24
//   SW[7]    speed: 1 = full speed, 0 = slow (a few instructions per second)
//   BTNC     reset (center button)
//   LD[7:0]  the selected byte
module fpga_top #(
    parameter PROGRAM  = "program.hex",
    parameter SLOW_DIV = 6_250_000      // slow mode: one instruction per SLOW_DIV cycles
) (
    input  logic       GCLK,            // 100 MHz oscillator
    input  logic       BTNC,
    input  logic [7:0] SW,
    output logic [7:0] LD
);

    // ---------------- Clock ----------------
    logic clk;                          // CPU clock (25 MHz)
    logic locked;

    clock_gen clocks (
        .clk_in(GCLK),
        .clk_out(clk),
        .locked(locked)
    );

    // ---------------- Synchronizers ----------------
    // The button and switches change at random moments, not in step with clk.
    // Two flip-flops in a row give a clean copy (this avoids metastability).
    // Reset starts at 1 and stays on until the clock manager has locked.
    logic       reset_meta = 1'b1;
    logic       reset      = 1'b1;
    logic [7:0] sw_meta;
    logic [7:0] sw_sync;

    always_ff @(posedge clk) begin
        reset_meta <= BTNC || !locked;
        reset      <= reset_meta;
        sw_meta    <= SW;
        sw_sync    <= sw_meta;
    end

    logic       run_fast;
    logic [1:0] byte_select;
    logic [4:0] reg_select;
    assign run_fast    = sw_sync[7];
    assign byte_select = sw_sync[6:5];
    assign reg_select  = sw_sync[4:0];

    // ---------------- Speed ----------------
    // Full speed: the CPU runs every cycle. Slow: only on the one cycle
    // out of every SLOW_DIV when slow_tick is 1.
    logic [31:0] slow_count;
    logic        slow_tick;
    logic        enable;

    assign slow_tick = (slow_count == SLOW_DIV - 1);
    assign enable    = run_fast || slow_tick;

    always_ff @(posedge clk) begin
        if (reset || slow_tick)
            slow_count <= 32'd0;
        else
            slow_count <= slow_count + 32'd1;
    end

    // ---------------- CPU ----------------
    logic [31:0] pc;
    logic [31:0] instruction;
    logic [31:0] debug_value;

    cpu #(.PROGRAM(PROGRAM)) core (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .pc(pc),
        .instruction(instruction),
        .debug_reg(reg_select),
        .debug_value(debug_value)
    );

    // ---------------- LEDs ----------------
    logic [31:0] shown;
    logic [31:0] shifted;
    assign shown   = (reg_select == 5'd0) ? pc : debug_value;
    assign shifted = shown >> {byte_select, 3'b000};

    always_ff @(posedge clk)
        LD <= shifted[7:0];

endmodule
