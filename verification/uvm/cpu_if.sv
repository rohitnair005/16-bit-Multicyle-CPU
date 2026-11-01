`timescale 1ns / 1ps

interface cpu_if(input logic clk);
    logic reset_n;
    logic resume; 
    logic halted;
  
    logic reg_write;
    logic [2:0] write_addr;
    logic [15:0] writeback_data;

    logic mem_write;
  	logic mem_read;
    logic [7:0] data_address;
    logic [15:0] store_data;
  
    logic [7:0] pc;
  	logic [15:0] instruction;
  	logic instruction_valid;
  
    logic branch_taken;
  	logic [4:0] branch_opcode;
  	logic branch_valid;
  
  	logic [3:0] alu_ctrl;
  	logic alu_out_write;
  
endinterface
