`timescale 1ns/1ps

module immediate_generator_tb;
    logic [31:0] instruction;
    logic [31:0] immediate;

    immediate_generator dut (
        .instruction(instruction),
        .immediate(immediate)
    );

    initial begin
        // addi x1, x0, 10  (small positive value)
        instruction = 32'h00A00093;
        #10;
        if (immediate !== 32'h0000000A)
            $fatal(1, "Positive immediate failed");

        // addi x2, x0, -3  (negative: the sign bit fills the upper 20 bits)
        instruction = 32'hFFD00113;
        #10;
        if (immediate !== 32'hFFFFFFFD)
            $fatal(1, "Negative immediate failed");

        // addi x3, x0, 2047  (largest positive 12-bit value)
        instruction = 32'h7FF00193;
        #10;
        if (immediate !== 32'h000007FF)
            $fatal(1, "Maximum immediate failed");

        // addi x4, x0, -2048  (most negative 12-bit value)
        instruction = 32'h80000213;
        #10;
        if (immediate !== 32'hFFFFF800)
            $fatal(1, "Minimum immediate failed");

        // addi x31, x31, 1  (all-ones register fields must not leak in)
        instruction = 32'h001F8F93;
        #10;
        if (immediate !== 32'h00000001)
            $fatal(1, "Field isolation failed");

        // lw x25, 4(x0)  (loads are I-type too)
        instruction = 32'h00402C83;
        #10;
        if (immediate !== 32'h00000004)
            $fatal(1, "Load immediate failed");

        // sw x2, 8(x1)  (S-type: immediate split across bits 31:25 and 11:7)
        instruction = 32'h0020A423;
        #10;
        if (immediate !== 32'h00000008)
            $fatal(1, "Store immediate failed");

        // sw x20, -4(x21)  (negative S-type offset)
        instruction = 32'hFF4AAE23;
        #10;
        if (immediate !== 32'hFFFFFFFC)
            $fatal(1, "Negative store immediate failed");

        // sw x31, 0(x31)  (S-type must not read bits 24:20 as immediate bits)
        instruction = 32'h01FFA023;
        #10;
        if (immediate !== 32'h00000000)
            $fatal(1, "Store field isolation failed");

        // beq x1, x1, +8  (B-type: offset bits scattered, imm[0] always 0)
        instruction = 32'h00108463;
        #10;
        if (immediate !== 32'h00000008)
            $fatal(1, "Branch immediate failed");

        // blt x11, x12, -8  (negative branch offset: a backward jump)
        instruction = 32'hFEC5CCE3;
        #10;
        if (immediate !== 32'hFFFFFFF8)
            $fatal(1, "Negative branch immediate failed");

        // beq x0, x0, +4094  (largest branch offset)
        instruction = 32'h7E000FE3;
        #10;
        if (immediate !== 32'h00000FFE)
            $fatal(1, "Maximum branch immediate failed");

        // beq x0, x0, -4096  (smallest branch offset: only imm[12], the sign bit)
        instruction = 32'h80000063;
        #10;
        if (immediate !== 32'hFFFFF000)
            $fatal(1, "Minimum branch immediate failed");

        // beq x0, x0, +2048  (only imm[11], which lives in instruction bit 7)
        instruction = 32'h000000E3;
        #10;
        if (immediate !== 32'h00000800)
            $fatal(1, "Branch immediate bit 11 failed");

        // lui x5, 0x12345  (U-type: upper 20 bits, low 12 bits zero)
        instruction = 32'h123452B7;
        #10;
        if (immediate !== 32'h12345000)
            $fatal(1, "lui immediate failed");

        // lui x16, 0xFFFFF  (U-type with bit 31 set: no extra sign extension needed)
        instruction = 32'hFFFFF837;
        #10;
        if (immediate !== 32'hFFFFF000)
            $fatal(1, "Negative lui immediate failed");

        // auipc x6, 0x1  (U-type, same layout as lui)
        instruction = 32'h00001317;
        #10;
        if (immediate !== 32'h00001000)
            $fatal(1, "auipc immediate failed");

        // jal x1, +12  (J-type: offset bits scattered, imm[0] always 0)
        instruction = 32'h00C000EF;
        #10;
        if (immediate !== 32'h0000000C)
            $fatal(1, "jal immediate failed");

        // jal x0, -8  (negative jump: a backward jump)
        instruction = 32'hFF9FF06F;
        #10;
        if (immediate !== 32'hFFFFFFF8)
            $fatal(1, "Negative jal immediate failed");

        // jal x0, +2048  (only imm[11], which lives in instruction bit 20)
        instruction = 32'h0010006F;
        #10;
        if (immediate !== 32'h00000800)
            $fatal(1, "jal immediate bit 11 failed");

        // jal x0, +4096  (only imm[12], the lowest of imm[19:12] in bits 19:12)
        instruction = 32'h0000106F;
        #10;
        if (immediate !== 32'h00001000)
            $fatal(1, "jal immediate bit 12 failed");

        // jalr x13, 29(x1)  (jalr uses the I-type layout)
        instruction = 32'h01D086E7;
        #10;
        if (immediate !== 32'h0000001D)
            $fatal(1, "jalr immediate failed");

        $display("All immediate generator tests passed!");
        $finish;
    end
endmodule
