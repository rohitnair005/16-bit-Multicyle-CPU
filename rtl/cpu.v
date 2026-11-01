`timescale 1ns / 1ps

module cpu(
    input clk, reset_n, resume,
    output Halted
    );
        
    wire [7:0] pc;
    wire [7:0] next_pc;
    wire [7:0] instruction_address;
    wire [15:0] instruction;
    
    wire [15:0] instruction_out;
    wire [4:0] opcode;
    wire [2:0] rd, rs1, rs2;
    wire [4:0] imm, offset;
    wire [1:0] res;
    wire [7:0] jump_address;
    
    wire [15:0] imm_extended;
    wire [15:0] branch_offset_extended;
    
    reg [2:0] read_addr1, read_addr2;
    wire [2:0] write_addr;
    wire [15:0] read_data1, read_data2;
    wire [15:0] writeback_data;
    wire [15:0] A, B;
    wire [15:0] store_data;
    
    wire [15:0] operand_b;
    wire [15:0] result;
    wire [15:0] ALUOut;
    wire zero;
    
    wire [7:0] data_address;
    wire [15:0] memory_read_data;
    wire [15:0] MDR;
    
    wire IRWrite, PCWrite;
    wire AWrite, BWrite;
    wire ALUOutWrite, MDRWrite;
    wire RegWrite, MemRead, MemWrite;
    wire MemToReg, ALUSrc;
    wire Jump, BranchTaken;
    wire [3:0] ALUCtrl;
    
    localparam [4:0]
        OP_ST  = 5'b01011,
        OP_BEQ = 5'b01100,
        OP_BNE = 5'b01101;
    
    assign instruction_address = pc;
    assign operand_b = ALUSrc ? imm_extended : B;
    assign data_address = ALUOut[7:0];
    assign branch_offset_extended = {{11{offset[4]}}, offset};
    assign store_data = B;
    assign write_addr = rd;
    
    always @(*) begin
        read_addr1 = rs1;
        read_addr2 = rs2;
    
        if ((opcode == OP_BEQ) || (opcode == OP_BNE)) begin
            read_addr1 = rd;
            read_addr2 = rs1;
        end
        else if (opcode == OP_ST) begin
            read_addr1 = rs1;
            read_addr2 = rd;
        end
    end
    
    pc pc_dut(
        .clk(clk),
        .reset_n(reset_n),
        .PCWrite(PCWrite),
        .next_pc(next_pc),
        .pc(pc)
    );
    
    instruction_memory instruction_memory_dut(
        .address(instruction_address),
        .instruction(instruction)
    );
    
    instruction_register instruction_register_dut(
        .clk(clk),
        .reset_n(reset_n),
        .IRWrite(IRWrite),
        .instruction_in(instruction),
        .instruction_out(instruction_out)
    );
    
    instruction_decoder instruction_decoder_dut(
        .instruction(instruction_out),
        .opcode(opcode),
        .rd(rd),
        .rs1(rs1),
        .rs2(rs2),
        .imm(imm),
        .offset(offset),
        .res(res),
        .jump_address(jump_address)
    );
    
    immediate_generator immediate_generator_dut(
        .imm(imm),
        .imm_extended(imm_extended)
    );
    
    register_file register_file_dut(
        .clk(clk),
        .reset_n(reset_n),
        .RegWrite(RegWrite),
        .read_addr1(read_addr1),
        .read_addr2(read_addr2),
        .write_addr(write_addr),
        .write_data(writeback_data),
        .read_data1(read_data1),
        .read_data2(read_data2)
    );
    
    a_register a_register_dut(
        .clk(clk),
        .reset_n(reset_n),
        .AWrite(AWrite),
        .data_in(read_data1),
        .A(A)
    );
    
    b_register b_register_dut(
        .clk(clk),
        .reset_n(reset_n),
        .BWrite(BWrite),
        .data_in(read_data2),
        .B(B)
    );
    
    alu alu_dut(
        .operand_a(A),
        .operand_b(operand_b),
        .ALUCtrl(ALUCtrl),
        .zero(zero),
        .result(result)
    );
    
    alu_out_register alu_out_register_dut(
        .clk(clk),
        .reset_n(reset_n),
        .ALUOutWrite(ALUOutWrite),
        .data_in(result),
        .ALUOut(ALUOut)
    );
    
    data_memory data_memory_dut(
        .clk(clk),
        .reset_n(reset_n),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .address(data_address),
        .write_data(store_data),
        .read_data(memory_read_data)
    );
    
    mdr mdr_dut(
        .clk(clk),
        .reset_n(reset_n),
        .MDRWrite(MDRWrite),
        .data_in(memory_read_data),
        .MDR(MDR)
    );
    
    writeback_mux writeback_mux_dut(
        .ALUOut(ALUOut),
        .MDR(MDR),
        .MemToReg(MemToReg),
        .writeback_data(writeback_data)
    );
    
    next_pc_logic next_pc_logic_dut(
        .pc(pc),
        .jump_address(jump_address),
        .branch_offset(branch_offset_extended),
        .BranchTaken(BranchTaken),
        .jump(Jump),
        .next_pc(next_pc)
    );
    
    control_unit control_unit_dut(
        .clk(clk),
        .reset_n(reset_n),
        .resume(resume),
        .zero(zero),
        .opcode(opcode),
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
        .ALUCtrl(ALUCtrl),
        .Halted(Halted)
    );
endmodule
