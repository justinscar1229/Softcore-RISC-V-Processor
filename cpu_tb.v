`timescale 1ns/1ps

module cpu_tb;
    reg         clk;
    reg         reset;
    wire [31:0] pc;
    wire [31:0] instruction;

    cpu dut (
        .clk(clk),
        .reset(reset),
        .pc(pc),
        .instruction(instruction)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    // Trace: print each register write as the processor commits it.
    always @(posedge clk) begin
        if (!reset && dut.reg_write) begin
            if (dut.rd == 5'd0)
                $display("pc=%2d  %h  write to x0 ignored", pc, instruction);
            else
                $display("pc=%2d  %h  x%0d <= %0d", pc, instruction, dut.rd, $signed(dut.alu_result));
        end
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

        // 12 program instructions, then 3 cycles of empty memory.
        repeat (15) @(posedge clk);
        #1;

        if (pc !== 32'd60)
            $fatal(1, "PC = %0d, expected 60", pc);

        check_reg(1,  32'd10);         // addi x1, x0, 10
        check_reg(2,  32'd3);          // addi x2, x0, 3
        check_reg(3,  32'd13);         // add  x3, x1, x2
        check_reg(4,  32'd7);          // sub  x4, x1, x2
        check_reg(5,  32'd2);          // and  x5, x1, x2
        check_reg(6,  32'd11);         // or   x6, x1, x2
        check_reg(7,  32'hFFFFFFF9);   // sub  x7, x2, x1   (-7)
        check_reg(8,  32'hFFFFFFF8);   // addi x8, x7, -1   (-8)
        check_reg(9,  32'h000000F8);   // andi x9, x8, 255  (248)
        check_reg(10, 32'd15);         // ori  x10, x2, 12
        check_reg(11, 32'd13);         // add  x11, x0, x3  (x0 still reads 0)

        $display("All CPU tests passed!");
        $finish;
    end
endmodule
