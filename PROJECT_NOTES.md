# RISC-V Processor Project Notes

A RISC-V processor written in Verilog, built one tested module at a time and simulated with Icarus Verilog. Later phases put it on an FPGA and pipeline it.

**Status (October 8, 2026):** Phase 1 complete. `cpu.v` is a working single-cycle processor that runs a 12-instruction program. All 11 testbenches pass.
**Next:** roadmap lesson 5, the ALU upgrade.

**Contents**

1. Verilog quick reference
2. RISC-V quick reference
3. How the processor works
4. Files: what each one does and how
5. Running the tests
6. Testbench patterns and common errors
7. Roadmap
8. Glossary

---

## 1. Verilog quick reference

### Module structure

| Code | What it does |
|---|---|
| `module name ( ...ports... ); ... endmodule` | Defines one hardware block or testbench. Each `.v` file holds one |
| `input wire [31:0] a,` | Input port, 32 bits wide. Commas separate ports; no comma after the last one |
| `output reg [31:0] result` | Output assigned inside an `always` block |
| `output wire [31:0] pc` | Output driven by `assign` or by a submodule |
| `wire [31:0] alu_b;` | Internal connection between parts. Declare before use |
| `reg [31:0] regs [0:31];` | Array: 32 entries of 32 bits (the register file's storage) |
| `localparam OP = 7'b0110011;` | Named constant. For readability only; creates no hardware |
| `alu arithmetic ( .a(x), .b(y) );` | Instance: a copy of module `alu` named `arithmetic`. `.port(signal)` connects by name |
| `.enable(1'b1)` | A port tied to a constant |
| `.write_enable(reg_write && !reset)` | A port connected to an expression; Verilog builds the gates |
| `// text` | Comment |

### Describing logic

| Code | What it does | Where it's used |
|---|---|---|
| `assign y = expression;` | Continuously drives `y`. Pure combinational logic or wiring | Decoder, immediate generator, register file reads, CPU operand mux |
| `always @(*) begin ... end` | Combinational logic written with `if`/`case`. Re-evaluates whenever an input changes | ALU, control unit, instruction memory |
| `always @(posedge clk) begin ... end` | Clocked logic: runs once per rising clock edge. This is how storage is built | Register, register file writes, program counter |
| `=` (blocking) | Assignment for `always @(*)` blocks and testbenches | |
| `<=` (nonblocking) | Assignment for clocked blocks: every register updates together just after the edge | |
| `if (c) ... else ...` | Chooses between statements | |
| `case (x) A: ...; default: ...; endcase` | Chooses by value; `default` covers all unlisted values | |
| `begin ... end` | Groups several statements where one is expected | |
| `c ? a : b` | Multiplexer: `a` when `c` is true, otherwise `b` | |

### Operators and bit manipulation

| Code | Meaning | Example |
|---|---|---|
| `+`, `-` | Add, subtract. Results wrap around at 32 bits | `FFFFFFFF + 1 = 0` |
| `&`, `\|`, `~` | Bitwise AND, OR, NOT | `1010 & 0011 = 0010` |
| `&&`, `\|\|`, `!` | Logical AND, OR, NOT, for conditions | `reg_write && !reset` |
| `==`, `!=` | Equal, not equal | `write_addr != 5'd0` |
| `sig[11:7]` | Part-select: bits 11 down to 7 (5 bits) | `rd = instruction[11:7]` |
| `{a, b}` | Concatenation: joins bits, `a` on top | `{funct7, funct3}` is 10 bits |
| `{20{bit}}` | Replication: 20 copies of `bit` | Sign extension |

### Numbers

| Code | Meaning |
|---|---|
| `32'd10` | 32 bits, decimal 10 |
| `7'b0110011` | 7 bits, binary |
| `32'hFFFFFFF9` | 32 bits, hexadecimal (this pattern means -7) |
| `10'b0000000_000` | Underscores are ignored; they just group digits |
| `x`, `32'bx` | Unknown. Registers are `x` in simulation until written |

Numbers use an apostrophe `'`. A backtick `` ` `` starts a directive such as `` `timescale ``.

### Testbench-only code

| Code | What it does |
|---|---|
| `` `timescale 1ns/1ps `` | Makes `#1` mean 1 nanosecond |
| `initial begin ... end` | Runs once from time 0; holds the test steps |
| `#10;` | Wait 10 ns |
| `always #5 clk = ~clk;` | Clock: flips every 5 ns, giving a rising edge every 10 ns |
| `@(posedge clk);`, `@(negedge clk);` | Wait for the next rising or falling edge |
| `repeat (15) @(posedge clk);` | Wait for 15 rising edges |
| `if (out !== expected) $fatal(1, "msg");` | Check a result; stop with an error if wrong. `!==` also fails on `x` |
| `$display("x%0d = %h", n, v);` | Print. `%h` hex, `%d` decimal, `%0d` no padding, `%2d` 2 characters wide |
| `$signed(v)` | Print `v` as signed (`FFFFFFF9` prints as -7) |
| `$finish;` | End the simulation |
| `task check (inputs); begin ... end endtask` | Reusable test steps, called like `check(a, b, c);` |
| `dut.registers.regs[3]` | Hierarchical reference: read a signal inside the design (simulation only) |
| `$dumpfile("x.vcd"); $dumpvars(0, x_tb);` | Record waveforms for GTKWave (optional) |

### Three rules that prevent most bugs

1. **In `always @(*)`, give every output a value on every path.** Set defaults at the top, then override in `case`/`if`. A missed path makes the output "remember" its old value, which creates a latch (unintended storage).
2. **Use `<=` in `always @(posedge clk)` and `=` in `always @(*)`.**
3. **Declare every wire before using it.** A misspelled name in a port connection silently becomes a new 1-bit wire. Read compiler warnings: they usually point at typos.

---

## 2. RISC-V quick reference

### Registers

32 registers, `x0` through `x31`, each 32 bits. `x0` always reads 0, and writes to it are ignored.

### Instruction fields

Every instruction is 32 bits, split into fields at fixed positions:

| Bits | 31:25 | 24:20 | 19:15 | 14:12 | 11:7 | 6:0 |
|---|---|---|---|---|---|---|
| R-type (`add`, `sub`, ...) | funct7 | rs2 | rs1 | funct3 | rd | opcode |
| I-type (`addi`, ...) | imm[11:5] | imm[4:0] | rs1 | funct3 | rd | opcode |

- **opcode:** the kind of instruction.
- **rd:** the destination register, where the result goes.
- **rs1**, **rs2:** the source registers.
- **funct3**, **funct7:** select the exact operation.
- **imm:** a constant stored inside the instruction (the "immediate").

The register fields sit in the same place in every format, so the decoder can slice them without knowing the format. In I-type instructions, the bits in the `rs2` and `funct7` positions are really part of the immediate.

### Instructions the processor supports

| Instruction | Does | opcode | funct3 | funct7 |
|---|---|---|---|---|
| `add rd, rs1, rs2` | rd = rs1 + rs2 | `0110011` | `000` | `0000000` |
| `sub rd, rs1, rs2` | rd = rs1 - rs2 | `0110011` | `000` | `0100000` |
| `and rd, rs1, rs2` | rd = rs1 AND rs2 | `0110011` | `111` | `0000000` |
| `or rd, rs1, rs2` | rd = rs1 OR rs2 | `0110011` | `110` | `0000000` |
| `addi rd, rs1, imm` | rd = rs1 + imm | `0010011` | `000` | (immediate bits) |
| `andi rd, rs1, imm` | rd = rs1 AND imm | `0010011` | `111` | (immediate bits) |
| `ori rd, rs1, imm` | rd = rs1 OR imm | `0010011` | `110` | (immediate bits) |

Any other instruction does nothing: no register is written. `addi rd, x0, value` is how a program loads a constant, since x0 is always 0.

### Encoding example

`add x3, x1, x2` packs funct7 `0000000`, rs2 `00010`, rs1 `00001`, funct3 `000`, rd `00011`, and opcode `0110011`. The result is `0000 0000 0010 0000 1000 0001 1011 0011` = `32'h002081B3`. The web page rvcodec.js (luplab.gitlab.io/rvcodecjs) converts between assembly and hex.

### Signed numbers

- **Two's complement:** the top bit is the sign. -1 is all ones (`FFFFFFFF`), and -7 is `FFFFFFF9`. The same adder handles signed and unsigned values; only the interpretation differs.
- **Sign extension:** widen a signed value by copying its sign bit into the new upper bits. The 12-bit -3 (`FFD`) becomes `FFFFFFFD`. Zero-filling would give `00000FFD`, which is 4093 and wrong.

---

## 3. How the processor works

Every instruction goes through the same steps:

| Step | What happens | Files |
|---|---|---|
| Fetch | The PC supplies an address; instruction memory returns the instruction stored there | `program_counter.v`, `instruction_memory.v`, `instruction_fetch.v` |
| Decode | Slice the fields, read registers rs1 and rs2, build the immediate, and choose control signals | `instruction_decoder.v`, `register_file.v`, `immediate_generator.v`, `control_unit.v` |
| Execute | The ALU computes the result | `alu.v` |
| Memory | Loads and stores access data memory | Not yet (lesson 6) |
| Write back | The result is stored in register rd | `register_file.v` |
| Next | The PC advances by 4 | `program_counter.v` |

```
       +------+  address   +--------------------+
  +--->|  PC  |----------->| instruction_memory |
  |    +------+            +--------------------+
  |       |                          | instruction
  +--+4---+                          v
                  +----------------------------------------+
                  |  instruction_decoder                   |
                  |  immediate_generator                   |
                  +----------------------------------------+
                    rs1 |    rs2 |   immediate |    opcode, funct3, funct7 |
                        v        v             |                           v
                  +---------------------+      |                 +--------------+
                  |    register_file    |      |                 | control_unit |
                  +---------------------+      |                 +--------------+
                    value1 |   value2 |        |                   alu_src, alu_op,
                           |          v        v                   reg_write
                           |     +-------------------+
                           |     | mux: value2 or    |<-- alu_src
                           |     |      immediate    |
                           |     +-------------------+
                           v               v
                        +----------------------+
                        |         alu          |<-- alu_op
                        +----------------------+
                                   | result
                                   v
                register_file write port: register rd <- result
                (at the rising edge, only when reg_write = 1)
```

**Single-cycle:** between two rising clock edges, signals flow through the combinational parts. At the next rising edge, the register file stores the result in rd and the PC advances to the next instruction. One instruction completes per clock cycle. In real hardware, the clock period must be longer than the slowest path through this chain, called the critical path.

**Example:** `add x3, x1, x2` at address 8.

1. **Fetch:** PC = 8, so memory outputs `002081B3`.
2. **Decode:** rs1 = 1, rs2 = 2, rd = 3. The control unit sets `alu_src` = 0 (use the register) and `alu_op` = add, and enables the write.
3. **Execute:** the ALU adds x1 + x2.
4. **Write back:** at the rising edge, x3 receives 13 and the PC becomes 12.

---

## 4. Files: what each one does and how

| File | Responsibility | Kind of logic | Part of the CPU? |
|---|---|---|---|
| `cpu.v` | Connects every part into the processor | Structure only | Top level |
| `program_counter.v` | Holds the current instruction's address | Clocked | Yes |
| `instruction_memory.v` | Holds the program | Combinational | Yes |
| `instruction_fetch.v` | Connects the PC to instruction memory | Structure only | Yes |
| `instruction_decoder.v` | Splits an instruction into fields | Wiring | Yes |
| `immediate_generator.v` | Extracts and sign-extends the constant | Wiring | Yes |
| `control_unit.v` | Decides what each instruction does | Combinational | Yes |
| `register_file.v` | Stores x0 through x31 | Combinational reads, clocked writes | Yes |
| `alu.v` | Computes add, subtract, AND, OR | Combinational | Yes |
| `register.v` | One 32-bit register (practice module) | Clocked | No |
| `datapath.v` | Register file and ALU controlled by a testbench (practice module) | Structure only | No |

Every `name_tb.v` file is the testbench for `name.v`. Each testbench prints `All ... tests passed!` when every check succeeds, or stops at the first failure with a message.

### `cpu.v`: the processor

**Responsibility:** connect all the parts so instructions run on their own. Its only inputs are `clk` and `reset`.

**How it works:**

- It instantiates `instruction_fetch`, `instruction_decoder`, `immediate_generator`, `control_unit`, `register_file`, and `alu`, connecting them with wires. It has no `always` block; all storage lives inside the PC and the register file.
- `.enable(1'b1)` on the fetch unit makes the PC advance every cycle.
- **The operand mux** is the one new piece of logic. It picks the ALU's second input: the register value for R-type, the immediate for I-type.

  ```verilog
  assign alu_b = alu_src ? immediate : rs2_value;
  ```

- **The ALU result goes straight to the register file's write port**, and `rd` selects the destination.
- **Register writes are blocked during reset.** While reset is held, the PC sits at 0 with the first instruction showing. Without this gate, that instruction would execute on every reset cycle.

  ```verilog
  .write_enable(reg_write && !reset),
  ```

| Wire | Driven by | Goes to |
|---|---|---|
| `pc`, `instruction` | `instruction_fetch` | Decoder and immediate generator; also module outputs |
| `opcode`, `funct3`, `funct7` | Decoder | Control unit |
| `rs1`, `rs2`, `rd` | Decoder | Register file read and write addresses |
| `immediate` | Immediate generator | Operand mux |
| `reg_write`, `alu_src`, `alu_op` | Control unit | Register file write enable, operand mux, ALU |
| `rs1_value`, `rs2_value` | Register file | ALU input `a`, operand mux |
| `alu_b` | Operand mux | ALU input `b` |
| `alu_result` | ALU | Register file write data |

**Tested by `cpu_tb.v`:**

- **Reset:** holds reset for 3 clock edges, then checks that PC = 0 and that no register was written.
- **Running the program:** releases reset and runs 15 cycles (12 instructions, then 3 cycles of empty memory). It then checks PC = 60 and registers x1 through x11.
- **Trace:** prints each register write as it happens:

```
pc= 0  00a00093  x1 <= 10
pc= 4  00300113  x2 <= 3
pc= 8  002081b3  x3 <= 13
pc=12  40208233  x4 <= 7
pc=16  0020f2b3  x5 <= 2
pc=20  0020e333  x6 <= 11
pc=24  401103b3  x7 <= -7
pc=28  fff38413  x8 <= -8
pc=32  0ff47493  x9 <= 248
pc=36  00c16513  x10 <= 15
pc=40  00108033  write to x0 ignored
pc=44  003005b3  x11 <= 13
All CPU tests passed!
```

The trace and the register checks use hierarchical references (`dut.reg_write`, `dut.registers.regs[3]`) to see inside the processor.

### `program_counter.v`: where we are in the program

**Responsibility:** hold the address of the current instruction.

**How it works:** on each rising edge, reset sets the PC to 0. Otherwise, if `enable` is 1, the PC adds 4, because each instruction is 4 bytes and addresses count bytes. Reset comes first, so it wins over `enable`. It is synchronous: it waits for the clock edge.

```verilog
always @(posedge clk) begin
    if (reset)
        pc <= 32'd0;
    else if (enable)
        pc <= pc + 32'd4;
end
```

**Tested by `program_counter_tb.v`:**
- Resets to 0.
- Counts 0, 4, 8.
- Holds its value when `enable` is 0.
- Reset waits for the clock edge.
- Reset overrides `enable`.

Branches (lesson 7) will add the ability to load a new address instead of adding 4.

### `instruction_memory.v`: the program

**Responsibility:** return the 32-bit instruction stored at a given address.

**How it works:** a `case` on the address acts as read-only memory (ROM). Addresses go up by 4 because each instruction is 4 bytes. Any address not listed returns `00000000`, which the control unit treats as "do nothing". The read is combinational: a new address gives a new instruction immediately, with no clock.

The current program:

| Address | Hex | Assembly | Result |
|---|---|---|---|
| 0 | `00A00093` | `addi x1, x0, 10` | x1 = 10 |
| 4 | `00300113` | `addi x2, x0, 3` | x2 = 3 |
| 8 | `002081B3` | `add x3, x1, x2` | x3 = 13 |
| 12 | `40208233` | `sub x4, x1, x2` | x4 = 7 |
| 16 | `0020F2B3` | `and x5, x1, x2` | x5 = 2 |
| 20 | `0020E333` | `or x6, x1, x2` | x6 = 11 |
| 24 | `401103B3` | `sub x7, x2, x1` | x7 = -7 |
| 28 | `FFF38413` | `addi x8, x7, -1` | x8 = -8 |
| 32 | `0FF47493` | `andi x9, x8, 255` | x9 = 248 |
| 36 | `00C16513` | `ori x10, x2, 12` | x10 = 15 |
| 40 | `00108033` | `add x0, x1, x1` | x0 stays 0 |
| 44 | `003005B3` | `add x11, x0, x3` | x11 = 13 (proves x0 still reads 0) |

**Tested by `instruction_memory_tb.v`:**
- The first four addresses return the right instructions.
- Address 48, just past the program, returns 0.
- Moving back to an earlier address works.

Lesson 9 replaces the hand-written `case` with a memory loaded from a file produced by a real assembler.

### `instruction_fetch.v`: fetch unit

**Responsibility:** combine the PC and instruction memory, so each clock edge brings the next instruction.

**How it works:** the PC's output wire `pc` connects to the memory's `address` input. The memory's output becomes `instruction`. There is no logic of its own, just two instances and the wires between them.

**Tested by `instruction_fetch_tb.v`:** checks each PC value together with its instruction:
- Reset gives 0 and `00A00093`.
- The PC advances to 4 and then 8.
- Both values hold when disabled.
- The PC resumes to 12, then 16.
- Reset returns to 0.

### `instruction_decoder.v`: splitting the instruction

**Responsibility:** cut the 32-bit instruction into named fields.

**How it works:** six `assign` part-selects. It is pure wiring, with no gates and no clock. It always slices every field; the control unit decides which ones matter.

```verilog
assign opcode = instruction[6:0];
assign rd     = instruction[11:7];
assign funct3 = instruction[14:12];
assign rs1    = instruction[19:15];
assign rs2    = instruction[24:20];
assign funct7 = instruction[31:25];
```

**Tested by `instruction_decoder_tb.v`:**
- **`add`:** every field lands in the right output.
- **`sub`:** only `funct7` differs from `add`.
- **`or x31, x30, x29`:** the largest register numbers work.
- **`addi`:** the "rs2" slice holds immediate bits.

### `immediate_generator.v`: the constant inside the instruction

**Responsibility:** produce the instruction's 12-bit immediate as a 32-bit signed value.

**How it works:** it copies the sign bit (instruction bit 31) into the upper 20 bits, above the 12 immediate bits. Positive numbers get leading zeros and negative numbers get leading ones, so the value is preserved.

```verilog
assign immediate = {{20{instruction[31]}}, instruction[31:20]};
```

**Tested by `immediate_generator_tb.v`:**
- 10 and -3: positive and negative values.
- 2047 and -2048: the largest and smallest 12-bit values.
- An instruction with all-ones register fields: confirms no other bits leak into the result.

Later lessons extend this for the other formats (stores, branches, jumps). In every format, bit 31 is the sign bit.

### `control_unit.v`: deciding what to do

**Responsibility:** turn `opcode`, `funct3`, and `funct7` into the three control signals.

| Output | 0 means | 1 means |
|---|---|---|
| `reg_write` | Write nothing | Store the result in rd |
| `alu_src` | Second ALU input is register rs2 | Second ALU input is the immediate |
| `alu_op` (2 bits) | `00` add, `01` sub, `10` AND, `11` OR (matches `alu.v`) | |

**How it works:**

- **Defaults first:** `reg_write = 0`, `alu_src = 0`, `alu_op = add`. Every output has a value on every path (no latches), and unknown instructions write nothing.
- **`case (opcode)`** picks R-type (`OP`) or I-type (`OP_IMM`), using `localparam` names.
- **R-type** checks `{funct7, funct3}` as one 10-bit value. All 7 funct7 bits must match, so that `mul` (same opcode and funct3 as `add`, but funct7 `0000001`) is rejected instead of running as `add`.
- **I-type** checks only `funct3` and ignores `funct7`, because those bits belong to the immediate. For example, `addi x1, x0, 1024` has `0100000` there, the same pattern as `sub`.

```verilog
case ({funct7, funct3})
    10'b0000000_000: begin reg_write = 1'b1; alu_op = ALU_ADD; end  // add
    10'b0100000_000: begin reg_write = 1'b1; alu_op = ALU_SUB; end  // sub
    ...
```

**Tested by `control_unit_tb.v`:** the test uses the decoder to turn 12 real instructions into fields, and a `check` task compares all three outputs for each one:
- `add`, `sub`, `and`, `or`
- `addi` (including `addi 1024`), `andi`, `ori`
- Unsupported instructions, which must not write: `xor`, `mul`, `lw`, and the empty word `00000000`

### `register_file.v`: the 32 registers

**Responsibility:** store x0 through x31. Provide two values at once (rs1 and rs2) and accept one write per clock cycle.

**How it works:**

- An array `reg [31:0] regs [0:31]` holds the values.
- **Reads** are `assign` statements: combinational, with no clock. Address 0 always returns 0.
- **Writes** happen in `always @(posedge clk)` when `write_enable` is 1, and never to address 0.

```verilog
assign read_data1 = (read_addr1 == 5'd0) ? 32'd0 : regs[read_addr1];

always @(posedge clk) begin
    if (write_enable && (write_addr != 5'd0))
        regs[write_addr] <= write_data;
end
```

There is no reset. Registers are `x` (unknown) in simulation until a program writes them.

**Tested by `register_file_tb.v`:**
- x0 reads 0.
- Writes appear only after the clock edge.
- Both read ports work at the same time.
- Reads change immediately when the address changes.
- Disabled writes change nothing.
- Writes to x0 are ignored.
- x31 works.

### `alu.v`: arithmetic and logic

**Responsibility:** compute a 32-bit result from two inputs.

**How it works:** an `always @(*)` with a `case` on `alu_op`:

```verilog
case (alu_op)
    2'b00: result = a + b;
    2'b01: result = a - b;
    2'b10: result = a & b;
    2'b11: result = a | b;
    default: result = 32'b0;
endcase
```

Results wrap at 32 bits: `FFFFFFFF + 1 = 0`, and `3 - 10 = FFFFFFF9`, which is -7. Lesson 5 widens `alu_op` to 4 bits and adds XOR, shifts, and comparisons.

**Tested by `alu_tb.v`:**
- All four operations, using 10 and 3.
- The wrap-around `FFFFFFFF + 1`.
- The negative result `3 - 10`.

### `register.v` (practice module, not in the CPU)

**Responsibility:** store one 32-bit value. This was the first clocked-storage lesson.

**How it works:** at each rising edge, reset clears `q`. Otherwise, if `write_enable` is 1, it captures `d`. With no assignment, `q` keeps its value: that is storage. The program counter uses the same pattern.

**Tested by `register_tb.v`:**
- Reset works.
- Values are captured only on the clock edge.
- The value holds between edges and when writing is disabled.
- Reset overrides writing.

### `datapath.v` (practice module, not in the CPU)

**Responsibility:** the first combination of the register file and the ALU, with a testbench acting as the control unit.

**How it works:** register read outputs feed the ALU, and the ALU result feeds the register write port. A `load_external` mux lets the testbench load starting values. `cpu.v` replaced this design: there, `addi` loads constants and the control unit drives the controls.

**Tested by `datapath_tb.v`:**
- Loads x1 = 10 and x2 = 3.
- Stores x1 + x2 into x5.
- Reads x5 back as 13.

---

## 5. Running the tests

Open a PowerShell terminal in VS Code. Run these once per terminal session:

```powershell
cd "C:\CODE\Softcore RISC-V Processor"
$iv  = "C:\Engineering Software\iverilog\bin\iverilog.exe"
$vvp = "C:\Engineering Software\iverilog\bin\vvp.exe"
```

Each test is then two steps: compile, and only if that succeeds, run. For example:

```powershell
& $iv -g2012 -s cpu_tb -o cpu_sim alu.v register_file.v program_counter.v instruction_memory.v instruction_fetch.v instruction_decoder.v immediate_generator.v control_unit.v cpu.v cpu_tb.v
& $vvp cpu_sim
```

| Part | Meaning |
|---|---|
| `& $iv` | Run the compiler stored in `$iv` |
| `-g2012` | Use the SystemVerilog 2012 language mode |
| `-s cpu_tb` | The top module (the testbench's module name) |
| `-o cpu_sim` | Name of the compiled output |
| `alu.v ... cpu_tb.v` | Every file the testbench needs, including modules used inside other modules |
| `& $vvp cpu_sim` | Run the compiled simulation |

Save files before compiling, since the compiler reads what's on disk. Never run an old `_sim` after a failed compile.

All compile commands (after each, run `& $vvp <name>_sim`):

```powershell
& $iv -g2012 -s alu_tb -o alu_sim alu.v alu_tb.v
& $iv -g2012 -s register_tb -o register_sim register.v register_tb.v
& $iv -g2012 -s register_file_tb -o register_file_sim register_file.v register_file_tb.v
& $iv -g2012 -s datapath_tb -o datapath_sim alu.v register_file.v datapath.v datapath_tb.v
& $iv -g2012 -s program_counter_tb -o program_counter_sim program_counter.v program_counter_tb.v
& $iv -g2012 -s instruction_memory_tb -o instruction_memory_sim instruction_memory.v instruction_memory_tb.v
& $iv -g2012 -s instruction_fetch_tb -o instruction_fetch_sim program_counter.v instruction_memory.v instruction_fetch.v instruction_fetch_tb.v
& $iv -g2012 -s instruction_decoder_tb -o instruction_decoder_sim instruction_decoder.v instruction_decoder_tb.v
& $iv -g2012 -s immediate_generator_tb -o immediate_generator_sim immediate_generator.v immediate_generator_tb.v
& $iv -g2012 -s control_unit_tb -o control_unit_sim instruction_decoder.v control_unit.v control_unit_tb.v
& $iv -g2012 -s cpu_tb -o cpu_sim alu.v register_file.v program_counter.v instruction_memory.v instruction_fetch.v instruction_decoder.v immediate_generator.v control_unit.v cpu.v cpu_tb.v
```

**Generated files:** `_sim` files (compiled tests) and `.vcd` files (waveforms) are outputs. Deleting them is harmless; compiling or running recreates them. Only `alu_tb`, `register_tb`, `register_file_tb`, `datapath_tb`, and `program_counter_tb` write `.vcd` files.

**Waveforms (optional):** open a `.vcd` file in GTKWave. Select the testbench scope, append signals, and use Zoom Fit to see the whole run.

**Shorter commands (optional):** to type `iverilog` and `vvp` directly, add `C:\Engineering Software\iverilog\bin` to your user PATH. Search Windows for "Edit environment variables for your account", choose Path, then Edit > New. Restart VS Code afterward.

---

## 6. Testbench patterns and common errors

### Patterns used in every testbench

| Pattern | Why |
|---|---|
| Inputs are `reg`, outputs are `wire`, and the design is instantiated as `dut` | The testbench drives inputs and watches outputs |
| Change inputs on the falling edge (`@(negedge clk)`) | They are settled before the next rising edge samples them |
| After a rising edge, wait `#1;` before checking | Lets the `<=` updates finish |
| Combinational tests: set inputs, `#10;`, check | No clock needed |
| Compare with `!==`, not `!=` | `!=` treats an unknown (`x`) result as "not different", so a broken output would pass |
| Use a `task` for repeated checks | One line per test case |
| Re-run every test after changing a module (regression testing) | Catches anything the change broke, including tests that need new expected values |
| Try a deliberately broken module once | If the test doesn't fail, it isn't really checking that behavior |

### Common errors

| Symptom | Fix |
|---|---|
| `iverilog` is not recognized | Use the full path, the `$iv` variable, or fix PATH |
| Unable to find root module | Check the file is saved and `-s` matches the module name |
| Macro `d0` undefined | A backtick was used in a number; write `32'd0` with an apostrophe |
| Many errors after one line | Fix the first error; the rest often follow from it |
| `input wire clk.` | Ports end with commas, not periods |
| Comma after the last port | Remove it; commas only separate ports |
| Misspelled `intital`, or a missing `;` | Typos; check the line the compiler names |
| A failure message shows `xxxxxxxx` | That register or signal was never written or connected |
| Port width warning | Usually a misspelled wire name that became a 1-bit wire |

---

## 7. Roadmap

| Phase | # | Lesson | Status |
|---|---|---|---|
| 1. First real instructions | 1 | `instruction_decoder.v` | Done |
| | 2 | `immediate_generator.v` | Done |
| | 3 | `control_unit.v` | Done |
| | 4 | `cpu.v`: the complete processor | Done (October 8, 2026) |
| 2. Complete RV32I | 5 | ALU upgrade: XOR, shifts, comparisons; 4-bit `alu_op` | **Next** |
| | 6 | `data_memory.v`: loads and stores | |
| | 7 | Branches: `beq`, `bne`, `blt`, `bge`, `bltu`, `bgeu` | |
| | 8 | Jumps and upper immediates: `jal`, `jalr`, `lui`, `auipc` | |
| | 9 | Load programs from a hex file built by a real assembler | |
| | 10 | Run the official RISC-V test suite (rv32ui) | |
| 3. FPGA | 11 | Synthesis, pin constraints, clock | |
| | 12 | Adapt memories to FPGA block RAM (clocked reads) | |
| | 13 | LEDs, then text output over a serial (UART) link | |
| 4. Pipelining | 14 | Five-stage pipeline | |
| | 15 | Hazards: forwarding, stalls, branch flushes | |

**Hardware target:** an FPGA, not an ESP32. An ESP32's processor is fixed silicon. It can run software, but it can't become the circuit our Verilog describes. An FPGA's logic is configurable, which is what a "softcore" needs.
- **Recommended:** Sipeed Tang Nano 20K (about $25-40, small toolchain).
- **Alternative:** Digilent Basys 3 (about $150+, the most tutorials, but its Vivado software needs tens of GB).

Nothing needs buying until Phase 3.

---

## 8. Glossary

| Term | Meaning |
|---|---|
| ALU | Arithmetic logic unit: computes add, subtract, AND, OR, and so on |
| Combinational logic | Output depends only on current inputs: no clock, no memory |
| Clocked (sequential) logic | Logic with storage that updates on clock edges |
| Control signals | Wires that steer the datapath: which ALU operation, which operand, whether to write |
| Critical path | The slowest combinational path; it limits the clock speed |
| Datapath | The parts that hold and move data: registers, ALU, multiplexers, memories |
| DUT | Device under test: the module a testbench checks |
| Extension (RISC-V) | An optional instruction group, such as M for multiply/divide |
| FPGA | A chip of configurable logic that can become the circuit described in Verilog |
| Hierarchical reference | A testbench path like `dut.registers.regs[3]` that reaches inside a design |
| Immediate | A constant stored inside an instruction |
| ISA | Instruction set architecture: the definition of instructions and their encodings. RISC-V is one |
| Latch | Unintended storage, created when a combinational block leaves an output unassigned |
| Multiplexer (mux) | Selects one of several inputs, like `sel ? a : b` |
| Opcode | Instruction bits 6:0; identify the kind of instruction |
| Pipelining | Overlapping instructions in stages so several are in progress at once |
| Program counter (PC) | Holds the address of the current instruction |
| Register file | The 32 registers x0-x31 with their read and write ports |
| Regression testing | Re-running all existing tests after a change |
| ROM | Read-only memory |
| RV32I | The 32-bit RISC-V base integer instruction set: our target |
| Sign extension | Widening a signed number by copying its sign bit |
| Single-cycle | Every instruction completes in one clock cycle |
| Softcore | A processor built from FPGA logic rather than fixed silicon |
| Synthesis | Turning Verilog into real hardware |
| Task | A reusable block of testbench steps |
| Testbench | Simulation-only code that drives a design and checks its outputs |
| Trace | A printed, cycle-by-cycle record of what the design did |
| Two's complement | The standard signed-number format; -1 is all ones |
| VCD | Waveform file viewed in GTKWave |
