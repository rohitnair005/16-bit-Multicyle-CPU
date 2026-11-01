`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.10.2026 13:15:39
// Design Name: 
// Module Name: next_pc_logic
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


module next_pc_logic(
    input [7:0] pc, jump_address,
    input [15:0] branch_offset,
    input BranchTaken, jump,
    output reg [7:0] next_pc
    );
    
    always @(*) begin
        if (jump)
            next_pc = jump_address;
        else if (BranchTaken)
            next_pc = pc + branch_offset[7:0];
        else
            next_pc = pc + 8'd1;
    end
endmodule
