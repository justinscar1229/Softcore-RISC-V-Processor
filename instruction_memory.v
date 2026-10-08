module instruction_memory (
    input  wire [31:0] address,
    output reg  [31:0] instruction
);

    // First real program. Each word is one RISC-V instruction.
    always @(*) begin
        case (address)
            32'd0:   instruction = 32'h00A00093;  // addi x1, x0, 10
            32'd4:   instruction = 32'h00300113;  // addi x2, x0, 3
            32'd8:   instruction = 32'h002081B3;  // add  x3, x1, x2
            32'd12:  instruction = 32'h40208233;  // sub  x4, x1, x2
            32'd16:  instruction = 32'h0020F2B3;  // and  x5, x1, x2
            32'd20:  instruction = 32'h0020E333;  // or   x6, x1, x2
            32'd24:  instruction = 32'h401103B3;  // sub  x7, x2, x1
            32'd28:  instruction = 32'hFFF38413;  // addi x8, x7, -1
            32'd32:  instruction = 32'h0FF47493;  // andi x9, x8, 255
            32'd36:  instruction = 32'h00C16513;  // ori  x10, x2, 12
            32'd40:  instruction = 32'h00108033;  // add  x0, x1, x1
            32'd44:  instruction = 32'h003005B3;  // add  x11, x0, x3
            default: instruction = 32'h00000000;
        endcase
    end

endmodule
