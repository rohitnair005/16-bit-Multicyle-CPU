`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.10.2026 11:52:29
// Design Name: 
// Module Name: instruction_decoder
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module instruction_decoder(
    input [15:0] instruction,
    output [4:0] opcode, offset, imm,
    output [2:0] rd, rs1, rs2,
    output [1:0] res,
    output [7:0] jump_address
    );
    
    assign opcode = instruction[15:11];
    assign rd = instruction[10:8];
    assign rs1 = instruction[7:5];
    assign rs2 = instruction[4:2];
    assign imm = instruction[4:0];
    assign offset = instruction[4:0];
    assign jump_address = instruction[10:3];
    assign res = instruction[1:0];
    
endmodule
