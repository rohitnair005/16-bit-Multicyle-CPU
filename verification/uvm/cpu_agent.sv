`ifndef CPU_AGENT_SV
	`define CPU_AGENT_SV
	
	`include "uvm_macros.svh"

    class cpu_agent extends uvm_agent;
      `uvm_component_utils(cpu_agent)
      
      cpu_driver cpu_drvr;
      cpu_sequencer cpu_sqncr;
      cpu_monitor cpu_mtr;
      
      function new(string name = "cpu_agent", uvm_component parent = null);
        super.new(name, parent);
      endfunction
      
      function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        cpu_drvr = cpu_driver::type_id::create("cpu_driver",this);
        cpu_sqncr = cpu_sequencer::type_id::create("cpu_sequencer", this);
        cpu_mtr = cpu_monitor::type_id::create("cpu_monitor", this);
      endfunction
      
      function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        cpu_drvr.seq_item_port.connect(cpu_sqncr.seq_item_export);
      endfunction

    endclass
`endif