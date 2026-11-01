`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.10.2026 12:04:27
// Design Name: 
// Module Name: register_file
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


module register_file(
    input clk, reset_n, RegWrite,
    input [2:0] read_addr1, read_addr2, write_addr,
    input [15:0] write_data,
    output [15:0] read_data1, read_data2
    );
    
    reg [15:0] registers [0:7];
    integer i;
    
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n)
            for (i=0; i<8; i=i+1)
                registers[i] <= 16'd0;
        else if (RegWrite && (write_addr != 3'd0))
            registers[write_addr] <= write_data;
    end
    
    assign read_data1 = (read_addr1==3'd0) ? 16'd0 : registers[read_addr1];
    assign read_data2 = (read_addr2==3'd0) ? 16'd0 : registers[read_addr2];
    
endmodule
