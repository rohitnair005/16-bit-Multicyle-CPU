`ifndef CPU_TRANSACTION_SV
	`define CPU_TRANSACTION_SV

	`include "uvm_macros.svh"

  class cpu_transaction extends uvm_sequence_item;
    `uvm_object_utils(cpu_transaction)
    
    rand bit reset_n;
    rand bit resume;
    constraint reset_resume{
      reset_n == 0 -> resume == 0;
    }
    
    function new(string name = "cpu_transaction");
    	super.new(name);
  	endfunction
    
  endclass
	

`endif