`timescale 1ns/1ps

module register_tb;
    reg clk;
    reg reset;
    reg write_enable;
    reg [31:0] d;
    wire [31:0] q;

    register dut(
        .clk(clk),
        .reset(reset),
        .write_enable(write_enable),
        .d(d),
        .q(q)
    );

    // Toggle every 5ns: a full clock cycle is 10ns
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("register.vcd");
        $dumpvars(0, register_tb);

        reset = 1;
        write_enable = 0;
        d = 32'd0;

        //Reset at the first rising edge
        @(posedge clk);
        #1;
        if (q !== 32'd0) $fatal(1, "Reset failed");

        //Set inputs on a fallung edge, before the next rising edge
        @(negedge clk);
        reset = 0;
        write_enable = 1;
        d = 32'd42;

        @(posedge clk);
        #1;
        if(q !== 32'd42) $fatal(1, "Write failed");

        //Changing d must not change q between rising edges
        @(negedge clk);
        d = 32'd99;
        #1;
        if(q !== 32'd42) $fatal(1, "Output changed between edges");

        //Disable writing: q must hold 42 at the next rising edge
        write_enable = 0;
        @(posedge clk);
        #1;
        if(q !== 32'd42) $fatal(1, "Hold failed");

        //Enable writing again: capture 99
        @(negedge clk);
        write_enable = 1;

        @(posedge clk);
        #1;
        if(q !== 32'd99) $fatal(1, "Second write failed");

        //Reset must override an enabled write
        @(negedge clk);
        reset = 1;
        d = 32'd123;
        #1;
        if(q !== 32'd99) $fatal(1, "Reset acted before clock edge");

        @(posedge clk);
        #1;
        if (q !== 32'd0) $fatal(1, "Reset priority failed");

        $display("All register tests passed!");
        $finish;
    end

endmodule
