`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.10.2026 13:01:34
// Design Name: 
// Module Name: data_memory
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


module data_memory(
    input clk, reset_n, MemRead, MemWrite,
    input [7:0] address,
    input [15:0] write_data,
    output [15:0] read_data
    );
    
    reg [15:0] memory [0:255];
    
    always @(posedge clk) begin
        if (reset_n && MemWrite && !MemRead)
            memory[address] <= write_data;
    end
    
    assign read_data = (reset_n && MemRead) ? memory[address] : 16'd0;
            
endmodule
