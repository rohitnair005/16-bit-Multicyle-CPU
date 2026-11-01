`ifndef CPU_SCOREBOARD_SV
`define CPU_SCOREBOARD_SV

`include "uvm_macros.svh"

class cpu_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(cpu_scoreboard)

    uvm_analysis_imp #(cpu_monitor_transaction, cpu_scoreboard) ai;

    logic [15:0] register_array [0:7];
    logic [15:0] data_memory [0:255];

    bit register_known [0:7];
    bit memory_known [0:255];

    logic [7:0] expected_pc;
    bit have_previous_instruction;

    int halt_count;

    function new(string name = "cpu_scoreboard",
                 uvm_component parent = null);
        super.new(name, parent);
        ai = new("ai", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        for (int i = 0; i < 8; i++) begin
            register_array[i] = 16'd0;
            register_known[i] = 1'b1;
        end

        for (int i = 0; i < 256; i++) begin
            data_memory[i] = 16'd0;
            memory_known[i] = 1'b0;
        end

        expected_pc = 8'd0;
        have_previous_instruction = 1'b0;
        halt_count = 0;
    endfunction


    // Independently predict the next instruction address.
    function logic [7:0] calculate_next_pc(
        input logic [7:0] pc,
        input logic [15:0] instruction
    );
        logic [4:0] opcode;
        logic [2:0] rd, rs1;
        logic signed [7:0] branch_offset;

        opcode = instruction[15:11];
        rd     = instruction[10:8];
        rs1    = instruction[7:5];

        branch_offset = {{3{instruction[4]}}, instruction[4:0]};

        case (opcode)
            5'b01110: begin // JMP
                calculate_next_pc = instruction[10:3];
            end

            5'b01100: begin // BEQ
                if (!register_known[rd] || !register_known[rs1]) begin
                    `uvm_warning("SCB_BRANCH",
                        "BEQ comparison uses an unknown reference register")
                    calculate_next_pc = pc + 8'd1;
                end
                else if (register_array[rd] == register_array[rs1]) begin
                    calculate_next_pc =
                  (pc + 8'd1) + {{3{instruction[4]}}, instruction[4:0]};
                end
                else begin
                    calculate_next_pc = pc + 8'd1;
                end
            end

            5'b01101: begin // BNE
                if (!register_known[rd] || !register_known[rs1]) begin
                    `uvm_warning("SCB_BRANCH",
                        "BNE comparison uses an unknown reference register")
                    calculate_next_pc = pc + 8'd1;
                end
                else if (register_array[rd] != register_array[rs1]) begin
                    calculate_next_pc =
                  (pc + 8'd1) + {{3{instruction[4]}}, instruction[4:0]};
                end
                else begin
                    calculate_next_pc = pc + 8'd1;
                end
            end

            default: begin
                // Includes NOP and ordinary instructions.
                calculate_next_pc = pc + 8'd1;
            end
        endcase
    endfunction


    // Calculate the expected result of a register-writing instruction.
    function void check_register_write(
        input cpu_monitor_transaction tx
    );
        logic [4:0] opcode;
        logic [2:0] rd, rs1, rs2;
        logic [4:0] imm;
        logic [15:0] imm_extended;
        logic [15:0] expected;
        bit known;

        opcode = tx.instruction[15:11];
        rd = tx.instruction[10:8];
        rs1 = tx.instruction[7:5];
        rs2 = tx.instruction[4:2];
        imm = tx.instruction[4:0];

        imm_extended = {{11{imm[4]}}, imm};
        expected = 16'd0;
        known = 1'b1;

        case (opcode)
            5'b00000: begin // ADD
                expected = register_array[rs1] + register_array[rs2];
                known = register_known[rs1] && register_known[rs2];
            end

            5'b00001: begin // SUB
                expected = register_array[rs1] - register_array[rs2];
                known = register_known[rs1] && register_known[rs2];
            end

            5'b00010: begin // ADDI
                expected = register_array[rs1] + imm_extended;
                known = register_known[rs1];
            end

            5'b00011: begin // SUBI
                expected = register_array[rs1] - imm_extended;
                known = register_known[rs1];
            end

            5'b00100: begin // AND
                expected = register_array[rs1] & register_array[rs2];
                known = register_known[rs1] && register_known[rs2];
            end

            5'b00101: begin // OR
                expected = register_array[rs1] | register_array[rs2];
                known = register_known[rs1] && register_known[rs2];
            end

            5'b00110: begin // XOR
                expected = register_array[rs1] ^ register_array[rs2];
                known = register_known[rs1] && register_known[rs2];
            end

            5'b00111: begin // NOT
                expected = ~register_array[rs1];
                known = register_known[rs1];
            end

            5'b01000: begin // MOV
                expected = register_array[rs1];
                known = register_known[rs1];
            end

            5'b01001: begin // LI
                expected = imm_extended;
            end

            5'b01010: begin // LD
                expected = data_memory[
                    (register_array[rs1] + imm_extended) & 16'h00FF
                ];

                known = register_known[rs1] &&
                    memory_known[
                        (register_array[rs1] + imm_extended) & 16'h00FF
                    ];
            end

            default: begin
                known = 1'b0;
                `uvm_error("SCB_OPCODE",
                    $sformatf("Unexpected register write: PC=%02h INST=%04h",
                              tx.pc, tx.instruction))
            end
        endcase

        if (!known) begin
            register_known[tx.write_addr] = 1'b0;
            `uvm_warning("SCB_UNKNOWN",
                $sformatf("Cannot verify write at PC=%02h INST=%04h",
                          tx.pc, tx.instruction))
        end
        else if (expected !== tx.writeback_data) begin
            register_known[tx.write_addr] = 1'b0;
            `uvm_error("SCB_REG",
                $sformatf(
                    "Mismatch PC=%02h INST=%04h R%0d Expected=%04h Actual=%04h",
                    tx.pc, tx.instruction, tx.write_addr,
                    expected, tx.writeback_data))
        end
        else begin
            register_array[tx.write_addr] = expected;
            register_known[tx.write_addr] = 1'b1;

            `uvm_info("SCB_REG",
                $sformatf("PASS PC=%02h R%0d = %04h",
                          tx.pc, tx.write_addr, expected),
                UVM_MEDIUM)
        end
    endfunction


    function void write(cpu_monitor_transaction tx);
        logic [4:0] opcode;
        logic [2:0] rd, rs1;
        logic [4:0] imm;
        logic [15:0] imm_extended;
        logic [7:0] expected_address;
        logic [15:0] expected_data;
        bit known_store;

        opcode = tx.instruction[15:11];
        rd = tx.instruction[10:8];
        rs1 = tx.instruction[7:5];
        imm = tx.instruction[4:0];
        imm_extended = {{11{imm[4]}}, imm};

        case (tx.event_kind)

            cpu_monitor_transaction::INSTR_EVENT: begin
                if (!have_previous_instruction) begin
                    if (tx.pc !== 8'd0) begin
                        `uvm_error("SCB_PC",
                            $sformatf("Expected initial PC=00, got %02h",
                                      tx.pc))
                    end
                    have_previous_instruction = 1'b1;
                end
                else if (tx.pc !== expected_pc) begin
                    `uvm_error("SCB_PC",
                        $sformatf(
                            "PC mismatch at instruction %04h: Expected PC=%02h Actual PC=%02h",
                            tx.instruction, expected_pc, tx.pc))
                end
                else begin
                    `uvm_info("SCB_PC",
                        $sformatf("PASS PC=%02h INST=%04h",
                                  tx.pc, tx.instruction),
                        UVM_MEDIUM)
                end

                case (opcode)
                    5'b01110: begin // JMP
                        `uvm_info("SCB_FLOW",
                            $sformatf("JMP at PC=%02h -> %02h",
                                      tx.pc, tx.instruction[10:3]),
                            UVM_MEDIUM)
                    end

                    5'b01100: begin // BEQ
                        `uvm_info("SCB_FLOW",
                            $sformatf("BEQ at PC=%02h, R%0d vs R%0d",
                                      tx.pc, rd, rs1),
                            UVM_MEDIUM)
                    end

                    5'b01101: begin // BNE
                        `uvm_info("SCB_FLOW",
                            $sformatf("BNE at PC=%02h, R%0d vs R%0d",
                                      tx.pc, rd, rs1),
                            UVM_MEDIUM)
                    end

                    5'b01111: begin // NOP
                        `uvm_info("SCB_FLOW",
                            $sformatf("NOP at PC=%02h", tx.pc),
                            UVM_MEDIUM)
                    end

                    5'b10000: begin // HALT
                        `uvm_info("SCB_FLOW",
                            $sformatf("HALT instruction at PC=%02h", tx.pc),
                            UVM_MEDIUM)
                    end

                    default: begin
                    end
                endcase

                // HALT has no expected next instruction.
                if (opcode == 5'b10000) begin
                    have_previous_instruction = 1'b0;
                end
                else begin
                    expected_pc = calculate_next_pc(tx.pc, tx.instruction);
                end
            end


            cpu_monitor_transaction::REG_WRITE: begin
                if (tx.write_addr != 3'd0)
                    check_register_write(tx);
            end


            cpu_monitor_transaction::MEM_WRITE: begin
                if (opcode != 5'b01011) begin
                    `uvm_error("SCB_MEM",
                        "Memory write event was not generated by ST")
                end
                else begin
                    expected_address =
                        (register_array[rs1] + imm_extended) & 16'h00FF;
                    expected_data = register_array[rd];

                    known_store =
                        register_known[rs1] && register_known[rd];

                    if (!known_store) begin
                        `uvm_warning("SCB_UNKNOWN",
                            "Cannot verify store: reference address/data unknown")
                    end
                    else if ((tx.data_address !== expected_address) ||
                             (tx.store_data !== expected_data)) begin
                        `uvm_error("SCB_MEM",
                            $sformatf(
                                "Store mismatch: expected MEM[%02h]=%04h, actual MEM[%02h]=%04h",
                                expected_address, expected_data,
                                tx.data_address, tx.store_data))
                    end
                    else begin
                        data_memory[expected_address] = expected_data;
                        memory_known[expected_address] = 1'b1;

                        `uvm_info("SCB_MEM",
                            $sformatf("PASS MEM[%02h]=%04h",
                                      expected_address, expected_data),
                            UVM_MEDIUM)
                    end
                end
            end


            cpu_monitor_transaction::HALT_EVENT: begin
                halt_count++;
                if (opcode != 5'b10000) begin
                    `uvm_error("SCB_HALT",
                        $sformatf("Halt event on non-HALT instruction %04h",
                                  tx.instruction))
                end
                else begin
                    `uvm_info("SCB_HALT",
                        $sformatf("PASS: CPU halted at PC=%02h", tx.pc),
                        UVM_MEDIUM)
                end
            end

        endcase
    endfunction

endclass

`endif