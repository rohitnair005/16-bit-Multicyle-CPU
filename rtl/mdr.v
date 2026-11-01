`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.10.2026 13:09:30
// Design Name: 
// Module Name: mdr
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


module mdr(
    input clk, reset_n, MDRWrite,
    input [15:0] data_in,
    output reg [15:0] MDR
    );
    
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n)
            MDR <= 16'd0;
        else if (MDRWrite)
            MDR <= data_in;
    end
    
endmodule
