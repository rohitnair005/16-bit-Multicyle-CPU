`ifndef CPU_TEST_SV
	`define CPU_TEST_SV

`include "uvm_macros.svh"

class cpu_test extends uvm_test;
  `uvm_component_utils(cpu_test)
  
  cpu_env cpu_e;

  function new(string name = "cpu_test", uvm_component parent = null);
    super.new(name,parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    cpu_e = cpu_env::type_id::create("cpu_env", this);
  endfunction
  
  task run_phase(uvm_phase phase);
    cpu_sequence seq;
    phase.raise_objection(this);
    
      seq = cpu_sequence::type_id::create("cpu_sequence", this);
    seq.start(cpu_e.cpu_agt.cpu_sqncr);
    
    #1000ns
    
    phase.drop_objection(this);
  endtask
  
endclass

`endif