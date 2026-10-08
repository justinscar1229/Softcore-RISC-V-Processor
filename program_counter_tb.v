`timescale 1ns/1ps

module program_counter_tb;
    reg clk;
    reg reset;
    reg enable;
    wire [31:0] pc;

    program_counter dut (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .pc(pc)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("program_counter.vcd");
        $dumpvars(0, program_counter_tb);

        reset = 1;
        enable = 0;

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

        $display("All program counter tests passed!");
        $finish;
    end
endmodule