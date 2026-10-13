`timescale 1ns/1ps

module instruction_decoder_tb;
    logic [31:0] instruction;
    logic [6:0]  opcode;
    logic [4:0]  rd;
    logic [2:0]  funct3;
    logic [4:0]  rs1;
    logic [4:0]  rs2;
    logic [6:0]  funct7;

    instruction_decoder dut (
        .instruction(instruction),
        .opcode(opcode),
        .rd(rd),
        .funct3(funct3),
        .rs1(rs1),
        .rs2(rs2),
        .funct7(funct7)
    );

    initial begin
        // add x5, x1, x2  (R-type)
        instruction = 32'h002082B3;
        #10;
        if (opcode !== 7'b0110011 || rd !== 5'd5 || funct3 !== 3'b000 ||
            rs1 !== 5'd1 || rs2 !== 5'd2 || funct7 !== 7'b0000000)
            $fatal(1, "add decode failed");

        // sub x6, x1, x2  (R-type; only funct7 differs from add)
        instruction = 32'h40208333;
        #10;
        if (opcode !== 7'b0110011 || rd !== 5'd6 || funct3 !== 3'b000 ||
            rs1 !== 5'd1 || rs2 !== 5'd2 || funct7 !== 7'b0100000)
            $fatal(1, "sub decode failed");

        // or x31, x30, x29  (R-type; largest register numbers)
        instruction = 32'h01DF6FB3;
        #10;
        if (opcode !== 7'b0110011 || rd !== 5'd31 || funct3 !== 3'b110 ||
            rs1 !== 5'd30 || rs2 !== 5'd29 || funct7 !== 7'b0000000)
            $fatal(1, "or decode failed");

        // addi x1, x0, 10  (I-type; bits 31:20 hold the immediate)
        instruction = 32'h00A00093;
        #10;
        if (opcode !== 7'b0010011 || rd !== 5'd1 || funct3 !== 3'b000 ||
            rs1 !== 5'd0 || rs2 !== 5'd10)
            $fatal(1, "addi decode failed");

        $display("All instruction decoder tests passed!");
        $finish;
    end
endmodule
