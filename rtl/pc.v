`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.10.2026 11:22:57
// Design Name: 
// Module Name: pc
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


module pc(
    input clk, reset_n, PCWrite,
    input [7:0] next_pc,
    output reg [7:0] pc
    );
    
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n)
            pc <= 8'd0;
        else if (PCWrite)
            pc <= next_pc;
    end
endmodule
