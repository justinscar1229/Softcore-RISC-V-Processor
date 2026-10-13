module instruction_memory (
    input  logic [31:0] address,
    output logic [31:0] instruction
);

    // First real program. Each word is one RISC-V instruction.
    always_comb begin
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
            // Lesson 5: XOR, shifts, and comparisons
            32'd48:  instruction = 32'h0020C633;  // xor   x12, x1, x2
            32'd52:  instruction = 32'h002096B3;  // sll   x13, x1, x2
            32'd56:  instruction = 32'h0023D733;  // srl   x14, x7, x2
            32'd60:  instruction = 32'h4023D7B3;  // sra   x15, x7, x2
            32'd64:  instruction = 32'h0013A833;  // slt   x16, x7, x1
            32'd68:  instruction = 32'h0013B8B3;  // sltu  x17, x7, x1
            32'd72:  instruction = 32'h00512913;  // slti  x18, x2, 5
            32'd76:  instruction = 32'hFFF13993;  // sltiu x19, x2, -1
            32'd80:  instruction = 32'hFFF0CA13;  // xori  x20, x1, -1
            32'd84:  instruction = 32'h00411A93;  // slli  x21, x2, 4
            32'd88:  instruction = 32'h01C45B13;  // srli  x22, x8, 28
            32'd92:  instruction = 32'h40145B93;  // srai  x23, x8, 1
            // Lesson 6: loads and stores
            32'd96:  instruction = 32'h00302023;  // sw    x3, 0(x0)
            32'd100: instruction = 32'h00702223;  // sw    x7, 4(x0)
            32'd104: instruction = 32'hFF4AAE23;  // sw    x20, -4(x21)
            32'd108: instruction = 32'h00002C03;  // lw    x24, 0(x0)
            32'd112: instruction = 32'h00402C83;  // lw    x25, 4(x0)
            32'd116: instruction = 32'h02C02D03;  // lw    x26, 44(x0)
            32'd120: instruction = 32'h019C0DB3;  // add   x27, x24, x25
            32'd124: instruction = 32'h01BAA023;  // sw    x27, 0(x21)
            32'd128: instruction = 32'h03002E03;  // lw    x28, 48(x0)
            // Lesson 6b: byte and halfword loads and stores
            32'd132: instruction = 32'h02002A23;  // sw    x0, 52(x0)
            32'd136: instruction = 32'h02900A23;  // sb    x9, 52(x0)
            32'd140: instruction = 32'h02D00AA3;  // sb    x13, 53(x0)
            32'd144: instruction = 32'h03401B23;  // sh    x20, 54(x0)
            32'd148: instruction = 32'h03402E83;  // lw    x29, 52(x0)
            32'd152: instruction = 32'h03400F03;  // lb    x30, 52(x0)
            32'd156: instruction = 32'h03404F83;  // lbu   x31, 52(x0)
            32'd160: instruction = 32'h03500283;  // lb    x5, 53(x0)
            32'd164: instruction = 32'h03601303;  // lh    x6, 54(x0)
            32'd168: instruction = 32'h03605383;  // lhu   x7, 54(x0)
            32'd172: instruction = 32'h03401403;  // lh    x8, 52(x0)
            // Lesson 7: a loop (sum of 1..10), then every branch type
            32'd176: instruction = 32'h00000513;  // addi  x10, x0, 0      sum = 0
            32'd180: instruction = 32'h00100593;  // addi  x11, x0, 1      i = 1
            32'd184: instruction = 32'h00B00613;  // addi  x12, x0, 11     limit = 11
            32'd188: instruction = 32'h00B50533;  // add   x10, x10, x11   loop: sum += i
            32'd192: instruction = 32'h00158593;  // addi  x11, x11, 1     i++
            32'd196: instruction = 32'hFEC5CCE3;  // blt   x11, x12, -8    if i < 11, go to loop
            32'd200: instruction = 32'h00000F13;  // addi  x30, x0, 0      wrong-way count = 0
            32'd204: instruction = 32'h00000F93;  // addi  x31, x0, 0      fall-through count = 0
            // Each branch skips the addi after it if taken (+8 = two instructions ahead).
            // "taken" tests skip a x30 += 1; "not taken" tests fall into a x31 += 1.
            32'd208: instruction = 32'h00108463;  // beq   x1, x1, +8      taken
            32'd212: instruction = 32'h001F0F13;  // addi  x30, x30, 1
            32'd216: instruction = 32'h00208463;  // beq   x1, x2, +8      not taken
            32'd220: instruction = 32'h001F8F93;  // addi  x31, x31, 1
            32'd224: instruction = 32'h00209463;  // bne   x1, x2, +8      taken
            32'd228: instruction = 32'h001F0F13;  // addi  x30, x30, 1
            32'd232: instruction = 32'h00109463;  // bne   x1, x1, +8      not taken
            32'd236: instruction = 32'h001F8F93;  // addi  x31, x31, 1
            32'd240: instruction = 32'h00134463;  // blt   x6, x1, +8      taken (-11 < 10)
            32'd244: instruction = 32'h001F0F13;  // addi  x30, x30, 1
            32'd248: instruction = 32'h0060C463;  // blt   x1, x6, +8      not taken
            32'd252: instruction = 32'h001F8F93;  // addi  x31, x31, 1
            32'd256: instruction = 32'h0060D463;  // bge   x1, x6, +8      taken (10 >= -11)
            32'd260: instruction = 32'h001F0F13;  // addi  x30, x30, 1
            32'd264: instruction = 32'h0010D463;  // bge   x1, x1, +8      taken (equal)
            32'd268: instruction = 32'h001F0F13;  // addi  x30, x30, 1
            32'd272: instruction = 32'h00135463;  // bge   x6, x1, +8      not taken
            32'd276: instruction = 32'h001F8F93;  // addi  x31, x31, 1
            32'd280: instruction = 32'h0060E463;  // bltu  x1, x6, +8      taken (FFFFFFF5 is huge)
            32'd284: instruction = 32'h001F0F13;  // addi  x30, x30, 1
            32'd288: instruction = 32'h00136463;  // bltu  x6, x1, +8      not taken
            32'd292: instruction = 32'h001F8F93;  // addi  x31, x31, 1
            32'd296: instruction = 32'h00137463;  // bgeu  x6, x1, +8      taken
            32'd300: instruction = 32'h001F0F13;  // addi  x30, x30, 1
            32'd304: instruction = 32'h00117463;  // bgeu  x2, x1, +8      not taken (3 < 10)
            32'd308: instruction = 32'h001F8F93;  // addi  x31, x31, 1
            // Lesson 8: upper immediates, then a function call with jal and jalr
            32'd312: instruction = 32'h123452B7;  // lui   x5, 0x12345     x5 = 12345000
            32'd316: instruction = 32'h67828293;  // addi  x5, x5, 0x678   x5 = 12345678
            32'd320: instruction = 32'h00001317;  // auipc x6, 0x1         x6 = 320 + 4096
            32'd324: instruction = 32'h00000397;  // auipc x7, 0           x7 = 324 (its own address)
            32'd328: instruction = 32'h00500513;  // addi  x10, x0, 5      argument = 5
            32'd332: instruction = 32'h00C000EF;  // jal   x1, +12         call "double" at 344
            32'd336: instruction = 32'h00050593;  // addi  x11, x10, 0     (after return) x11 = result
            32'd340: instruction = 32'h00C0006F;  // jal   x0, +12         jump over the function
            32'd344: instruction = 32'h00A50533;  // add   x10, x10, x10   double: x10 = x10 * 2
            32'd348: instruction = 32'h00008067;  // jalr  x0, 0(x1)       return to 336
            32'd352: instruction = 32'h00100613;  // addi  x12, x0, 1      marker: got here
            32'd356: instruction = 32'h01D086E7;  // jalr  x13, 29(x1)     go to (336+29) & ~1 = 364
            32'd360: instruction = 32'h06300793;  // addi  x15, x0, 99     must be skipped
            32'd364: instruction = 32'h00700713;  // addi  x14, x0, 7      landed here
            32'd368: instruction = 32'hFFFFF837;  // lui   x16, 0xFFFFF    x16 = FFFFF000
            default: instruction = 32'h00000000;
        endcase
    end

endmodule
