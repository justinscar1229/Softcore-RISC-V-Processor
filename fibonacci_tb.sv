`timescale 1ns/1ps

module fibonacci_tb;
    logic        clk;
    logic        reset;
    logic [31:0] pc;
    logic [31:0] instruction;

    cpu #(.PROGRAM("programs/fibonacci.hex")) dut (
        .clk(clk),
        .reset(reset),
        .enable(1'b1),
        .pc(pc),
        .instruction(instruction),
        .debug_reg(5'd0),
        .debug_value()
    );

    initial clk = 0;
    always #5 clk = ~clk;

    // The program halts with "j done", which assembles to jal x0, 0 (a jump to itself).
    localparam logic [31:0] HALT = 32'h0000006F;

    initial begin
        int          cycles;
        logic [31:0] halt_pc;
        logic [31:0] a, b, next;

        reset = 1;
        repeat (3) @(posedge clk);
        @(negedge clk);
        reset = 0;

        // Run until the halt instruction is reached (give up after 1000 cycles).
        cycles = 0;
        while (instruction !== HALT) begin
            @(posedge clk);
            #1;
            cycles++;
            if (cycles > 1000)
                $fatal(1, "Program did not halt (pc = %0d)", pc);
        end
        $display("Halted at pc=%0d after %0d cycles", pc, cycles);

        // The halt loop must hold the PC in place.
        halt_pc = pc;
        repeat (3) @(posedge clk);
        #1;
        if (pc !== halt_pc)
            $fatal(1, "PC left the halt loop: %0d", pc);

        // Compare memory with Fibonacci numbers computed here.
        a = 0;
        b = 1;
        for (int i = 0; i < 12; i++) begin
            if (dut.dmem.mem[i] !== a)
                $fatal(1, "mem[%0d] = %0d, expected %0d", i * 4, dut.dmem.mem[i], a);
            next = a + b;
            a = b;
            b = next;
        end

        $display("All Fibonacci tests passed!");
        $finish;
    end
endmodule
