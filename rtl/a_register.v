`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.10.2026 12:17:22
// Design Name: 
// Module Name: a_register
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


module a_register(
    input clk, reset_n, AWrite,
    input [15:0] data_in,
    output reg [15:0] A
    );
    
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n)
            A <= 16'd0;
        else if (AWrite)
            A <= data_in;
    end
endmodule
