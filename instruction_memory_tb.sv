`timescale 1ns/1ps

module instruction_memory_tb;
    logic [31:0] address;
    logic [31:0] instruction;

    instruction_memory #(.PROGRAM("programs/cpu_test.hex")) dut (
        .address(address),
        .instruction(instruction)
    );

    initial begin
        // Check the first four stored instructions.
        address = 32'd0;
        #10;
        if (instruction !== 32'h00A00093)
            $fatal(1, "Address 0 failed");

        address = 32'd4;
        #10;
        if (instruction !== 32'h00300113)
            $fatal(1, "Address 4 failed");

        address = 32'd8;
        #10;
        if (instruction !== 32'h002081B3)
            $fatal(1, "Address 8 failed");

        address = 32'd12;
        #10;
        if (instruction !== 32'h40208233)
            $fatal(1, "Address 12 failed");

        // The last instruction proves the whole file was loaded.
        address = 32'd368;
        #10;
        if (instruction !== 32'hFFFFF837)
            $fatal(1, "Address 368 (last instruction) failed");

        // The first address after the program should return zero.
        address = 32'd372;
        #10;
        if (instruction !== 32'h00000000)
            $fatal(1, "Default value failed");

        // Return to an earlier address.
        address = 32'd4;
        #10;
        if (instruction !== 32'h00300113)
            $fatal(1, "Read after address change failed");

        $display("All instruction memory tests passed!");
        $finish;
    end
endmodule
