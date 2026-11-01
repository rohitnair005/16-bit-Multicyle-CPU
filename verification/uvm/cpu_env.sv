`ifndef CPU_ENV_SV
	`define CPU_ENV_SV
	
	`include "uvm_macros.svh"

    class cpu_env extends uvm_env;
      `uvm_component_utils(cpu_env)
      
      cpu_agent cpu_agt;
      cpu_scoreboard cpu_scbd;
      cpu_coverage cpu_cvg;
      
      function new(string name = "cpu_env", uvm_component parent = null);
        super.new(name, parent);
      endfunction
      
      function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        cpu_agt = cpu_agent::type_id::create("cpu_agent", this);
        cpu_scbd = cpu_scoreboard::type_id::create("cpu_scoreboard", this);
        cpu_cvg = cpu_coverage::type_id::create("cpu_coverage", this);
      endfunction
      
      function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        cpu_agt.cpu_mtr.ap.connect(cpu_scbd.ai);
        cpu_agt.cpu_mtr.ap.connect(cpu_cvg.analysis_export);
      endfunction

    endclass
`endif