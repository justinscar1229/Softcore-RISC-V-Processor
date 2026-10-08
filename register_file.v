module register_file(
    input wire clk,

    input wire [4:0] read_addr1,
    input wire [4:0] read_addr2,
    output wire [31:0] read_data1,
    output wire [31:0] read_data2,

    input wire write_enable,
    input wire [4:0] write_addr,
    input wire [31:0] write_data
);

    reg [31:0] regs [0:31];

    assign read_data1 = (read_addr1 == 5'd0) ? 32'd0 : regs[read_addr1];
    assign read_data2 = (read_addr2 == 5'd0) ? 32'd0 : regs[read_addr2];

    always @(posedge clk) begin
        if(write_enable && (write_addr != 5'd0))
            regs[write_addr] <= write_data;
    end

endmodule
