`include "uvm_macros.svh"
`include "cpu_if.sv"
`include "cpu_uvm_pkg.sv"

module testbench;
    import uvm_pkg::*;
    import cpu_uvm_pkg::*;

    logic clk;
    logic [7:0] instruction_pc;

    initial clk = 1'b0;
    always #5ns clk = ~clk;

    cpu_if dut_if(clk);

    cpu dut (
        .clk     (dut_if.clk),
        .reset_n (dut_if.reset_n),
        .resume  (dut_if.resume),
        .Halted  (dut_if.halted)
    );

    // Preserve the instruction address when the instruction is fetched.
    always @(posedge clk or negedge dut_if.reset_n) begin
        if (!dut_if.reset_n)
            instruction_pc <= 8'd0;
        else if (dut.IRWrite)
            instruction_pc <= dut.pc;
    end

    assign dut_if.reg_write      = dut.RegWrite;
    assign dut_if.write_addr     = dut.write_addr;
    assign dut_if.writeback_data = dut.writeback_data;

    assign dut_if.mem_write      = dut.MemWrite;
  	assign dut_if.mem_read 		 = dut.MemRead;
    assign dut_if.data_address   = dut.data_address;
    assign dut_if.store_data     = dut.store_data;

    assign dut_if.pc                 = instruction_pc;
    assign dut_if.instruction        = dut.instruction_out;
    assign dut_if.instruction_valid  = dut.IRWrite;
  
    assign dut_if.branch_taken = dut.BranchTaken;
  	assign dut_if.branch_opcode = dut.opcode;
  	assign dut_if.branch_valid = (dut.control_unit_dut.state == 4'd10);
  
  	assign dut_if.alu_ctrl = dut.ALUCtrl;
  	assign dut_if.alu_out_write = dut.ALUOutWrite;

    initial begin
        uvm_config_db #(virtual cpu_if)::set(
            null, "*", "vif", dut_if
        );
        run_test();
    end

endmodule

`include "cpu_assertions.sv"