
`ifndef CPU_ASSERTIONS_SV
`define CPU_ASSERTIONS_SV

// ============================================================
// 1. PROGRAM COUNTER ASSERTIONS
// ============================================================

module pc_sva (
    input logic clk,
    input logic reset_n,
    input logic PCWrite,
    input logic [7:0] next_pc,
    input logic [7:0] pc
);

    // PC must hold its value when PCWrite is low.
    a_pc_hold: assert property (
        @(posedge clk)
        disable iff (reset_n !== 1'b1)
        !PCWrite |=> $stable(pc)
    )
    else $error("SVA: PC changed when PCWrite was low");

    // PC must update using next_pc when PCWrite is high.
    a_pc_update: assert property (
        @(posedge clk)
        disable iff (reset_n !== 1'b1)
        PCWrite |=> (pc == $past(next_pc))
    )
    else $error("SVA: PC did not update correctly");

    // PC must be zero during reset.
    a_pc_reset: assert property (
        @(posedge clk)
        (reset_n === 1'b0) |-> (pc == 8'd0)
    )
    else $error("SVA: PC did not reset to zero");

endmodule


// ============================================================
// 2. CONTROL UNIT ASSERTIONS
// ============================================================

module control_unit_sva (
    input logic clk,
    input logic reset_n,

    input logic [3:0] state,

    input logic IRWrite,
    input logic PCWrite,
    input logic AWrite,
    input logic BWrite,
    input logic ALUOutWrite,
    input logic MDRWrite,
    input logic RegWrite,
    input logic MemRead,
    input logic MemWrite,
    input logic MemToReg,
    input logic ALUSrc,
    input logic Jump,
    input logic BranchTaken,
    input logic Halted
);

    localparam S_FETCH     = 4'd0;
    localparam S_DECODE    = 4'd1;
    localparam S_EXEC_R    = 4'd2;
    localparam S_WB_R      = 4'd3;
    localparam S_EXEC_I    = 4'd4;
    localparam S_WB_I      = 4'd5;
    localparam S_MEM_ADDR  = 4'd6;
    localparam S_MEM_READ  = 4'd7;
    localparam S_WB_LD     = 4'd8;
    localparam S_MEM_WRITE = 4'd9;
    localparam S_BRANCH    = 4'd10;
    localparam S_JUMP      = 4'd11;
    localparam S_HALT      = 4'd12;

    // FSM state must be legal.
    a_cu_state_legality: assert property (
        @(posedge clk)
        disable iff (reset_n !== 1'b1)
        !$isunknown(state) &&
        (state inside {[4'd0:4'd12]})
    )
    else $error("SVA: FSM state is illegal");

    // Halted must correspond to the HALT state.
    a_cu_halt_indication: assert property (
        @(posedge clk)
        disable iff (reset_n !== 1'b1)
        Halted == (state == S_HALT)
    )
    else $error("SVA: Halted indication does not match FSM state");

    // IRWrite is allowed only in FETCH.
    a_cu_irwrite: assert property (
        @(posedge clk)
        disable iff (reset_n !== 1'b1)
        IRWrite |-> (state == S_FETCH)
    )
    else $error("SVA: IRWrite asserted outside FETCH");

    // AWrite and BWrite are allowed only in DECODE.
    a_cu_abwrite: assert property (
        @(posedge clk)
        disable iff (reset_n !== 1'b1)
        (AWrite || BWrite) |-> (state == S_DECODE)
    )
    else $error("SVA: AWrite or BWrite asserted outside DECODE");

    // RegWrite is allowed only in writeback states.
    a_cu_regwrite: assert property (
        @(posedge clk)
        disable iff (reset_n !== 1'b1)
        RegWrite |-> (
            (state == S_WB_R) ||
            (state == S_WB_I) ||
            (state == S_WB_LD)
        )
    )
    else $error("SVA: RegWrite asserted in an invalid state");

    // MemRead is allowed only in MEM_READ.
    a_cu_memread: assert property (
        @(posedge clk)
        disable iff (reset_n !== 1'b1)
        MemRead |-> (state == S_MEM_READ)
    )
    else $error("SVA: MemRead asserted outside MEM_READ");

    // MemWrite is allowed only in MEM_WRITE.
    a_cu_memwrite: assert property (
        @(posedge clk)
        disable iff (reset_n !== 1'b1)
        MemWrite |-> (state == S_MEM_WRITE)
    )
    else $error("SVA: MemWrite asserted outside MEM_WRITE");

    // Memory read and write must not occur together.
    a_cu_mem_access_exclusivity: assert property (
        @(posedge clk)
        disable iff (reset_n !== 1'b1)
        !(MemRead && MemWrite)
    )
    else $error("SVA: MemRead and MemWrite asserted simultaneously");

    // Jump is allowed only in JUMP.
    a_cu_jump: assert property (
        @(posedge clk)
        disable iff (reset_n !== 1'b1)
        Jump |-> (state == S_JUMP)
    )
    else $error("SVA: Jump asserted outside JUMP");

    // BranchTaken is allowed only in BRANCH.
    a_cu_branch: assert property (
        @(posedge clk)
        disable iff (reset_n !== 1'b1)
        BranchTaken |-> (state == S_BRANCH)
    )
    else $error("SVA: BranchTaken asserted outside BRANCH");

    // ALUOutWrite is allowed in execution/address states.
    a_cu_aluoutwrite: assert property (
        @(posedge clk)
        disable iff (reset_n !== 1'b1)
        ALUOutWrite |-> (
            (state == S_EXEC_R) ||
            (state == S_EXEC_I) ||
            (state == S_MEM_ADDR)
        )
    )
    else $error("SVA: ALUOutWrite asserted in an invalid state");

    // MDRWrite is allowed only in MEM_READ.
    a_cu_mdrwrite: assert property (
        @(posedge clk)
        disable iff (reset_n !== 1'b1)
        MDRWrite |-> (state == S_MEM_READ)
    )
    else $error("SVA: MDRWrite asserted outside MEM_READ");

endmodule


// ============================================================
// 3. REGISTER FILE ASSERTIONS
// ============================================================

module register_file_sva (
    input logic clk,
    input logic reset_n,

    input logic RegWrite,
    input logic [2:0] write_addr,
    input logic [15:0] write_data,

    input logic [2:0] read_addr1,
    input logic [2:0] read_addr2,

    input logic [15:0] read_data1,
    input logic [15:0] read_data2,

    input logic [15:0] registers [0:7]
);

    // R0 must return zero on read port 1.
    a_rf_r0_read1: assert property (
        @(posedge clk)
        disable iff (reset_n !== 1'b1)
        (read_addr1 == 3'd0) |-> (read_data1 == 16'd0)
    )
    else $error("SVA: R0 read port 1 did not return zero");

    // R0 must return zero on read port 2.
    a_rf_r0_read2: assert property (
        @(posedge clk)
        disable iff (reset_n !== 1'b1)
        (read_addr2 == 3'd0) |-> (read_data2 == 16'd0)
    )
    else $error("SVA: R0 read port 2 did not return zero");

    // R0 must always remain zero internally.
    a_rf_r0_write_protection: assert property (
        @(posedge clk)
        disable iff (reset_n !== 1'b1)
        (registers[0] == 16'd0)
    )
    else $error("SVA: R0 is not retained to zero");

    // A valid write must update the selected register.
    a_rf_register_write: assert property (
        @(posedge clk)
        disable iff (reset_n !== 1'b1)
        (RegWrite && (write_addr != 3'd0))
        |=> (registers[$past(write_addr)] == $past(write_data))
    )
    else $error("SVA: Register write operation failed");

    // Every register must be zero during reset.
    generate
        for (genvar i = 0; i < 8; i++) begin : g_rf_reset

            a_rf_reset: assert property (
                @(posedge clk)
                (reset_n === 1'b0) |-> (registers[i] == 16'd0)
            )
            else $error("SVA: Register did not reset to zero");

        end
    endgenerate

endmodule


// ============================================================
// 4. ALU ASSERTIONS
// ============================================================

module alu_sva (
    input logic clk,
    input logic reset_n,

    input logic [3:0] state,

    input logic [15:0] operand_a,
    input logic [15:0] operand_b,

    input logic [3:0] ALUCtrl,

    input logic [15:0] result,
    input logic zero
);

    localparam S_EXEC_R   = 4'd2;
    localparam S_EXEC_I   = 4'd4;
    localparam S_MEM_ADDR = 4'd6;
    localparam S_BRANCH   = 4'd10;

    // ALU is active only in these execution states.
    wire alu_active =
        (state == S_EXEC_R)   ||
        (state == S_EXEC_I)   ||
        (state == S_MEM_ADDR) ||
        (state == S_BRANCH);

    // ADD
    a_alu_add: assert property (
        @(posedge clk)
        disable iff (reset_n !== 1'b1)
        (alu_active && (ALUCtrl == 4'b0000))
        |-> (result == (operand_a + operand_b))
    )
    else $error("SVA: ALU ADD operation failed");

    // SUB
    a_alu_sub: assert property (
        @(posedge clk)
        disable iff (reset_n !== 1'b1)
        (alu_active && (ALUCtrl == 4'b0001))
        |-> (result == (operand_a - operand_b))
    )
    else $error("SVA: ALU SUB operation failed");

    // AND
    a_alu_and: assert property (
        @(posedge clk)
        disable iff (reset_n !== 1'b1)
        (alu_active && (ALUCtrl == 4'b0010))
        |-> (result == (operand_a & operand_b))
    )
    else $error("SVA: ALU AND operation failed");

    // OR
    a_alu_or: assert property (
        @(posedge clk)
        disable iff (reset_n !== 1'b1)
        (alu_active && (ALUCtrl == 4'b0011))
        |-> (result == (operand_a | operand_b))
    )
    else $error("SVA: ALU OR operation failed");

    // XOR
    a_alu_xor: assert property (
        @(posedge clk)
        disable iff (reset_n !== 1'b1)
        (alu_active && (ALUCtrl == 4'b0100))
        |-> (result == (operand_a ^ operand_b))
    )
    else $error("SVA: ALU XOR operation failed");

    // NOT
    a_alu_not: assert property (
        @(posedge clk)
        disable iff (reset_n !== 1'b1)
        (alu_active && (ALUCtrl == 4'b0101))
        |-> (result == (~operand_a))
    )
    else $error("SVA: ALU NOT operation failed");

    // PASS A
    a_alu_pass_a: assert property (
        @(posedge clk)
        disable iff (reset_n !== 1'b1)
        (alu_active && (ALUCtrl == 4'b0110))
        |-> (result == operand_a)
    )
    else $error("SVA: ALU PASS_A operation failed");

    // PASS B
    a_alu_pass_b: assert property (
        @(posedge clk)
        disable iff (reset_n !== 1'b1)
        (alu_active && (ALUCtrl == 4'b0111))
        |-> (result == operand_b)
    )
    else $error("SVA: ALU PASS_B operation failed");

    // Invalid ALU controls must produce zero.
    a_alu_default: assert property (
        @(posedge clk)
        disable iff (reset_n !== 1'b1)
        (alu_active && ALUCtrl[3])
        |-> (result == 16'd0)
    )
    else $error("SVA: ALU default operation failed");

    // Zero flag must match the ALU result during execution.
    a_alu_zero: assert property (
        @(posedge clk)
        disable iff (reset_n !== 1'b1)
        alu_active
        |-> (zero == (result == 16'd0))
    )
    else $error("SVA: ALU zero flag assertion failed");

endmodule


// ============================================================
// 5. DATA MEMORY ASSERTIONS
// ============================================================

module data_memory_sva (
    input logic clk,
    input logic reset_n,

    input logic MemRead,
    input logic MemWrite,

    input logic [7:0] address,
    input logic [15:0] write_data,
    input logic [15:0] read_data,

    input logic [15:0] memory [0:255]
);

    // Memory write correctness.
    a_dm_mem_write: assert property (
        @(posedge clk)
        disable iff (reset_n !== 1'b1)
        (MemWrite && !MemRead)
        |=> (memory[$past(address)] == $past(write_data))
    )
    else $error("SVA: Data memory write operation failed");

    // Memory read correctness.
    a_dm_mem_read: assert property (
        @(posedge clk)
        disable iff (reset_n !== 1'b1)
        MemRead |-> (read_data == memory[address])
    )
    else $error("SVA: Data memory read operation failed");

    // Read data must be zero when read is disabled.
    a_dm_read_disable: assert property (
        @(posedge clk)
        disable iff (reset_n !== 1'b1)
        !MemRead |-> (read_data == 16'd0)
    )
    else $error("SVA: Data memory read disable failed");

    // Read and write must not be active simultaneously.
    a_dm_read_write_exclusivity: assert property (
        @(posedge clk)
        disable iff (reset_n !== 1'b1)
        !(MemRead && MemWrite)
    )
    else $error("SVA: Data memory read/write exclusivity failed");

endmodule


// ============================================================
// 6. INSTRUCTION MEMORY ASSERTIONS
// ============================================================


module instruction_memory_sva (
    input logic clk,
    input logic reset_n,

    input logic fetch_enable,

    input logic [7:0] address,
    input logic [15:0] instruction,

    input logic [15:0] mem [0:255]
);

    // Verify instruction data only when the CPU
    // explicitly enables instruction-register loading.
    a_imem_fetch: assert property (
        @(posedge clk)
        disable iff (reset_n !== 1'b1)
        fetch_enable
        |-> (instruction == mem[address])
    )
    else $error(
        "IMEM DEBUG: fetch_enable=%b address=%h instruction=%h mem[address]=%h",
        $sampled(fetch_enable),
        $sampled(address),
        $sampled(instruction),
        $sampled(mem[address])
    );
endmodule

// ============================================================
// 7. BIND STATEMENTS
// ============================================================

// Program counter
bind pc pc_sva pc_assertion_inst (
    .clk(clk),
    .reset_n(reset_n),
    .PCWrite(PCWrite),
    .next_pc(next_pc),
    .pc(pc)
);


// Control unit
bind control_unit control_unit_sva control_unit_assertion_inst (
    .clk(clk),
    .reset_n(reset_n),
    .state(state),

    .IRWrite(IRWrite),
    .PCWrite(PCWrite),
    .AWrite(AWrite),
    .BWrite(BWrite),
    .ALUOutWrite(ALUOutWrite),
    .MDRWrite(MDRWrite),
    .RegWrite(RegWrite),
    .MemRead(MemRead),
    .MemWrite(MemWrite),
    .MemToReg(MemToReg),
    .ALUSrc(ALUSrc),
    .Jump(Jump),
    .BranchTaken(BranchTaken),
    .Halted(Halted)
);


// Register file
bind register_file register_file_sva register_file_assertion_inst (
    .clk(clk),
    .reset_n(reset_n),

    .RegWrite(RegWrite),
    .write_addr(write_addr),
    .write_data(write_data),

    .read_addr1(read_addr1),
    .read_addr2(read_addr2),

    .read_data1(read_data1),
    .read_data2(read_data2),

    .registers(registers)
);


// ALU
bind alu alu_sva alu_assertion_inst (
    .clk($root.testbench.clk),
    .reset_n($root.testbench.dut.reset_n),

    .state($root.testbench.dut.control_unit_dut.state),

    .operand_a(operand_a),
    .operand_b(operand_b),
    .ALUCtrl(ALUCtrl),
    .result(result),
    .zero(zero)
);


// Data memory
bind data_memory data_memory_sva data_memory_assertion_inst (
    .clk(clk),
    .reset_n(reset_n),

    .MemRead(MemRead),
    .MemWrite(MemWrite),

    .address(address),
    .write_data(write_data),
    .read_data(read_data),

    .memory(memory)
);


// Instruction memory

bind instruction_memory instruction_memory_sva instruction_memory_assertion_inst (
    .clk($root.testbench.clk),
    .reset_n($root.testbench.dut.reset_n),

    .fetch_enable($root.testbench.dut.control_unit_dut.IRWrite),

    .address(address),
    .instruction(instruction),
    .mem(mem)
);


`endif
