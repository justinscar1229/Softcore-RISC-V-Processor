`timescale 1ns/1ps

module data_memory_tb;
    logic        clk;
    logic        write_enable;
    logic [2:0]  funct3;
    logic [31:0] address;
    logic [31:0] write_data;
    logic [31:0] read_data;

    data_memory dut (
        .clk(clk),
        .write_enable(write_enable),
        .funct3(funct3),
        .address(address),
        .write_data(write_data),
        .read_data(read_data)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    // Access sizes: the funct3 values the load and store instructions use.
    localparam B = 3'b000, H = 3'b001, W = 3'b010, BU = 3'b100, HU = 3'b101;

    // Store: set up on a falling edge, write at the rising edge.
    task store (
        input [2:0]  size,
        input [31:0] addr,
        input [31:0] data
    );
        begin
            @(negedge clk);
            write_enable = 1;
            funct3 = size;
            address = addr;
            write_data = data;
            @(posedge clk);
            #1;
            write_enable = 0;
        end
    endtask

    // Load: reads are combinational, so set the inputs and check.
    task load_check (
        input [2:0]  size,
        input [31:0] addr,
        input [31:0] expected
    );
        begin
            funct3 = size;
            address = addr;
            #1;
            if (read_data !== expected)
                $fatal(1, "load funct3=%b at %0d gave %h, expected %h",
                       size, addr, read_data, expected);
        end
    endtask

    initial begin
        write_enable = 0;
        funct3 = W;
        address = 32'd0;
        write_data = 32'd0;

        // Words. Nothing may change before the clock edge.
        @(negedge clk);
        write_enable = 1;
        address = 32'd0;
        write_data = 32'd13;
        #1;
        if (read_data === 32'd13)
            $fatal(1, "Write happened before the clock edge");
        @(posedge clk);
        #1;
        write_enable = 0;
        load_check(W, 0, 32'd13);

        store(W, 4, 32'hFFFFFFF9);
        load_check(W, 4, 32'hFFFFFFF9);
        load_check(W, 0, 32'd13);              // other words undisturbed

        // A disabled write changes nothing.
        @(negedge clk);
        address = 32'd0;
        write_data = 32'd99;
        @(posedge clk);
        #1;
        load_check(W, 0, 32'd13);

        store(W, 1020, 32'hA5A5A5A5);          // highest word
        load_check(W, 1020, 32'hA5A5A5A5);

        // Little-endian: byte 8 is bits 7:0 of the word at address 8.
        store(W, 8, 32'h11223344);
        load_check(BU, 8,  32'h00000044);
        load_check(BU, 9,  32'h00000033);
        load_check(BU, 10, 32'h00000022);
        load_check(BU, 11, 32'h00000011);
        load_check(HU, 8,  32'h00003344);
        load_check(HU, 10, 32'h00001122);

        // Signed vs unsigned loads.
        store(W, 12, 32'h80FF7F01);
        load_check(B,  12, 32'h00000001);      // 01: positive
        load_check(B,  13, 32'h0000007F);      // 7F: largest positive byte
        load_check(B,  14, 32'hFFFFFFFF);      // FF: -1, sign bit copied
        load_check(BU, 14, 32'h000000FF);      // FF: 255, zero-filled
        load_check(H,  14, 32'hFFFF80FF);      // 80FF: negative halfword
        load_check(HU, 14, 32'h000080FF);      // 80FF: 33023
        load_check(H,  12, 32'h00007F01);      // 7F01: positive halfword

        // Byte and halfword stores change only their own bytes.
        store(B, 9, 32'h000000AB);             // 11223344 -> 1122AB44
        load_check(W, 8, 32'h1122AB44);
        store(B, 11, 32'h12345678);            // only the low byte (78) is stored
        load_check(W, 8, 32'h7822AB44);
        store(H, 10, 32'h0000BEEF);            // upper halfword
        load_check(W, 8, 32'hBEEFAB44);
        store(H, 8, 32'hCAFE0102);             // lower halfword: only 0102 is stored
        load_check(W, 8, 32'hBEEF0102);

        $display("All data memory tests passed!");
        $finish;
    end
endmodule
