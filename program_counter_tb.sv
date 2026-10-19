`timescale 1ns/1ps

module program_counter_tb;
    logic clk;
    logic reset;
    logic enable;
    logic load;
    logic [31:0] target;
    logic [31:0] pc;

    program_counter dut (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .load(load),
        .target(target),
        .pc(pc)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        reset = 1;
        enable = 0;
        load = 0;
        target = 32'd0;

        //Reset the PC to zero.
        @(posedge clk);
        #1;
        if (pc !== 32'd0)
            $fatal(1, "Reset failed");

        //Enable counting.
        @(negedge clk);
        reset = 0;
        enable = 1;

        @(posedge clk);
        #1;
        if (pc !== 32'd4)
            $fatal(1, "First increment failed");

        //Leave enable high for another cycle.
        @(posedge clk);
        #1;
        if (pc !== 32'd8)
            $fatal(1, "Second increment failed");

        //Disable counting: the PC must hold its value.
        @(negedge clk);
        enable = 0;

        @(posedge clk);
        #1;
        if (pc !== 32'd8)
            $fatal(1, "Hold failed");

        //Re-enable counting.
        @(negedge clk);
        enable = 1;

        @(posedge clk);
        #1;
        if (pc !== 32'd12)
            $fatal(1, "Resume failed");

        //Assert reset while enable is still high.
        @(negedge clk);
        reset = 1;
        #1;
        if (pc !== 32'd12)
            $fatal(1, "Reset acted before the rising edge");

        @(posedge clk);
        #1;
        if (pc !== 32'd0)
            $fatal(1, "Reset priority failed");

        // Load a target instead of adding 4 (used by branches and jumps).
        @(negedge clk);
        reset = 0;
        load = 1;
        target = 32'd100;
        @(posedge clk);
        #1;
        if (pc !== 32'd100)
            $fatal(1, "Load target failed");

        // Load while disabled: the PC must hold.
        @(negedge clk);
        enable = 0;
        target = 32'd200;
        @(posedge clk);
        #1;
        if (pc !== 32'd100)
            $fatal(1, "Load happened while disabled");

        // Back to counting, from the loaded address.
        @(negedge clk);
        enable = 1;
        load = 0;
        @(posedge clk);
        #1;
        if (pc !== 32'd104)
            $fatal(1, "Increment after load failed");

        // Reset beats load.
        @(negedge clk);
        reset = 1;
        load = 1;
        @(posedge clk);
        #1;
        if (pc !== 32'd0)
            $fatal(1, "Reset did not override load");

        $display("All program counter tests passed!");
        $finish;
    end
endmodule
