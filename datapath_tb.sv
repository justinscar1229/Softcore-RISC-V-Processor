`timescale 1ns/1ps

module datapath_tb;
    import riscv_pkg::*;

    logic clk;
    logic [4:0] read_addr1, read_addr2, write_addr;
    logic write_enable;
    alu_op_t alu_op;
    logic load_external;
    logic [31:0] external_data;
    logic [31:0] alu_result;

    datapath dut(
        .clk(clk),
        .read_addr1(read_addr1),
        .read_addr2(read_addr2),
        .write_addr(write_addr),
        .write_enable(write_enable),
        .alu_op(alu_op),
        .load_external(load_external),
        .external_data(external_data),
        .alu_result(alu_result)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        read_addr1 = 0;
        read_addr2 = 0;
        write_addr = 0;
        write_enable = 0;
        alu_op = ALU_ADD;
        load_external = 0;
        external_data = 0;

        //Load x1 with 10
        @(negedge clk);
        load_external = 1;
        external_data = 32'd10;
        write_addr = 5'd1;
        write_enable = 1;

        @(posedge clk);

        //Load x2 with 3
        @(negedge clk);
        external_data = 32'd3;
        write_addr = 5'd2;

        @(posedge clk);

        //Calculate x1 + x2 and select x5 as the destination.
        @(negedge clk);
        load_external = 0;
        read_addr1 = 5'd1;
        read_addr2 = 5'd2;
        alu_op = ALU_ADD;
        write_addr = 5'd5;

        #1;
        if(alu_result !== 32'd13)
            $fatal(1, "Addition failed");

        //Store the ALU result in x5.
        @(posedge clk);

        //Read back x5 through the ALU using x5 + x0.
        @(negedge clk);
        write_enable = 0;
        read_addr1 = 5'd5;
        read_addr2 = 5'd0;

        #1;
        if (alu_result !== 32'd13)
            $fatal(1, "Result was not stored in x5");

        $display("All datapath tests passed!");
        $finish;
    end
endmodule
