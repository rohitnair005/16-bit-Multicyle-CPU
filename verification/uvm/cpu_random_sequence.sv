`ifndef CPU_RANDOM_SEQUENCE_SV
    `define CPU_RANDOM_SEQUENCE_SV

    `include "uvm_macros.svh"

    class cpu_random_sequence extends uvm_sequence #(cpu_transaction);

        `uvm_object_utils(cpu_random_sequence)

        // Random register assignments
        rand bit [2:0] r_base;
        rand bit [2:0] r_a;
        rand bit [2:0] r_b;
        rand bit [2:0] r_d0;
        rand bit [2:0] r_d1;
        rand bit [2:0] r_d2;
        rand bit [2:0] r_d3;

        // Random initial values and signed immediates
        rand bit [4:0] base_value;
        rand bit [4:0] value_a;
        rand bit [4:0] value_b;
        rand bit signed [4:0] imm_add;
        rand bit signed [4:0] imm_sub;

        constraint valid_registers {
            r_base inside {[1:7]};
            r_a    inside {[1:7]};
            r_b    inside {[1:7]};
            r_d0   inside {[1:7]};
            r_d1   inside {[1:7]};
            r_d2   inside {[1:7]};
            r_d3   inside {[1:7]};

            r_base != r_a;
            r_base != r_b;
            r_base != r_d0;
            r_base != r_d1;
            r_base != r_d2;
            r_base != r_d3;

            r_a != r_b;
            r_a != r_d0;
            r_a != r_d1;
            r_a != r_d2;
            r_a != r_d3;

            r_b != r_d0;
            r_b != r_d1;
            r_b != r_d2;
            r_b != r_d3;

            r_d0 != r_d1;
            r_d0 != r_d2;
            r_d0 != r_d3;
            r_d1 != r_d2;
            r_d1 != r_d3;
            r_d2 != r_d3;
        }

        constraint valid_values {
            base_value inside {[1:15]};
            value_a inside {[1:15]};
            value_b inside {[1:15]};
            value_a != value_b;
        }

        constraint valid_immediates {
            imm_add inside {[-16:15]};
            imm_sub inside {[-16:15]};
        }

        function new(string name = "cpu_random_sequence");
            super.new(name);
        endfunction

        task body();

            uvm_hdl_data_t readback;
            cpu_transaction tx;
            bit [15:0] program_mem [0:20];
            string path;

            if (!this.randomize())
                `uvm_fatal("RANDOMIZE", "Program randomization failed")

            `uvm_info("RANDOM",
                $sformatf(
                    "Registers: BASE=R%0d A=R%0d B=R%0d D0=R%0d D1=R%0d D2=R%0d D3=R%0d",
                    r_base, r_a, r_b, r_d0, r_d1, r_d2, r_d3),
                UVM_LOW)

            // ------------------------------------------------
            // Generate the complete 21-instruction program
            // ------------------------------------------------

            // 0: LI base register
            program_mem[0] = {5'b01001, r_base, 3'b000, base_value};

            // 1: LI source A
            program_mem[1] = {5'b01001, r_a, 3'b000, value_a};

            // 2: LI source B
            program_mem[2] = {5'b01001, r_b, 3'b000, value_b};

            // 3: ADD D0 = A + B
            program_mem[3] = {5'b00000, r_d0, r_a, r_b, 2'b00};

            // 4: SUB D1 = A - B
            program_mem[4] = {5'b00001, r_d1, r_a, r_b, 2'b00};

            // 5: ADDI D2 = D0 + immediate
            program_mem[5] = {5'b00010, r_d2, r_d0, imm_add};

            // 6: SUBI D3 = D2 - immediate
            program_mem[6] = {5'b00011, r_d3, r_d2, imm_sub};

            // 7: AND D0 = A & B
            program_mem[7] = {5'b00100, r_d0, r_a, r_b, 2'b00};

            // 8: OR D1 = A | B
            program_mem[8] = {5'b00101, r_d1, r_a, r_b, 2'b00};

            // 9: XOR D2 = A ^ B
            program_mem[9] = {5'b00110, r_d2, r_a, r_b, 2'b00};

            // 10: NOT D3 = ~A
            program_mem[10] = {5'b00111, r_d3, r_a, 5'b00000};

            // 11: MOV D0 = B
            program_mem[11] = {5'b01000, r_d0, r_b, 5'b00000};

            // 12: ST A -> MEM[BASE + 0]
            program_mem[12] = {5'b01011, r_a, r_base, 5'b00000};

            // 13: LD D1 <- MEM[BASE + 0]
            program_mem[13] = {5'b01010, r_d1, r_base, 5'b00000};

            // 14: BEQ A, A -> taken, offset 0
            program_mem[14] = {5'b01100, r_a, r_a, 5'b00000};

            // 15: BEQ A, B -> not taken, offset 0
            program_mem[15] = {5'b01100, r_a, r_b, 5'b00000};

            // 16: BNE A, B -> taken, offset 0
            program_mem[16] = {5'b01101, r_a, r_b, 5'b00000};

            // 17: BNE A, A -> not taken, offset 0
            program_mem[17] = {5'b01101, r_a, r_a, 5'b00000};

            // 18: JMP to next instruction
            program_mem[18] = {5'b01110, 8'd19, 3'b000};

            // 19: NOP
            program_mem[19] = 16'h7800;

            // 20: HALT
            program_mem[20] = 16'h8000;

            // ------------------------------------------------
            // Load the generated program into instruction memory
            // ------------------------------------------------

            for (int i = 0; i < 21; i++) begin

                path = $sformatf(
                    "testbench.dut.instruction_memory_dut.mem[%0d]", i);

                if (!uvm_hdl_deposit(path, program_mem[i]))
                    `uvm_fatal("MEM_ACCESS",
                        $sformatf("Failed to write instruction %0d", i))

            end

            // ------------------------------------------------
            // Read back and verify every instruction
            // ------------------------------------------------

            for (int i = 0; i < 21; i++) begin

                path = $sformatf(
                    "testbench.dut.instruction_memory_dut.mem[%0d]", i);

                if (!uvm_hdl_read(path, readback))
                    `uvm_fatal("MEM_ACCESS",
                        $sformatf("Failed to read instruction %0d", i))

                if (readback[15:0] !== program_mem[i])
                    `uvm_fatal("MEM_ACCESS",
                        $sformatf("Instruction mismatch at address %0d", i))

            end

            `uvm_info("RANDOM",
                "All 21 randomized program instructions loaded and verified",
                UVM_LOW)

            // ------------------------------------------------
            // Reset CPU
            // ------------------------------------------------

            tx = cpu_transaction::type_id::create("tx");
            start_item(tx);
            tx.reset_n = 0;
            tx.resume  = 0;
            finish_item(tx);

            tx = cpu_transaction::type_id::create("tx");
            start_item(tx);
            tx.reset_n = 0;
            tx.resume  = 0;
            finish_item(tx);

            // Release reset while paused
            tx = cpu_transaction::type_id::create("tx");
            start_item(tx);
            tx.reset_n = 1;
            tx.resume  = 0;
            finish_item(tx);

            // Start execution
            tx = cpu_transaction::type_id::create("tx");
            start_item(tx);
            tx.reset_n = 1;
            tx.resume  = 1;
            finish_item(tx);

            tx = cpu_transaction::type_id::create("tx");
            start_item(tx);
            tx.reset_n = 1;
            tx.resume  = 1;
            finish_item(tx);

            // Prevent the CPU from leaving HALT
            tx = cpu_transaction::type_id::create("tx");
            start_item(tx);
            tx.reset_n = 1;
            tx.resume  = 0;
            finish_item(tx);

        endtask

    endclass

`endif
