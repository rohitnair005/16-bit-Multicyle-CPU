`ifndef CPU_SEQUENCER_SV
	`define CPU_SEQUENCER_SV
	
	`include "uvm_macros.svh"
	
    class cpu_sequencer extends uvm_sequencer#(cpu_transaction);
      `uvm_component_utils(cpu_sequencer)
    
      function new(string name="cpu_sequencer", uvm_component parent = null);
        super.new(name, parent);
      endfunction
      
    endclass

`endif