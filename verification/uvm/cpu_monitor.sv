`ifndef CPU_MONITOR_SV
`define CPU_MONITOR_SV

`include "uvm_macros.svh"

class cpu_monitor extends uvm_monitor;
    `uvm_component_utils(cpu_monitor)

    virtual cpu_if vif;
    cpu_monitor_transaction cpu_mtr_tx;
    uvm_analysis_port #(cpu_monitor_transaction) ap;

    logic halt_previous;
  	bit stop_monitoring;

    function new(string name = "cpu_monitor",
                 uvm_component parent = null);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db #(virtual cpu_if)::get(
                this, "", "vif", vif))
            `uvm_fatal("MON_NO_VIF",
                       "Could not retrieve virtual interface")
    endfunction

    task run_phase(uvm_phase phase);
        halt_previous = 0;
		stop_monitoring = 0;

        forever begin
            @(negedge vif.clk);

            if (!vif.reset_n) begin
                halt_previous = 0;
              	stop_monitoring = 0;
                continue;
            end

            // Report each instruction fetch.
            if (vif.instruction_valid && !stop_monitoring) begin
                cpu_mtr_tx =
                    cpu_monitor_transaction::type_id::create(
                        "cpu_mtr_tx");

                cpu_mtr_tx.event_kind =
                    cpu_monitor_transaction::INSTR_EVENT;
                cpu_mtr_tx.pc = vif.pc;
                cpu_mtr_tx.instruction = vif.instruction;

                ap.write(cpu_mtr_tx);
            end
          
            // Report branch execution outcome.
            if (vif.branch_valid && !stop_monitoring) begin
                cpu_mtr_tx =
                    cpu_monitor_transaction::type_id::create("cpu_mtr_tx");

                cpu_mtr_tx.event_kind =
                    cpu_monitor_transaction::BRANCH_EVENT;

                cpu_mtr_tx.branch_opcode = vif.branch_opcode;
                cpu_mtr_tx.branch_taken  = vif.branch_taken;

                cpu_mtr_tx.pc = vif.pc;
                cpu_mtr_tx.instruction = vif.instruction;

                ap.write(cpu_mtr_tx);
            end

            // Report architectural register writes.
            if (vif.reg_write && vif.write_addr != 3'd0 && !stop_monitoring) begin
                cpu_mtr_tx =
                    cpu_monitor_transaction::type_id::create(
                        "cpu_mtr_tx");

                cpu_mtr_tx.event_kind = cpu_monitor_transaction::REG_WRITE;
                cpu_mtr_tx.write_addr = vif.write_addr;
                cpu_mtr_tx.writeback_data = vif.writeback_data;
                cpu_mtr_tx.pc = vif.pc;
                cpu_mtr_tx.instruction = vif.instruction;

                ap.write(cpu_mtr_tx);
            end

            // Report data-memory writes.
            if (vif.mem_write && !stop_monitoring) begin
                cpu_mtr_tx =
                    cpu_monitor_transaction::type_id::create(
                        "cpu_mtr_tx");

                cpu_mtr_tx.event_kind = cpu_monitor_transaction::MEM_WRITE;
                cpu_mtr_tx.data_address = vif.data_address;
                cpu_mtr_tx.store_data = vif.store_data;
                cpu_mtr_tx.pc = vif.pc;
                cpu_mtr_tx.instruction = vif.instruction;

                ap.write(cpu_mtr_tx);
            end
          
            // Report data-memory reads.
          	if (vif.mem_read && !stop_monitoring) begin
                cpu_mtr_tx =
                    cpu_monitor_transaction::type_id::create(
                        "cpu_mtr_tx");

                cpu_mtr_tx.event_kind = cpu_monitor_transaction::MEM_READ;
                cpu_mtr_tx.data_address = vif.data_address;
                cpu_mtr_tx.store_data = vif.store_data;
                cpu_mtr_tx.pc = vif.pc;
                cpu_mtr_tx.instruction = vif.instruction;

                ap.write(cpu_mtr_tx);
            end
          if (!stop_monitoring && (vif.alu_out_write || vif.branch_valid))begin
                cpu_mtr_tx =
                    cpu_monitor_transaction::type_id::create(
                        "cpu_mtr_tx");

                cpu_mtr_tx.event_kind = cpu_monitor_transaction::ALU_EVENT;
                cpu_mtr_tx.alu_ctrl = vif.alu_ctrl;
                cpu_mtr_tx.pc = vif.pc;
                cpu_mtr_tx.instruction = vif.instruction;

                ap.write(cpu_mtr_tx);
            end

            // Report the transition into the halted state.
            if (vif.halted && !halt_previous) begin
                cpu_mtr_tx =
                    cpu_monitor_transaction::type_id::create(
                        "cpu_mtr_tx");

                cpu_mtr_tx.event_kind = cpu_monitor_transaction::HALT_EVENT;
              	stop_monitoring = 1;
                cpu_mtr_tx.pc = vif.pc;
                cpu_mtr_tx.instruction = vif.instruction;

                ap.write(cpu_mtr_tx);
            end

            halt_previous = vif.halted;
        end
    endtask

endclass

`endif