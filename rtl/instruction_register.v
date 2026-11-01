`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.10.2026 11:36:58
// Design Name: 
// Module Name: instruction_register
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


module instruction_register(
    input clk, reset_n, IRWrite,
    input [15:0] instruction_in,
    output reg [15:0] instruction_out
    );
    
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n)
            instruction_out <= 16'd0;
        else if (IRWrite)
            instruction_out <= instruction_in;
    end
endmodule
