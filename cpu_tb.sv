`timescale 1ns/1ps

module cpu_tb;
    logic        clk;
    logic        reset;
    logic [31:0] pc;
    logic [31:0] instruction;

    cpu dut (
        .clk(clk),
        .reset(reset),
        .pc(pc),
        .instruction(instruction)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    // Trace: print each register write, memory write, and jump
    // (taken branch, jal, or jalr) as the processor commits it.
    always @(posedge clk) begin
        if (!reset && dut.reg_write) begin
            if (dut.rd == 5'd0)
                $display("pc=%3d  %h  write to x0 ignored", pc, instruction);
            else
                $display("pc=%3d  %h  x%0d <= %0d", pc, instruction, dut.rd, $signed(dut.write_back));
        end
        if (!reset && dut.mem_write)
            $display("pc=%3d  %h  mem[%0d] <= %0d (%s)", pc, instruction, dut.alu_result,
                     $signed(dut.rs2_value),
                     (dut.funct3[1:0] == 2'b00) ? "byte" :
                     (dut.funct3[1:0] == 2'b01) ? "half" : "word");
        if (!reset && dut.take_jump)
            $display("pc=%3d  %h  jump -> %0d", pc, instruction, dut.jump_target);
    end

    // Compare one register inside the processor with its expected value.
    task check_reg (
        input [4:0]  number,
        input [31:0] expected
    );
        begin
            if (dut.registers.regs[number] !== expected)
                $fatal(1, "x%0d = %h, expected %h", number, dut.registers.regs[number], expected);
        end
    endtask

    // Compare one data memory word (by byte address) with its expected value.
    task check_mem (
        input [31:0] address,
        input [31:0] expected
    );
        begin
            if (dut.dmem.mem[address[9:2]] !== expected)
                $fatal(1, "mem[%0d] = %h, expected %h", address, dut.dmem.mem[address[9:2]], expected);
        end
    endtask

    initial begin
        // Hold reset for three rising edges.
        reset = 1;
        repeat (3) @(posedge clk);
        #1;
        if (pc !== 32'd0)
            $fatal(1, "PC did not reset to 0");
        if (dut.registers.regs[1] !== 32'bx)
            $fatal(1, "A register was written during reset");

        // Release reset. From now on, one instruction completes per rising edge.
        @(negedge clk);
        reset = 0;

        // ---- Part 1 (arithmetic, logic, word loads and stores): 33 instructions ----
        repeat (33) @(posedge clk);
        #1;
        if (pc !== 32'd132)
            $fatal(1, "PC = %0d, expected 132", pc);

        check_reg(1,  32'd10);         // addi  x1, x0, 10
        check_reg(2,  32'd3);          // addi  x2, x0, 3
        check_reg(3,  32'd13);         // add   x3, x1, x2
        check_reg(4,  32'd7);          // sub   x4, x1, x2
        check_reg(5,  32'd2);          // and   x5, x1, x2
        check_reg(6,  32'd11);         // or    x6, x1, x2
        check_reg(7,  32'hFFFFFFF9);   // sub   x7, x2, x1    (-7)
        check_reg(8,  32'hFFFFFFF8);   // addi  x8, x7, -1    (-8)
        check_reg(9,  32'h000000F8);   // andi  x9, x8, 255   (248)
        check_reg(10, 32'd15);         // ori   x10, x2, 12
        check_reg(11, 32'd13);         // add   x11, x0, x3   (x0 still reads 0)
        check_reg(12, 32'd9);          // xor   x12, x1, x2   (1010 ^ 0011)
        check_reg(13, 32'd80);         // sll   x13, x1, x2   (10 << 3)
        check_reg(14, 32'h1FFFFFFF);   // srl   x14, x7, x2   (zeros shifted in)
        check_reg(15, 32'hFFFFFFFF);   // sra   x15, x7, x2   (-7 >> 3 = -1)
        check_reg(16, 32'd1);          // slt   x16, x7, x1   (-7 < 10)
        check_reg(17, 32'd0);          // sltu  x17, x7, x1   (FFFFFFF9 is huge unsigned)
        check_reg(18, 32'd1);          // slti  x18, x2, 5    (3 < 5)
        check_reg(19, 32'd1);          // sltiu x19, x2, -1   (3 < FFFFFFFF unsigned)
        check_reg(20, 32'hFFFFFFF5);   // xori  x20, x1, -1   (NOT 10)
        check_reg(21, 32'd48);         // slli  x21, x2, 4    (3 << 4)
        check_reg(22, 32'd15);         // srli  x22, x8, 28   (FFFFFFF8 >> 28)
        check_reg(23, 32'hFFFFFFFC);   // srai  x23, x8, 1    (-8 >> 1 = -4)
        check_reg(24, 32'd13);         // lw    x24, 0(x0)    (stored from x3)
        check_reg(25, 32'hFFFFFFF9);   // lw    x25, 4(x0)    (stored from x7)
        check_reg(26, 32'hFFFFFFF5);   // lw    x26, 44(x0)   (stored at 48 - 4)
        check_reg(27, 32'd6);          // add   x27, x24, x25 (13 + -7)
        check_reg(28, 32'd6);          // lw    x28, 48(x0)   (stored from x27)

        check_mem(0,  32'd13);         // sw    x3, 0(x0)
        check_mem(4,  32'hFFFFFFF9);   // sw    x7, 4(x0)
        check_mem(44, 32'hFFFFFFF5);   // sw    x20, -4(x21)
        check_mem(48, 32'd6);          // sw    x27, 0(x21)

        // ---- Part 2 (byte and halfword loads and stores): 11 instructions ----
        repeat (11) @(posedge clk);
        #1;
        if (pc !== 32'd176)
            $fatal(1, "PC = %0d, expected 176", pc);

        check_mem(52, 32'hFFF550F8);   // built by sw, sb, sb, sh
        check_reg(29, 32'hFFF550F8);   // lw    x29, 52(x0)
        check_reg(30, 32'hFFFFFFF8);   // lb    x30, 52(x0)   (F8 sign-extended: -8)
        check_reg(31, 32'h000000F8);   // lbu   x31, 52(x0)   (F8 zero-extended: 248)
        check_reg(5,  32'h00000050);   // lb    x5, 53(x0)    (50 is positive: 80)
        check_reg(6,  32'hFFFFFFF5);   // lh    x6, 54(x0)    (FFF5 sign-extended: -11)
        check_reg(7,  32'h0000FFF5);   // lhu   x7, 54(x0)    (FFF5 zero-extended: 65525)
        check_reg(8,  32'h000050F8);   // lh    x8, 52(x0)    (lower half, positive)

        // ---- Part 3 (branches): a loop, then every branch type ----
        // 3 setup + 10 loop passes x 3 + 2 counters + 7 taken x 1 + 6 not taken x 2 = 54 cycles
        repeat (54) @(posedge clk);
        #1;
        if (pc !== 32'd312)
            $fatal(1, "PC = %0d, expected 312", pc);

        check_reg(10, 32'd55);         // sum of 1..10
        check_reg(11, 32'd11);         // the loop stopped when i reached 11
        check_reg(30, 32'd0);          // no branch went the wrong way
        check_reg(31, 32'd6);          // all 6 not-taken branches fell through

        // ---- Part 4 (upper immediates and jumps), then 3 cycles of empty memory ----
        // 14 instructions run (the function call skips around), plus 3 empty cycles
        repeat (17) @(posedge clk);
        #1;
        if (pc !== 32'd384)
            $fatal(1, "PC = %0d, expected 384", pc);

        check_reg(5,  32'h12345678);   // lui + addi: a full 32-bit constant
        check_reg(6,  32'h00001140);   // auipc x6, 0x1   (320 + 4096)
        check_reg(7,  32'd324);        // auipc x7, 0     (its own address)
        check_reg(1,  32'd336);        // jal saved the return address
        check_reg(10, 32'd10);         // the function doubled 5
        check_reg(11, 32'd10);         // copied after returning
        check_reg(12, 32'd1);          // jal x0 jumped over the function to here
        check_reg(13, 32'd360);        // jalr saved its return address
        check_reg(15, 32'hFFFFFFFF);   // still from Part 1: the addi at 360 was skipped
        check_reg(14, 32'd7);          // jalr landed at 364 (bit 0 of 365 cleared)
        check_reg(16, 32'hFFFFF000);   // lui with the top bit set

        $display("All CPU tests passed!");
        $finish;
    end
endmodule
