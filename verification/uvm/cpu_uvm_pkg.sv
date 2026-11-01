`ifndef CPU_UVM_PKG_SV
	`define CPU_UVM_PKG_SV

`include "uvm_macros.svh"

package cpu_uvm_pkg;
	import uvm_pkg::*;

	`include "cpu_transaction.sv"
    `include "cpu_random_sequence.sv"
	`include "cpu_sequence.sv"
    `include "cpu_sequencer.sv"
    `include "cpu_driver.sv"
	`include "cpu_monitor_transaction.sv"
	`include "cpu_monitor.sv"
    `include "cpu_agent.sv"
    `include "cpu_scoreboard.sv"
	`include "cpu_coverage.sv"
    `include "cpu_env.sv"
	`include "cpu_test.sv"
	`include "cpu_random_test.sv"

endpackage

`endif