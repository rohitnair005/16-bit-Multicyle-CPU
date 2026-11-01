`ifndef CPU_COVERAGE_SV
    `define CPU_COVERAGE_SV

    `include "uvm_macros.svh"

    class cpu_coverage extends uvm_subscriber #(cpu_monitor_transaction);
        `uvm_component_utils(cpu_coverage)

        logic [4:0] opcode;
          logic [4:0] branch_opcode;
        logic branch_taken;
          logic [2:0] rd;
        logic [2:0] rs1;
        logic [2:0] rs2;
        logic [2:0] branch_rs2;
          logic [7:0] mem_address;
          logic [3:0] alu_ctrl;
          logic [4:0] immediate;
          logic [15:0] writeback_data;
          logic mem_operation;

          int opcode_count [0:16];
          int branch_cross_count[0:3];
        int rd_count [0:7];
        int rs1_count [0:7];
        int rs2_count [0:7];
        int branch_rs2_count [0:7];
          int mem_write_count;
          int mem_read_count;
          int mem_addr_count_w [0:255];
          int mem_addr_count_r [0:255];
          int alu_ctrl_count [0:7];
          int imm_cross_count [0:223];
        int rs1_rs2_count[0:63];
        int opcode_rd_count[0:76];
        int mem_op_addr_count[0:511];
        int writeback_bin_count[0:4];
        int opcode_total, branch_total, rd_total, rs1_total, rs2_total;
        int branch_rs2_total, alu_invalid_count;
        int imm_slot;
        int alu_total, immediate_total, writeback_total;
        int rs1_rs2_total, opcode_rd_total, mem_op_addr_total;
        int opcode_covered, rd_covered, rs1_covered, rs2_covered;
        int alu_covered, immediate_covered, writeback_covered;
        int rs1_rs2_covered, opcode_rd_covered, mem_op_addr_covered;
        int mem_write_covered, mem_read_covered;

        covergroup opcode_cg;
          opcode_cp: coverpoint opcode{
            bins ADD = {5'b00000};
            bins SUB = {5'b00001};
            bins ADDI = {5'b00010};
            bins SUBI = {5'b00011};
            bins AND  = {5'b00100};
            bins OR   = {5'b00101};
            bins XOR  = {5'b00110};
            bins NOT  = {5'b00111};
            bins MOV  = {5'b01000};
            bins LI   = {5'b01001};
            bins LD   = {5'b01010};
            bins ST   = {5'b01011};
            bins BEQ  = {5'b01100};
            bins BNE  = {5'b01101};
            bins JMP  = {5'b01110};
            bins NOP  = {5'b01111};
            bins HALT = {5'b10000};
          }
        endgroup

      covergroup branch_cg;
        branch_opcode_cp: coverpoint branch_opcode{
          bins BEQ = {5'b01100};
          bins BNE = {5'b01101};
        }

        branch_taken_cp : coverpoint branch_taken{
          bins not_taken = {1'b0};
          bins taken = {1'b1};
        }

        branch_cross: cross branch_opcode_cp, branch_taken_cp;
      endgroup

      covergroup rd_cg;
        rd_cp : coverpoint rd{
          bins R1 = {3'b001};
          bins R2 = {3'b010};
          bins R3 = {3'b011};
          bins R4 = {3'b100};
          bins R5 = {3'b101};
          bins R6 = {3'b110};
          bins R7 = {3'b111};
        }
      endgroup

      covergroup rs1_cg;
          rs1_cp: coverpoint rs1 {
              bins R0 = {3'b000};
              bins R1 = {3'b001};
              bins R2 = {3'b010};
              bins R3 = {3'b011};
              bins R4 = {3'b100};
              bins R5 = {3'b101};
              bins R6 = {3'b110};
              bins R7 = {3'b111};
          }
      endgroup

      covergroup rs2_cg;
          rs2_cp: coverpoint rs2 {
              bins R0 = {3'b000};
              bins R1 = {3'b001};
              bins R2 = {3'b010};
              bins R3 = {3'b011};
              bins R4 = {3'b100};
              bins R5 = {3'b101};
              bins R6 = {3'b110};
              bins R7 = {3'b111};
          }
      endgroup

      covergroup branch_rs2_cg;
        branch_rs2_cp: coverpoint branch_rs2 {
          bins R0 = {3'b000};
          bins R1 = {3'b001};
          bins R2 = {3'b010};
          bins R3 = {3'b011};
          bins R4 = {3'b100};
          bins R5 = {3'b101};
          bins R6 = {3'b110};
          bins R7 = {3'b111};
        }
      endgroup

      covergroup mem_write_cg;
        mem_write_cp : coverpoint mem_address{
          bins address[] = {[0:255]};
        }
      endgroup

      covergroup mem_read_cg;
        mem_read_cp : coverpoint mem_address{
          bins address[] = {[0:255]};
        }
      endgroup

      covergroup alu_ctrl_cg;
        alu_ctrl_cp : coverpoint alu_ctrl{
          bins ADD = {4'b0000};
          bins SUB = {4'b0001};
          bins AND = {4'b0010};
          bins OR = {4'b0011};
          bins XOR = {4'b0100};
          bins NOT = {4'b0101};
          bins PASS_A = {4'b0110};
          bins PASS_B = {4'b0111};
        }
      endgroup

      covergroup immediate_cg;
          immediate_value_cp: coverpoint immediate {
              bins negative[]     = {[5'b10000:5'b11111]};
              bins non_negative[] = {[5'b00000:5'b01111]};
          }
          immediate_instr_cp: coverpoint opcode {
              bins ADDI = {5'b00010};
              bins SUBI = {5'b00011};
              bins LI   = {5'b01001};
              bins LD   = {5'b01010};
              bins ST   = {5'b01011};
              bins BEQ  = {5'b01100};
              bins BNE  = {5'b01101};
          }
          immediate_instr_cross: cross immediate_instr_cp,
                                        immediate_value_cp;
      endgroup

      covergroup writeback_data_cg;
        writeback_data_cp: coverpoint writeback_data{
          bins zero = {16'h0000};
          bins positive = {[16'h0001:16'h7ffe]};
          bins maximum_positive = {16'h7fff};
          bins minimum_negative = {16'h8000};
          bins negative = {[16'h8001:16'hffff]};
        }
      endgroup

      covergroup rs1_rs2_cg;
          rs1_cp: coverpoint rs1 {
              bins R0 = {3'b000};
              bins R1 = {3'b001};
              bins R2 = {3'b010};
              bins R3 = {3'b011};
              bins R4 = {3'b100};
              bins R5 = {3'b101};
              bins R6 = {3'b110};
              bins R7 = {3'b111};
          }

          rs2_cp: coverpoint rs2 {
              bins R0 = {3'b000};
              bins R1 = {3'b001};
              bins R2 = {3'b010};
              bins R3 = {3'b011};
              bins R4 = {3'b100};
              bins R5 = {3'b101};
              bins R6 = {3'b110};
              bins R7 = {3'b111};
          }
          rs1_rs2_cross: cross rs1_cp, rs2_cp;
      endgroup

      covergroup opcode_rd_cg;
          opcode_cp: coverpoint opcode {
              bins ADD  = {5'b00000};
              bins SUB  = {5'b00001};
              bins ADDI = {5'b00010};
              bins SUBI = {5'b00011};
              bins AND  = {5'b00100};
              bins OR   = {5'b00101};
              bins XOR  = {5'b00110};
              bins NOT  = {5'b00111};
              bins MOV  = {5'b01000};
              bins LI   = {5'b01001};
              bins LD   = {5'b01010};
          }
          rd_cp: coverpoint rd {
              bins R1 = {3'b001};
              bins R2 = {3'b010};
              bins R3 = {3'b011};
              bins R4 = {3'b100};
              bins R5 = {3'b101};
              bins R6 = {3'b110};
              bins R7 = {3'b111};
          }
          opcode_rd_cross: cross opcode_cp, rd_cp;
      endgroup

      covergroup mem_op_addr_cg;
          mem_operation_cp: coverpoint mem_operation {
              bins LD = {1'b0};
              bins ST = {1'b1};
          }
          mem_address_cp: coverpoint mem_address {
              bins address[] = {[8'h00:8'hFF]};
          }
          mem_op_addr_cross: cross mem_operation_cp, mem_address_cp;
      endgroup

        function automatic int imm_opcode_slot(logic [4:0] op);
            case (op)
                5'b00010: return 0;
                5'b00011: return 1;
                5'b01001: return 2;
                5'b01010: return 3;
                5'b01011: return 4;
                5'b01100: return 5;
                5'b01101: return 6;
                default: return -1;
            endcase
        endfunction

        function automatic string opcode_rd_name(int slot);
            case (slot)
                0: return "ADD"; 1: return "SUB"; 2: return "ADDI";
                3: return "SUBI"; 4: return "AND"; 5: return "OR";
                6: return "XOR"; 7: return "NOT"; 8: return "MOV";
                9: return "LI"; 10: return "LD";
                default: return "UNKNOWN";
            endcase
        endfunction

        function automatic int count_nonzero_branch_rs2();
            int count;
            count = 0;
            for (int i = 0; i < 8; i++) if (branch_rs2_count[i] > 0) count++;
            return count;
        endfunction

        function automatic real pct(int covered, int total);
            if (total == 0) return 0.0;
            return 100.0 * covered / total;
        endfunction

        function new(string name = "cpu_coverage", uvm_component parent = null);
          super.new(name, parent);

          opcode_cg = new();
          branch_cg = new();
          rd_cg = new();
          rs1_cg = new();
          rs2_cg = new();
          branch_rs2_cg = new();
          mem_write_cg = new();
          mem_read_cg = new();
          alu_ctrl_cg = new();
          immediate_cg = new();
          writeback_data_cg = new();
          rs1_rs2_cg = new();
          opcode_rd_cg = new();
          mem_op_addr_cg = new();

          mem_write_count = 0;
          mem_read_count = 0;

          for (int i = 0; i < 17; i++)
              opcode_count[i] = 0;
          for(int i = 0; i < 4; i++)
            branch_cross_count[i] = 0;
          for (int i = 0; i<8; i++) begin
            rd_count[i] = 0;
            rs1_count[i] = 0;
              rs2_count[i] = 0;
            branch_rs2_count[i] = 0;
            alu_ctrl_count[i] = 0;
          end

          opcode_total = 0; branch_total = 0; rd_total = 0;
          rs1_total = 0; rs2_total = 0; alu_total = 0;
          branch_rs2_total = 0; alu_invalid_count = 0;
          immediate_total = 0; writeback_total = 0;
          rs1_rs2_total = 0; opcode_rd_total = 0; mem_op_addr_total = 0;
          for (int i = 0; i < 224; i++) imm_cross_count[i] = 0;
          for (int i = 0; i < 64; i++) rs1_rs2_count[i] = 0;
          for (int i = 0; i < 77; i++) opcode_rd_count[i] = 0;
          for (int i = 0; i < 512; i++) mem_op_addr_count[i] = 0;
          for (int i = 0; i < 5; i++) writeback_bin_count[i] = 0;
          for (int i = 0; i < 256; i++) begin
            mem_addr_count_w[i] = 0;
            mem_addr_count_r[i] = 0;
          end

        endfunction

//         function void build_phase(uvm_phase phase);
//           super.build_phase(phase);
//         endfunction

        function void write(cpu_monitor_transaction t);

            if (t.event_kind == cpu_monitor_transaction::INSTR_EVENT) begin

                opcode = t.instruction[15:11];
                rd     = t.instruction[10:8];
                rs1    = t.instruction[7:5];
                rs2    = t.instruction[4:2];
                  immediate    = t.instruction[4:0];

                // OPCODE COVERAGE
                opcode_cg.sample();
                opcode_total++;

                // DESTINATION REGISTER COVERAGE
                case (opcode)
                    5'b00000, 5'b00001, 5'b00010, 5'b00011,
                    5'b00100, 5'b00101, 5'b00110, 5'b00111,
                    5'b01000, 5'b01001, 5'b01010: begin
                        if (rd != 3'b000) begin
                            rd_cg.sample();
                            rd_total++;
                            case (rd)
                                3'b001: rd_count[1]++;
                                3'b010: rd_count[2]++;
                                3'b011: rd_count[3]++;
                                3'b100: rd_count[4]++;
                                3'b101: rd_count[5]++;
                                3'b110: rd_count[6]++;
                                3'b111: rd_count[7]++;
                            endcase
                        end
                    end
                endcase

                // RS1 SOURCE REGISTER COVERAGE
                case (opcode)
                    // ADD, SUB, ADDI, SUBI
                    5'b00000, 5'b00001, 5'b00010, 5'b00011,
                    // AND, OR, XOR, NOT, MOV
                    5'b00100, 5'b00101, 5'b00110, 5'b00111, 5'b01000,
                    // LD, ST, BEQ, BNE
                    5'b01010, 5'b01011, 5'b01100, 5'b01101: begin
                        rs1_cg.sample();
                        rs1_total++;
                        rs1_count[rs1]++;
                    end
                endcase

                // RS2 SOURCE REGISTER COVERAGE
                case (opcode)
                    // ADD, SUB, AND, OR, XOR
                    5'b00000, 5'b00001, 5'b00100,
                    5'b00101, 5'b00110: begin
                        rs2_cg.sample();
                        rs2_total++;
                        rs2_count[rs2]++;
                    end
                endcase

              // BRANCH SECOND OPERAND COVERAGE (rs1 field is a source for BEQ/BNE)
                if (opcode == 5'b01100 || opcode == 5'b01101) begin
                    branch_rs2 = rs1;
                    branch_rs2_cg.sample();
                    branch_rs2_total++;
                    branch_rs2_count[branch_rs2]++;
                end

                //IMMEDIATE CROSS COVERAGE
                  case (opcode)
                    5'b00010, 5'b00011, 5'b01001, 5'b01010,
                      5'b01011, 5'b01100, 5'b01101: begin
                      immediate_cg.sample();
                      immediate_total++;
                      imm_slot = imm_opcode_slot(opcode);
                      if (imm_slot >= 0)
                          imm_cross_count[(imm_slot * 32) + immediate]++;
                    end
                endcase

                // RS1 x RS2 COVERAGE
                case (opcode)
                    5'b00000, 5'b00001, 5'b00100,
                    5'b00101, 5'b00110: begin
                        rs1_rs2_cg.sample();
                        rs1_rs2_total++;
                        rs1_rs2_count[(rs1 * 8) + rs2]++;
                    end
                endcase

                // OPCODE x RD COVERAGE
                case (opcode)
                    5'b00000, 5'b00001, 5'b00010, 5'b00011,
                    5'b00100, 5'b00101, 5'b00110, 5'b00111,
                    5'b01000, 5'b01001, 5'b01010: begin
                        if (rd != 3'b000) begin
                            opcode_rd_cg.sample();
                            opcode_rd_total++;
                            case (opcode)
                                5'b00000: opcode_rd_count[0*7+rd-1]++;
                                5'b00001: opcode_rd_count[1*7+rd-1]++;
                                5'b00010: opcode_rd_count[2*7+rd-1]++;
                                5'b00011: opcode_rd_count[3*7+rd-1]++;
                                5'b00100: opcode_rd_count[4*7+rd-1]++;
                                5'b00101: opcode_rd_count[5*7+rd-1]++;
                                5'b00110: opcode_rd_count[6*7+rd-1]++;
                                5'b00111: opcode_rd_count[7*7+rd-1]++;
                                5'b01000: opcode_rd_count[8*7+rd-1]++;
                                5'b01001: opcode_rd_count[9*7+rd-1]++;
                                5'b01010: opcode_rd_count[10*7+rd-1]++;
                            endcase
                        end
                    end
                endcase

                // MANUAL OPCODE HIT COUNTERS
                if (opcode <= 5'b10000)
                    opcode_count[opcode]++;
            end

          // BRANCH COVERAGE
              else if (t.event_kind == cpu_monitor_transaction::BRANCH_EVENT) begin
                branch_opcode = t.branch_opcode;
                branch_taken  = t.branch_taken;
                branch_cg.sample();
                branch_total++;

                case ({branch_opcode, branch_taken})
                    6'b011000: branch_cross_count[0]++; // BEQ not taken
                    6'b011001: branch_cross_count[1]++; // BEQ taken
                    6'b011010: branch_cross_count[2]++; // BNE not taken
                    6'b011011: branch_cross_count[3]++; // BNE taken
                endcase
            end

            // WRITEBACK DATA COVERAGE
            else if (t.event_kind == cpu_monitor_transaction::REG_WRITE) begin
                writeback_data = t.writeback_data;
                writeback_data_cg.sample();
                writeback_total++;
                if (writeback_data == 16'h0000) writeback_bin_count[0]++;
                else if (writeback_data <= 16'h7ffe) writeback_bin_count[1]++;
                else if (writeback_data == 16'h7fff) writeback_bin_count[2]++;
                else if (writeback_data == 16'h8000) writeback_bin_count[3]++;
                else writeback_bin_count[4]++;
            end

            // MEM_WRITE COVERAGE
              else if (t.event_kind == cpu_monitor_transaction::MEM_WRITE) begin
                  mem_address = t.data_address;
                  mem_write_cg.sample();
                mem_write_count++;
                  mem_addr_count_w[mem_address]++;
                mem_operation = 1'b1;
                mem_op_addr_cg.sample();
                mem_op_addr_total++;
                mem_op_addr_count[256 + mem_address]++;
            end

            // MEM_READ COVERAGE
              else if (t.event_kind == cpu_monitor_transaction::MEM_READ) begin
                  mem_address = t.data_address;
                  mem_read_cg.sample();
                mem_read_count++;
                  mem_addr_count_r[mem_address]++;
                mem_operation = 1'b0;
                mem_op_addr_cg.sample();
                mem_op_addr_total++;
                mem_op_addr_count[mem_address]++;
            end

            // ALU_CTRL COVERAGE
              else if (t.event_kind == cpu_monitor_transaction::ALU_EVENT) begin
                  alu_ctrl = t.alu_ctrl;
                alu_ctrl_cg.sample();
                alu_total++;
              case(alu_ctrl)
                4'b0000 : alu_ctrl_count[0]++;   //ADD
                4'b0001 : alu_ctrl_count[1]++;    //SUB
                4'b0010 : alu_ctrl_count[2]++;    //AND
                4'b0011 : alu_ctrl_count[3]++;    //OR
                4'b0100 : alu_ctrl_count[4]++;   //XOR
                4'b0101 : alu_ctrl_count[5]++;   //NOT
                4'b0110 : alu_ctrl_count[6]++;    //PASS_A
                4'b0111 : alu_ctrl_count[7]++;  //PASS_B
                default : alu_invalid_count++;
              endcase
            end

            // HALT COVERAGE
            else if (t.event_kind == cpu_monitor_transaction::HALT_EVENT) begin
                opcode = t.instruction[15:11];
                opcode_cg.sample();
                opcode_total++;
                if (opcode <= 5'b10000)
                    opcode_count[opcode]++;
            end
        endfunction

        function void report_phase(uvm_phase phase);
            int branch_covered;
            int imm_opcode_hits, imm_unique_values;
            string imm_name;
            int branch_opcode_covered, branch_outcome_covered;
            int imm_value_covered, imm_opcode_covered;
            int rs1_rs2_rs1_covered, rs1_rs2_rs2_covered;
            int opcode_rd_opcode_covered, opcode_rd_rd_covered;
            int mem_op_covered, mem_addr_covered;
            real aggregate_cov;
            super.report_phase(phase);

            opcode_covered = 0; rd_covered = 0; rs1_covered = 0;
            rs2_covered = 0; alu_covered = 0; immediate_covered = 0;
            writeback_covered = 0; rs1_rs2_covered = 0;
            opcode_rd_covered = 0; mem_op_addr_covered = 0;
            mem_write_covered = 0; mem_read_covered = 0;
            branch_covered = 0;
            branch_opcode_covered = 0; branch_outcome_covered = 0;
            imm_value_covered = 0; imm_opcode_covered = 0;
            rs1_rs2_rs1_covered = 0; rs1_rs2_rs2_covered = 0;
            opcode_rd_opcode_covered = 0; opcode_rd_rd_covered = 0;
            mem_op_covered = 0; mem_addr_covered = 0;

            for (int i = 0; i < 17; i++) if (opcode_count[i] > 0) opcode_covered++;
            for (int i = 1; i < 8; i++) if (rd_count[i] > 0) rd_covered++;
            for (int i = 0; i < 8; i++) begin
                if (rs1_count[i] > 0) rs1_covered++;
                if (rs2_count[i] > 0) rs2_covered++;
                if (alu_ctrl_count[i] > 0) alu_covered++;
            end
            for (int i = 0; i < 224; i++) if (imm_cross_count[i] > 0) immediate_covered++;
            for (int i = 0; i < 5; i++) if (writeback_bin_count[i] > 0) writeback_covered++;
            for (int i = 0; i < 64; i++) if (rs1_rs2_count[i] > 0) rs1_rs2_covered++;
            for (int i = 0; i < 77; i++) if (opcode_rd_count[i] > 0) opcode_rd_covered++;
            for (int i = 0; i < 512; i++) if (mem_op_addr_count[i] > 0) mem_op_addr_covered++;
            for (int i = 0; i < 256; i++) begin
                if (mem_addr_count_w[i] > 0) mem_write_covered++;
                if (mem_addr_count_r[i] > 0) mem_read_covered++;
            end
            for (int i = 0; i < 4; i++) if (branch_cross_count[i] > 0) branch_covered++;
            if ((branch_cross_count[0] + branch_cross_count[1]) > 0) branch_opcode_covered++;
            if ((branch_cross_count[2] + branch_cross_count[3]) > 0) branch_opcode_covered++;
            if ((branch_cross_count[0] + branch_cross_count[2]) > 0) branch_outcome_covered++;
            if ((branch_cross_count[1] + branch_cross_count[3]) > 0) branch_outcome_covered++;

            for (int imm = 0; imm < 32; imm++) begin
                bit seen_value;
                seen_value = 0;
                for (int op = 0; op < 7; op++)
                    if (imm_cross_count[op*32+imm] > 0) seen_value = 1;
                if (seen_value) imm_value_covered++;
            end
            for (int op = 0; op < 7; op++) begin
                bit seen_opcode;
                seen_opcode = 0;
                for (int imm = 0; imm < 32; imm++)
                    if (imm_cross_count[op*32+imm] > 0) seen_opcode = 1;
                if (seen_opcode) imm_opcode_covered++;
            end

            for (int r = 0; r < 8; r++) begin
                bit seen_rs1, seen_rs2;
                seen_rs1 = 0; seen_rs2 = 0;
                for (int c = 0; c < 8; c++) begin
                    if (rs1_rs2_count[r*8+c] > 0) seen_rs1 = 1;
                    if (rs1_rs2_count[c*8+r] > 0) seen_rs2 = 1;
                end
                if (seen_rs1) rs1_rs2_rs1_covered++;
                if (seen_rs2) rs1_rs2_rs2_covered++;
            end

            for (int op = 0; op < 11; op++) begin
                bit seen_opcode;
                seen_opcode = 0;
                for (int r = 0; r < 7; r++)
                    if (opcode_rd_count[op*7+r] > 0) seen_opcode = 1;
                if (seen_opcode) opcode_rd_opcode_covered++;
            end
            for (int r = 0; r < 7; r++) begin
                bit seen_rd;
                seen_rd = 0;
                for (int op = 0; op < 11; op++)
                    if (opcode_rd_count[op*7+r] > 0) seen_rd = 1;
                if (seen_rd) opcode_rd_rd_covered++;
            end

            for (int op = 0; op < 2; op++) begin
                bit seen_operation;
                seen_operation = 0;
                for (int a = 0; a < 256; a++)
                    if (mem_op_addr_count[op*256+a] > 0) seen_operation = 1;
                if (seen_operation) mem_op_covered++;
            end
            for (int a = 0; a < 256; a++) begin
                bit seen_address;
                seen_address = 0;
                if (mem_op_addr_count[a] > 0 || mem_op_addr_count[256+a] > 0)
                    seen_address = 1;
                if (seen_address) mem_addr_covered++;
            end

            $display("\n============================================================");
            $display("                 CPU FUNCTIONAL COVERAGE");
            $display("============================================================");

            $display("\n[1] OPCODE");
            $display("Total hits=%0d | Covered=%0d/17 | Coverpoint=%.2f%% | Cross=N/A | Aggregate=%.2f%%",
                     opcode_total, opcode_covered, pct(opcode_covered,17), pct(opcode_covered,17));
            for (int i = 0; i < 17; i++)
                if (opcode_count[i] > 0) $display("  %05b : %0d", i, opcode_count[i]);

            $display("\n[2] BRANCH OPCODE x OUTCOME");
            aggregate_cov = (pct(branch_opcode_covered,2) + pct(branch_outcome_covered,2) + pct(branch_covered,4)) / 3.0;
            $display("Total hits=%0d | Opcode CP=%0d/2 (%.2f%%) | Outcome CP=%0d/2 (%.2f%%)",
                     branch_total, branch_opcode_covered, pct(branch_opcode_covered,2),
                     branch_outcome_covered, pct(branch_outcome_covered,2));
            $display("Cross=%0d/4 (%.2f%%) | Aggregate coverage=%.2f%%",
                     branch_covered, pct(branch_covered,4), aggregate_cov);
            $display("  BEQ : not-taken=%0d, taken=%0d", branch_cross_count[0], branch_cross_count[1]);
            $display("  BNE : not-taken=%0d, taken=%0d", branch_cross_count[2], branch_cross_count[3]);

            $display("\n[3] DESTINATION REGISTER Rd");
            $display("Total writes=%0d | Coverpoint=%0d/7 (%.2f%%) | Cross=N/A | Aggregate=%.2f%%",
                     rd_total, rd_covered, pct(rd_covered,7), pct(rd_covered,7));
            for (int i = 1; i < 8; i++)
                if (rd_count[i] > 0) $display("  R%0d : %0d", i, rd_count[i]);

            $display("\n[4] SOURCE REGISTER Rs1");
            $display("Total accesses=%0d | Coverpoint=%0d/8 (%.2f%%) | Cross=N/A | Aggregate=%.2f%%",
                     rs1_total, rs1_covered, pct(rs1_covered,8), pct(rs1_covered,8));
            for (int i = 0; i < 8; i++)
                if (rs1_count[i] > 0) $display("  R%0d : %0d", i, rs1_count[i]);

            $display("\n[5] SOURCE REGISTER Rs2");
            $display("Total accesses=%0d | Coverpoint=%0d/8 (%.2f%%) | Cross=N/A | Aggregate=%.2f%%",
                     rs2_total, rs2_covered, pct(rs2_covered,8), pct(rs2_covered,8));
            for (int i = 0; i < 8; i++)
                if (rs2_count[i] > 0) $display("  R%0d : %0d", i, rs2_count[i]);

            $display("\n[6] BRANCH SECOND SOURCE REGISTER (rd FIELD)");
            $display("Total accesses=%0d | Coverpoint=%0d/8 (%.2f%%) | Cross=N/A | Aggregate=%.2f%%",
                     branch_rs2_total, count_nonzero_branch_rs2(), pct(count_nonzero_branch_rs2(),8),
                     pct(count_nonzero_branch_rs2(),8));
            for (int i = 0; i < 8; i++)
                if (branch_rs2_count[i] > 0) $display("  R%0d : %0d", i, branch_rs2_count[i]);

            $display("\n[7] MEMORY WRITE ADDRESS");
            $display("Total writes=%0d | Coverpoint=%0d/256 (%.2f%%) | Cross=N/A | Aggregate=%.2f%%",
                     mem_write_count, mem_write_covered, pct(mem_write_covered,256), pct(mem_write_covered,256));
            for (int i = 0; i < 256; i++)
                if (mem_addr_count_w[i] > 0) $display("  0x%02h : %0d writes", i, mem_addr_count_w[i]);

            $display("\n[8] MEMORY READ ADDRESS");
            $display("Total reads=%0d | Coverpoint=%0d/256 (%.2f%%) | Cross=N/A | Aggregate=%.2f%%",
                     mem_read_count, mem_read_covered, pct(mem_read_covered,256), pct(mem_read_covered,256));
            for (int i = 0; i < 256; i++)
                if (mem_addr_count_r[i] > 0) $display("  0x%02h : %0d reads", i, mem_addr_count_r[i]);

            $display("\n[9] ALU CONTROL");
            $display("Total operations=%0d | Valid coverpoint=%0d/8 (%.2f%%) | Invalid controls=%0d | Cross=N/A | Aggregate=%.2f%%",
                     alu_total, alu_covered, pct(alu_covered,8), alu_invalid_count, pct(alu_covered,8));
            for (int i = 0; i < 8; i++)
                if (alu_ctrl_count[i] > 0) $display("  ALU control %04b : %0d", i, alu_ctrl_count[i]);

            $display("\n[10] IMMEDIATE OPCODE x VALUE");
            aggregate_cov = (pct(imm_opcode_covered,7) + pct(imm_value_covered,32) + pct(immediate_covered,224)) / 3.0;
            $display("Total samples=%0d | Opcode CP=%0d/7 (%.2f%%) | Immediate CP=%0d/32 (%.2f%%)",
                     immediate_total, imm_opcode_covered, pct(imm_opcode_covered,7),
                     imm_value_covered, pct(imm_value_covered,32));
            $display("Cross=%0d/224 (%.2f%%) | Aggregate coverage=%.2f%%",
                     immediate_covered, pct(immediate_covered,224), aggregate_cov);
            for (int op = 0; op < 7; op++) begin
                imm_opcode_hits = 0;
                imm_unique_values = 0;
                case (op)
                    0: imm_name = "ADDI";
                    1: imm_name = "SUBI";
                    2: imm_name = "LI";
                    3: imm_name = "LD";
                    4: imm_name = "ST";
                    5: imm_name = "BEQ";
                    6: imm_name = "BNE";
                endcase
                for (int imm = 0; imm < 32; imm++) begin
                    imm_opcode_hits += imm_cross_count[op*32+imm];
                    if (imm_cross_count[op*32+imm] > 0) imm_unique_values++;
                end
                $display("  %-4s : %0d hits | %0d unique immediate values / 32",
                         imm_name, imm_opcode_hits, imm_unique_values);
            end

            $display("\n[11] WRITEBACK DATA DISTRIBUTION");
            $display("Total register writes=%0d | Coverpoint=%0d/5 (%.2f%%) | Cross=N/A | Aggregate=%.2f%%",
                     writeback_total, writeback_covered, pct(writeback_covered,5), pct(writeback_covered,5));
            $display("  Zero=%0d | Positive=%0d | Max positive=%0d | Min negative=%0d | Negative=%0d",
                     writeback_bin_count[0], writeback_bin_count[1], writeback_bin_count[2],
                     writeback_bin_count[3], writeback_bin_count[4]);

            $display("\n[12] Rs1 x Rs2 CROSS");
            aggregate_cov = (pct(rs1_rs2_rs1_covered,8) + pct(rs1_rs2_rs2_covered,8) + pct(rs1_rs2_covered,64)) / 3.0;
            $display("Total samples=%0d | Rs1 CP=%0d/8 (%.2f%%) | Rs2 CP=%0d/8 (%.2f%%)",
                     rs1_rs2_total, rs1_rs2_rs1_covered, pct(rs1_rs2_rs1_covered,8),
                     rs1_rs2_rs2_covered, pct(rs1_rs2_rs2_covered,8));
            $display("Cross=%0d/64 (%.2f%%) | Aggregate coverage=%.2f%%",
                     rs1_rs2_covered, pct(rs1_rs2_covered,64), aggregate_cov);
            for (int i = 0; i < 64; i++)
                if (rs1_rs2_count[i] > 0)
                    $display("  R%0d x R%0d : %0d", i/8, i%8, rs1_rs2_count[i]);

            $display("\n[13] OPCODE x Rd CROSS");
            aggregate_cov = (pct(opcode_rd_opcode_covered,11) + pct(opcode_rd_rd_covered,7) + pct(opcode_rd_covered,77)) / 3.0;
            $display("Total samples=%0d | Opcode CP=%0d/11 (%.2f%%) | Rd CP=%0d/7 (%.2f%%)",
                     opcode_rd_total, opcode_rd_opcode_covered, pct(opcode_rd_opcode_covered,11),
                     opcode_rd_rd_covered, pct(opcode_rd_rd_covered,7));
            $display("Cross=%0d/77 (%.2f%%) | Aggregate coverage=%.2f%%",
                     opcode_rd_covered, pct(opcode_rd_covered,77), aggregate_cov);
            for (int i = 0; i < 77; i++)
                if (opcode_rd_count[i] > 0)
                    $display("  %s x R%0d : %0d", opcode_rd_name(i/7), (i%7)+1, opcode_rd_count[i]);

            $display("\n[14] MEMORY OPERATION x ADDRESS CROSS");
            aggregate_cov = (pct(mem_op_covered,2) + pct(mem_addr_covered,256) + pct(mem_op_addr_covered,512)) / 3.0;
            $display("Total operations=%0d | Operation CP=%0d/2 (%.2f%%) | Address CP=%0d/256 (%.2f%%)",
                     mem_op_addr_total, mem_op_covered, pct(mem_op_covered,2),
                     mem_addr_covered, pct(mem_addr_covered,256));
            $display("Cross=%0d/512 (%.2f%%) | Aggregate coverage=%.2f%%",
                     mem_op_addr_covered, pct(mem_op_addr_covered,512), aggregate_cov);
            for (int i = 0; i < 512; i++)
                if (mem_op_addr_count[i] > 0)
                    $display("  %s @ 0x%02h : %0d", (i < 256) ? "LD" : "ST",
                             i%256, mem_op_addr_count[i]);

            $display("\n============================================================");
            $display("Aggregate coverage = arithmetic mean of constituent coverpoint and cross percentages.");
            $display("Only hit bins/combinations are listed; coverage uses all defined bins.");
            $display("============================================================");
        endfunction

    endclass

`endif
