`ifndef CPU_DRIVER_SV
	`define CPU_DRIVER_SV

    class cpu_driver extends uvm_driver #(cpu_transaction);
      `uvm_component_utils(cpu_driver)
      
      virtual cpu_if vif;
      cpu_transaction tx;
      
      function new(string name = "cpu_driver", uvm_component parent);
        super.new(name, parent);
      endfunction
      
      function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        if (!uvm_config_db #(virtual cpu_if)::get (this, "", "vif", vif))
          `uvm_fatal("GET FAIL", "Retrieving interface failed");
      endfunction
      
      task run_phase(uvm_phase phase);
        forever begin
          seq_item_port.get_next_item(tx);
          `uvm_info("DRV", $sformatf("Received transaction: reset_n=%0b, resume=%0b",
                           tx.reset_n, tx.resume), UVM_MEDIUM)
          
          @(negedge vif.clk);
          vif.reset_n = tx.reset_n;
          vif.resume = tx.resume;
          
          seq_item_port.item_done();
          `uvm_info("DRV", "Transaction completed", UVM_MEDIUM)
        end
      endtask
      
    endclass
`endif