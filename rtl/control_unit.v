`timescale 1ns / 1ps

module control_unit(
    input wire clk,
    input wire reset_n,
    input wire zero,
    input wire resume,
    input wire [4:0] opcode,

    output reg IRWrite,
    output reg PCWrite,
    output reg AWrite,
    output reg BWrite,
    output reg ALUOutWrite,
    output reg MDRWrite,
    output reg RegWrite,
    output reg MemRead,
    output reg MemWrite,
    output reg MemToReg,
    output reg ALUSrc,
    output reg Jump,
    output reg BranchTaken,
    output reg [3:0] ALUCtrl,
    output reg Halted
);

    // FSM states
    localparam
        S_FETCH     = 4'd0,
        S_DECODE    = 4'd1,
        S_EXEC_R    = 4'd2,
        S_WB_R      = 4'd3,
        S_EXEC_I    = 4'd4,
        S_WB_I      = 4'd5,
        S_MEM_ADDR  = 4'd6,
        S_MEM_READ  = 4'd7,
        S_WB_LD     = 4'd8,
        S_MEM_WRITE = 4'd9,
        S_BRANCH    = 4'd10,
        S_JUMP      = 4'd11,
        S_HALT      = 4'd12;

    // Opcodes
    localparam [4:0]
        OP_ADD  = 5'b00000,
        OP_SUB  = 5'b00001,
        OP_ADDI = 5'b00010,
        OP_SUBI = 5'b00011,
        OP_AND  = 5'b00100,
        OP_OR   = 5'b00101,
        OP_XOR  = 5'b00110,
        OP_NOT  = 5'b00111,
        OP_MOV  = 5'b01000,
        OP_LI   = 5'b01001,
        OP_LD   = 5'b01010,
        OP_ST   = 5'b01011,
        OP_BEQ  = 5'b01100,
        OP_BNE  = 5'b01101,
        OP_JMP  = 5'b01110,
        OP_NOP  = 5'b01111,
        OP_HALT = 5'b10000;

    // ALU control codes
    localparam [3:0]
        ALU_ADD    = 4'b0000,
        ALU_SUB    = 4'b0001,
        ALU_AND    = 4'b0010,
        ALU_OR     = 4'b0011,
        ALU_XOR    = 4'b0100,
        ALU_NOT    = 4'b0101,
        ALU_PASS_A = 4'b0110,
        ALU_PASS_B = 4'b0111;

    reg [3:0] state, next_state;

    // 1. Sequential state register
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n)
            state <= S_FETCH;
        else
            state <= next_state;
    end

    // 2. Combinational next-state logic
    always @(*) begin
        next_state = state;

        case (state)

            S_FETCH:
                next_state = S_DECODE;

            S_DECODE: begin
                case (opcode)
                    OP_ADD, OP_SUB, OP_AND, OP_OR,
                    OP_XOR, OP_NOT, OP_MOV:
                        next_state = S_EXEC_R;

                    OP_ADDI, OP_SUBI, OP_LI:
                        next_state = S_EXEC_I;

                    OP_LD, OP_ST:
                        next_state = S_MEM_ADDR;

                    OP_BEQ, OP_BNE:
                        next_state = S_BRANCH;

                    OP_JMP:
                        next_state = S_JUMP;

                    OP_NOP:
                        next_state = S_FETCH;

                    OP_HALT:
                        next_state = S_HALT;

                    default:
                        next_state = S_FETCH;
                endcase
            end

            S_EXEC_R:
                next_state = S_WB_R;

            S_WB_R:
                next_state = S_FETCH;

            S_EXEC_I:
                next_state = S_WB_I;

            S_WB_I:
                next_state = S_FETCH;

            S_MEM_ADDR: begin
                if (opcode == OP_LD)
                    next_state = S_MEM_READ;
                else if (opcode == OP_ST)
                    next_state = S_MEM_WRITE;
                else
                    next_state = S_FETCH;
            end

            S_MEM_READ:
                next_state = S_WB_LD;

            S_WB_LD:
                next_state = S_FETCH;

            S_MEM_WRITE:
                next_state = S_FETCH;

            S_BRANCH, S_JUMP:
                next_state = S_FETCH;

            S_HALT: begin
                if (resume)
                    next_state = S_FETCH;
                else
                    next_state = S_HALT;
            end

            default:
                next_state = S_FETCH;

        endcase
    end

    // 3. Combinational output logic
    always @(*) begin

        // Safe defaults: prevents unintended latches
        IRWrite     = 1'b0;
        PCWrite     = 1'b0;
        AWrite      = 1'b0;
        BWrite      = 1'b0;
        ALUOutWrite = 1'b0;
        MDRWrite    = 1'b0;
        RegWrite    = 1'b0;
        MemRead     = 1'b0;
        MemWrite    = 1'b0;
        MemToReg    = 1'b0;
        ALUSrc      = 1'b0;
        Jump        = 1'b0;
        BranchTaken = 1'b0;
        Halted = 1'b0;
        ALUCtrl     = ALU_ADD;

        case (state)

            S_FETCH: begin
                IRWrite = 1'b1;
                PCWrite = 1'b1;
            end

            S_DECODE: begin
                AWrite = 1'b1;
                BWrite = 1'b1;
            end

            S_EXEC_R: begin
                ALUOutWrite = 1'b1;

                case (opcode)
                    OP_ADD: ALUCtrl = ALU_ADD;
                    OP_SUB: ALUCtrl = ALU_SUB;
                    OP_AND: ALUCtrl = ALU_AND;
                    OP_OR : ALUCtrl = ALU_OR;
                    OP_XOR: ALUCtrl = ALU_XOR;
                    OP_NOT: ALUCtrl = ALU_NOT;
                    OP_MOV: ALUCtrl = ALU_PASS_A;
                    default: ALUCtrl = ALU_ADD;
                endcase
            end

            S_WB_R: begin
                RegWrite = 1'b1;
            end

            S_EXEC_I: begin
                ALUOutWrite = 1'b1;
                ALUSrc = 1'b1;

                case (opcode)
                    OP_ADDI: ALUCtrl = ALU_ADD;
                    OP_SUBI: ALUCtrl = ALU_SUB;
                    OP_LI:   ALUCtrl = ALU_PASS_B;
                    default: ALUCtrl = ALU_ADD;
                endcase
            end

            S_WB_I: begin
                RegWrite = 1'b1;
            end

            S_MEM_ADDR: begin
                ALUOutWrite = 1'b1;
                ALUSrc = 1'b1;
                ALUCtrl = ALU_ADD;
            end

            S_MEM_READ: begin
                MemRead = 1'b1;
                MDRWrite = 1'b1;
            end

            S_WB_LD: begin
                RegWrite = 1'b1;
                MemToReg = 1'b1;
            end

            S_MEM_WRITE: begin
                MemWrite = 1'b1;
            end

            S_BRANCH: begin
                ALUCtrl = ALU_SUB;

                if (opcode == OP_BEQ)
                    BranchTaken = zero;
                else if (opcode == OP_BNE)
                    BranchTaken = ~zero;

                // PCWrite only when branch is taken.
                if (BranchTaken)
                    PCWrite = 1'b1;
            end

            S_JUMP: begin
                PCWrite = 1'b1;
                Jump = 1'b1;
            end

            S_HALT: begin
                Halted = 1'b1;
            end

            default: begin
                // All controls remain at their safe defaults.
            end

        endcase
    end

endmodule