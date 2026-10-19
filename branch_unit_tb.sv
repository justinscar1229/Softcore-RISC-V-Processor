`timescale 1ns/1ps

module branch_unit_tb;
    logic [31:0] a, b;
    logic [2:0]  funct3;
    logic        taken;

    branch_unit dut (
        .a(a),
        .b(b),
        .funct3(funct3),
        .taken(taken)
    );

    // Branch types: the funct3 values the branch instructions use.
    localparam BEQ = 3'b000, BNE = 3'b001, BLT = 3'b100,
               BGE = 3'b101, BLTU = 3'b110, BGEU = 3'b111;

    // Apply one comparison, wait, and compare the result.
    task check (
        input [2:0]  f3,
        input [31:0] in_a,
        input [31:0] in_b,
        input        expected
    );
        begin
            funct3 = f3;
            a = in_a;
            b = in_b;
            #10;
            if (taken !== expected)
                $fatal(1, "funct3 %b with %h, %h gave %b, expected %b",
                       f3, in_a, in_b, taken, expected);
        end
    endtask

    initial begin
        //    type  a             b             taken?
        check(BEQ,  32'd5,        32'd5,        1'b1);  // equal
        check(BEQ,  32'd5,        32'd6,        1'b0);
        check(BNE,  32'd5,        32'd6,        1'b1);
        check(BNE,  32'd5,        32'd5,        1'b0);
        check(BLT,  32'hFFFFFFFF, 32'd1,        1'b1);  // -1 < 1 signed
        check(BLT,  32'd1,        32'hFFFFFFFF, 1'b0);  // 1 < -1 is false
        check(BLT,  32'd5,        32'd5,        1'b0);  // equal is not less
        check(BGE,  32'd1,        32'hFFFFFFFF, 1'b1);  // 1 >= -1 signed
        check(BGE,  32'd5,        32'd5,        1'b1);  // equal counts as >=
        check(BGE,  32'hFFFFFFFF, 32'd1,        1'b0);
        check(BLTU, 32'd1,        32'hFFFFFFFF, 1'b1);  // 1 < 4294967295 unsigned
        check(BLTU, 32'hFFFFFFFF, 32'd1,        1'b0);
        check(BGEU, 32'hFFFFFFFF, 32'd1,        1'b1);
        check(BGEU, 32'd5,        32'd5,        1'b1);  // equal counts as >=
        check(BGEU, 32'd1,        32'hFFFFFFFF, 1'b0);
        check(3'b010, 32'd5,      32'd5,        1'b0);  // not a branch type
        check(3'b011, 32'd5,      32'd5,        1'b0);  // not a branch type

        $display("All branch unit tests passed!");
        $finish;
    end
endmodule
