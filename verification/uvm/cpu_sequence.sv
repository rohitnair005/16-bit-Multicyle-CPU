`ifndef CPU_SEQUENCE_SV
	`define CPU_SEQUENCE_SV

	`include "uvm_macros.svh"

    class cpu_sequence extends uvm_sequence#(cpu_transaction);
      
      `uvm_object_utils(cpu_sequence)
    
      function new(string name = "cpu_sequence");
          super.new(name);
      endfunction
      
      cpu_transaction tx;
      
      task body();
        
        // 1. Assert reset
        tx = cpu_transaction::type_id::create("tx");
        start_item(tx);
        tx.reset_n = 0;
        tx.resume  = 0;
        finish_item(tx);

        // 2. Maintain reset
        tx = cpu_transaction::type_id::create("tx");
        start_item(tx);
        tx.reset_n = 0;
        tx.resume  = 0;
        finish_item(tx);

        // 3. Release reset, keep CPU paused
        tx = cpu_transaction::type_id::create("tx");
        start_item(tx);
        tx.reset_n = 1;
        tx.resume  = 0;
        finish_item(tx);

        // 4. Allow CPU execution
        tx = cpu_transaction::type_id::create("tx");
        start_item(tx);
        tx.reset_n = 1;
        tx.resume  = 1;
        finish_item(tx);

        // 5. Continue execution
        tx = cpu_transaction::type_id::create("tx");
        start_item(tx);
        tx.reset_n = 1;
        tx.resume  = 0;
        finish_item(tx);
        
      endtask
      
    endclass
	
`endif