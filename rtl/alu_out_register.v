`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.10.2026 12:57:46
// Design Name: 
// Module Name: alu_out_register
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


module alu_out_register(
    input clk, reset_n, ALUOutWrite,
    input [15:0] data_in,
    output reg [15:0] ALUOut
    );
    
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n)
            ALUOut <= 16'd0;
        else if (ALUOutWrite)
            ALUOut <= data_in;
    end
endmodule
