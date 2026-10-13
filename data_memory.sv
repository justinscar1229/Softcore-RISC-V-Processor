module data_memory (
    input  logic        clk,
    input  logic        write_enable,
    input  logic [2:0]  funct3,       // access size, from the load/store instruction
    input  logic [31:0] address,
    input  logic [31:0] write_data,
    output logic [31:0] read_data
);

    // 256 words = 1 KB. Byte address bits 9:2 select the word, and
    // bits 1:0 select the byte within it (little-endian: byte 0 is bits 7:0).
    logic [31:0] mem [0:255];

    logic [7:0] index;
    logic [1:0] offset;
    logic [1:0] size;                 // funct3[1:0]: 00 byte, 01 halfword, 10 word
    assign index  = address[9:2];
    assign offset = address[1:0];
    assign size   = funct3[1:0];

    // ---------------- Loads ----------------
    // Shift the addressed byte or halfword down to bit 0, then extend it.
    logic [31:0] word;
    logic [31:0] shifted;
    logic [31:0] lb_value, lh_value, lbu_value, lhu_value;
    assign word      = mem[index];
    assign shifted   = word >> {offset, 3'b000};          // shift by offset * 8 bits
    assign lb_value  = {{24{shifted[7]}},  shifted[7:0]};  // sign-extend
    assign lh_value  = {{16{shifted[15]}}, shifted[15:0]}; // sign-extend
    assign lbu_value = {24'b0, shifted[7:0]};              // zero-extend
    assign lhu_value = {16'b0, shifted[15:0]};             // zero-extend

    always_comb begin
        case (funct3)
            3'b000:  read_data = lb_value;
            3'b001:  read_data = lh_value;
            3'b100:  read_data = lbu_value;
            3'b101:  read_data = lhu_value;
            default: read_data = word;      // lw
        endcase
    end

    // ---------------- Stores ----------------
    // byte_enable marks which of the word's 4 bytes get written.
    // store_data copies the value into every byte position it could land in.
    logic [3:0]  byte_enable;
    logic [31:0] store_data;
    logic [31:0] byte_copies, half_copies;
    assign byte_copies = {4{write_data[7:0]}};
    assign half_copies = {2{write_data[15:0]}};

    always_comb begin
        case (size)
            2'b00: begin  // sb
                byte_enable = 4'b0001 << offset;
                store_data  = byte_copies;
            end
            2'b01: begin  // sh
                byte_enable = 4'b0011 << offset;
                store_data  = half_copies;
            end
            default: begin  // sw
                byte_enable = 4'b1111;
                store_data  = write_data;
            end
        endcase
    end

    always_ff @(posedge clk) begin
        if (write_enable) begin
            if (byte_enable[0]) mem[index][7:0]   <= store_data[7:0];
            if (byte_enable[1]) mem[index][15:8]  <= store_data[15:8];
            if (byte_enable[2]) mem[index][23:16] <= store_data[23:16];
            if (byte_enable[3]) mem[index][31:24] <= store_data[31:24];
        end
    end

endmodule
