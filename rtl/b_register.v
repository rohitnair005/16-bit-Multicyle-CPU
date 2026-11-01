`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.10.2026 12:23:03
// Design Name: 
// Module Name: b_register
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


module b_register(
    input clk, reset_n, BWrite,
    input [15:0] data_in,
    output reg [15:0] B
    );
    
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n)
            B <= 16'd0;
        else if (BWrite)
            B <= data_in;
    end
endmodule
