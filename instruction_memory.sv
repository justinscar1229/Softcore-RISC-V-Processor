module instruction_memory #(
    parameter PROGRAM = "program.hex"   // hex file to load, built by programs\build.ps1
                                        // ("" = start empty; a testbench loads it)
) (
    input  logic [31:0] address,
    output logic [31:0] instruction
);

    // 1024 words = 4 KB of program space.
    logic [31:0] mem [0:1023];

    // Byte address -> word index: drop the low 2 bits.
    logic [9:0] index;
    assign index = address[11:2];

    // Load the program once, at the start of simulation.
    // Words the file doesn't cover stay 0.
    initial begin
        for (int i = 0; i < 1024; i++)
            mem[i] = 32'h00000000;
        if (PROGRAM != "")
            $readmemh(PROGRAM, mem);
    end

    assign instruction = mem[index];

endmodule
