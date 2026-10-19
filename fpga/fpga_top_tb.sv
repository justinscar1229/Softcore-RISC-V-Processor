`timescale 1ns/1ps

// Tests fpga_top in simulation, with clock_gen_sim.sv standing in for the MMCM.
// It runs programs/cpu_test.hex, whose final register values are known.
module fpga_top_tb;
    logic       GCLK;
    logic       BTNC;
    logic [7:0] SW;
    logic [7:0] LD;

    localparam int SLOW_DIV = 4;

    fpga_top #(.PROGRAM("programs/cpu_test.hex"), .SLOW_DIV(SLOW_DIV)) dut (
        .GCLK(GCLK),
        .BTNC(BTNC),
        .SW(SW),
        .LD(LD)
    );

    initial GCLK = 0;
    always #5 GCLK = ~GCLK;

    // Select a register and byte with the switches (keeping the speed switch),
    // wait for them to pass the synchronizer and the LED register, then check.
    task show (
        input [4:0] register,
        input [1:0] which_byte,
        input [7:0] expected
    );
        begin
            SW = {SW[7], which_byte, register};
            repeat (5) @(posedge GCLK);
            #1;
            if (LD !== expected)
                $fatal(1, "x%0d byte %0d: LEDs = %h, expected %h", register, which_byte, LD, expected);
        end
    endtask

    initial begin
        int          cycles;
        logic [31:0] pc_before;

        // Hold reset at full speed, showing the PC.
        BTNC = 1;
        SW   = 8'b1_00_00000;
        repeat (20) @(posedge GCLK);
        #1;
        if (dut.pc !== 32'd0 || LD !== 8'd0)
            $fatal(1, "During reset: pc = %0d, LEDs = %h", dut.pc, LD);

        // Run at full speed until the end of cpu_test (pc 372).
        BTNC = 0;
        cycles = 0;
        while (dut.pc !== 32'd372) begin
            @(posedge GCLK);
            #1;
            cycles++;
            if (cycles > 1000)
                $fatal(1, "cpu_test did not reach pc 372");
        end

        // Switch to slow mode; then exactly one instruction per SLOW_DIV cycles.
        SW[7] = 0;
        repeat (10) @(posedge GCLK);
        #1;
        pc_before = dut.pc;
        repeat (10 * SLOW_DIV) @(posedge GCLK);
        #1;
        if (dut.pc - pc_before !== 32'd40)
            $fatal(1, "Slow mode: PC moved %0d bytes in %0d cycles, expected 40",
                   dut.pc - pc_before, 10 * SLOW_DIV);

        // The program is done, so its registers hold their final values.
        show(5'd5,  2'd0, 8'h78);          // x5 = 12345678
        show(5'd5,  2'd1, 8'h56);
        show(5'd5,  2'd2, 8'h34);
        show(5'd5,  2'd3, 8'h12);
        show(5'd16, 2'd1, 8'hF0);          // x16 = FFFFF000
        show(5'd16, 2'd3, 8'hFF);
        show(5'd1,  2'd0, 8'h50);          // x1 = 336 = 0x150
        show(5'd1,  2'd1, 8'h01);
        show(5'd14, 2'd0, 8'h07);          // x14 = 7

        // Register 0 shows the PC. The LEDs are registered, so they can lag one step.
        SW = 8'b0_00_00000;
        repeat (5) @(posedge GCLK);
        #1;
        if (LD !== dut.pc[7:0] && LD !== dut.pc[7:0] - 8'd4)
            $fatal(1, "PC display: LEDs = %h, pc = %0d", LD, dut.pc);

        // Reset again: back to address 0.
        BTNC = 1;
        repeat (6) @(posedge GCLK);
        #1;
        if (dut.pc !== 32'd0 || LD !== 8'd0)
            $fatal(1, "Second reset: pc = %0d, LEDs = %h", dut.pc, LD);

        $display("All FPGA top tests passed!");
        $finish;
    end
endmodule
