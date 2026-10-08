module immediate_generator (
    input  wire [31:0] instruction,
    output wire [31:0] immediate
);

    // I-type: 12-bit immediate in bits 31:20, sign-extended to 32 bits.
    assign immediate = {{20{instruction[31]}}, instruction[31:20]};

endmodule
