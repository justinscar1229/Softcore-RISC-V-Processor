`timescale 1ns/1ps

module register_file_tb;
    logic clk;
    logic [4:0] read_addr1, read_addr2;
    logic [31:0] read_data1, read_data2;
    logic write_enable;
    logic [4:0] write_addr;
    logic [31:0] write_data;

    register_file dut (
        .clk(clk),
        .read_addr1(read_addr1),
        .read_addr2(read_addr2),
        .read_data1(read_data1),
        .read_data2(read_data2),
        .write_enable(write_enable),
        .write_addr(write_addr),
        .write_data(write_data)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        read_addr1 = 0;
        read_addr2 = 0;
        write_enable = 0;
        write_addr = 0;
        write_data = 0;
        #1;
        if (read_data1 !== 32'd0 || read_data2 !== 32'd0)
            $fatal(1, "x0 must read zero on both ports");

        // Write x1 = 42. Observe it on read port 1.
        @(negedge clk);
        write_enable = 1;
        write_addr = 5'd1;
        write_data = 32'd42;
        read_addr1 = 5'd1;
        @(posedge clk);
        #1;
        if (read_data1 !== 32'd42) $fatal(1, "Write to x1 failed");

        // Write x2 = 99, while continuing to read x1.
        @(negedge clk);
        write_addr = 5'd2;
        write_data = 32'd99;
        read_addr2 = 5'd2;
        @(posedge clk);
        #1;
        if (read_data1 !== 32'd42 || read_data2 !== 32'd99)
            $fatal(1, "Independent register reads failed");

        // Swap read addresses without waiting for a rising edge.
        @(negedge clk);
        write_enable = 0;
        read_addr1 = 5'd2;
        read_addr2 = 5'd1;
        #1;
        if (read_data1 !== 32'd99 || read_data2 !== 32'd42)
            $fatal(1, "Combinational reads failed");

        // Attempt to overwrite x1 with writing disabled.
        write_addr = 5'd1;
        write_data = 32'd123;
        @(posedge clk);
        #1;
        if (read_data2 !== 32'd42) $fatal(1, "Disabled write changed x1");

        // Enable the write, but check that it waits for the edge.
        @(negedge clk);
        write_enable = 1;
        #1;
        if (read_data2 !== 32'd42) $fatal(1, "Write occurred before rising edge");
        @(posedge clk);
        #1;
        if (read_data2 !== 32'd123 || read_data1 !== 32'd99)
            $fatal(1, "Clocked overwrite or preservation of x2 failed");

        // Attempt a write to x0. Both ports must still return zero.
        @(negedge clk);
        write_addr = 5'd0;
        write_data = 32'd777;
        read_addr1 = 5'd0;
        read_addr2 = 5'd0;
        @(posedge clk);
        #1;
        if (read_data1 !== 32'd0 || read_data2 !== 32'd0)
            $fatal(1, "Write to x0 changed its visible value");

        // Exercise the highest address and read it on both ports.
        @(negedge clk);
        write_addr = 5'd31;
        write_data = 32'hA5A5A5A5;
        read_addr1 = 5'd31;
        read_addr2 = 5'd31;
        @(posedge clk);
        #1;
        if (read_data1 !== 32'hA5A5A5A5 || read_data2 !== 32'hA5A5A5A5)
            $fatal(1, "x31 or same-address reads failed");

        $display("All register file tests passed!");
        $finish;
    end
endmodule
