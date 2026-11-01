`ifndef CPU_TRANSACTION_MONITOR_SV
`define CPU_TRANSACTION_MONITOR_SV

`include "uvm_macros.svh"

class cpu_monitor_transaction extends uvm_sequence_item;
    `uvm_object_utils(cpu_monitor_transaction)

    typedef enum {
        INSTR_EVENT,
      	BRANCH_EVENT,
        REG_WRITE,
        MEM_WRITE,
      	MEM_READ,
      	ALU_EVENT,
        HALT_EVENT
    } event_type_t;

    event_type_t event_kind;

    logic reg_write;
    logic [2:0] write_addr;
    logic [15:0] writeback_data;

    logic mem_write;
    logic [7:0] data_address;
    logic [15:0] store_data;

    logic [7:0] pc;
    logic [15:0] instruction;
  	logic branch_taken;
  	logic [4:0] branch_opcode;
  
  	logic [3:0] alu_ctrl;

    function new(string name = "cpu_monitor_transaction");
        super.new(name);
    endfunction

endclass

`endif