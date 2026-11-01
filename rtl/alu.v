`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.10.2026 12:40:25
// Design Name: 
// Module Name: alu
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


module alu(
    input [15:0] operand_a, operand_b,
    input [3:0] ALUCtrl,
    output reg [15:0] result,
    output zero
    );
    
    always @(*) begin
        case(ALUCtrl)
            4'b0000 : result = operand_a + operand_b;    //ADD
            4'b0001 : result = operand_a - operand_b;    //SUB
            4'b0010 : result = operand_a & operand_b;    //AND
            4'b0011 : result = operand_a | operand_b;    //OR
            4'b0100 : result = operand_a ^ operand_b;    //XOR
            4'b0101 : result = ~operand_a ;  //NOT
            4'b0110 : result = operand_a;    //PASS_A
            4'b0111 : result = operand_b;    //PASS_B
            default : result = 16'd0; 
        endcase
    end
    
    assign zero = (result == 16'd0);
    
endmodule
