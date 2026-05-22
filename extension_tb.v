`timescale 1ns/1ps

module extension_tb;
    reg clockSignal;
    reg resetSignal;
    reg startSignal;
    reg [15:0] pmem_in;
    reg pmem_write;

    controller dut (
        .clk(clockSignal),
        .rst(resetSignal),
        .start(startSignal),
        .pmem_in(pmem_in),
        .pmem_write(pmem_write)
    );

    always begin
        #5;
        clockSignal = ~clockSignal;
    end

    // Task to wait N clock cycles
    task wait_cycles(input integer n);
        integer i;
        begin
            for (i = 0; i < n; i = i + 1)
                @(negedge clockSignal);
        end
    endtask

    // Instruction encoding:
    //   LDI  (2 words): word1 = {4'b0000, RR, 10'b0}, word2 = immediate
    //   MOV:  {4'b0001, DD, SS, 8'b0}
    //   ADD:  {4'b0010, DD, SS, 8'b0}   dest += src
    //   SUB:  {4'b0011, DD, SS, 8'b0}   dest -= src
    //   INC:  {4'b0100, DD, 10'b0}      dest += 1
    //   DEC:  {4'b0101, DD, 10'b0}      dest -= 1
    //   MUL:  {4'b0110, DD, SS, 8'b0}   dest *= src
    //   CMP:  {4'b0111, DD, SS, 8'b0}   compare, sets status
    //   BREQ: {4'b1000, OOOOO, 7'b0}    branch if equal  (offset in [11:7])
    //   BRH:  {4'b1001, OOOOO, 7'b0}    branch if higher (offset in [11:7])
    //   LD:   {4'b1010, DD, AAAAAA, 4'b0}  load reg from dmem[addr] (addr in [9:4])
    //   ST:   {4'b1011, DD, AAAAAA, 4'b0}  store reg to dmem[addr]  (addr in [9:4])

    integer test_num;
    integer pass_count;
    integer fail_count;

    task check(input [15:0] actual, input [15:0] expected, input [8*50-1:0] name);
        begin
            test_num = test_num + 1;
            if (actual === expected) begin
                $display("  PASS test %0d: %0s = %h (expected %h)", test_num, name, actual, expected);
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL test %0d: %0s = %h (expected %h)", test_num, name, actual, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("extension_tb.vcd");
        $dumpvars(0, extension_tb);

        test_num = 0;
        pass_count = 0;
        fail_count = 0;

        clockSignal = 0;
        resetSignal = 1;
        startSignal = 0;
        pmem_in = 0;
        pmem_write = 0;

        // Load program into RAM (direct access while in reset)
        //
        // Program:
        //   0: LDI r0 decode    0x0000
        //   1: LDI r0 = 5       0x0005
        //   2: LDI r1 decode    0x0400
        //   3: LDI r1 = 3       0x0003
        //   4: INC r0            0x4000   (r0 = 5+1 = 6)
        //   5: DEC r1            0x5400   (r1 = 3-1 = 2)
        //   6: MUL r0, r1       0x6100   (r0 = 6*2 = 12)
        //   7: LDI r2 decode    0x0800
        //   8: LDI r2 = 12      0x000C
        //   9: CMP r0, r2       0x7200   (r0 vs r2: equal, status[1]=1)
        //  10: BREQ +3          0x8180   (branch to addr 13 if equal)
        //  11: LDI r2 decode    0x0800   (SKIPPED by branch)
        //  12: LDI r2 = 99      0x0063   (SKIPPED by branch)
        //  13: MOV r2, r0       0x1800   (r2 = r0 = 12)
        //  14: LDI r2 decode    0x0800   (for BRH test)
        //  15: LDI r2 = 7       0x0007
        //  16: CMP r0, r2       0x7200   (r0=12 vs r2=7: higher, status[0]=1)
        //  17: BRH +2           0x9100   (branch to addr 19 if higher)
        //  18: LDI r2 = 0       0x0000   (SKIPPED)
        //  19: MOV r1, r0       0x1400   (r1 = r0 = 12)

        dut.program_memory.ram_block[0]  = 16'h0000; // LDI r0 decode
        dut.program_memory.ram_block[1]  = 16'h0005; // r0 = 5
        dut.program_memory.ram_block[2]  = 16'h0400; // LDI r1 decode
        dut.program_memory.ram_block[3]  = 16'h0003; // r1 = 3
        dut.program_memory.ram_block[4]  = 16'h4000; // INC r0
        dut.program_memory.ram_block[5]  = 16'h5400; // DEC r1
        dut.program_memory.ram_block[6]  = 16'h6100; // MUL r0, r1
        dut.program_memory.ram_block[7]  = 16'h0800; // LDI r2 decode
        dut.program_memory.ram_block[8]  = 16'h000C; // r2 = 12
        dut.program_memory.ram_block[9]  = 16'h7200; // CMP r0, r2
        dut.program_memory.ram_block[10] = 16'h8180; // BREQ +3 (to addr 13)
        dut.program_memory.ram_block[11] = 16'h0800; // (skipped) LDI r2
        dut.program_memory.ram_block[12] = 16'h0063; // (skipped) r2 = 99
        dut.program_memory.ram_block[13] = 16'h1800; // MOV r2, r0
        dut.program_memory.ram_block[14] = 16'h0800; // LDI r2 decode
        dut.program_memory.ram_block[15] = 16'h0007; // r2 = 7
        dut.program_memory.ram_block[16] = 16'h7200; // CMP r0, r2
        dut.program_memory.ram_block[17] = 16'h9100; // BRH +2 (to addr 19)
        dut.program_memory.ram_block[18] = 16'h0000; // (skipped) NOP-ish
        dut.program_memory.ram_block[19] = 16'h1400; // MOV r1, r0

        // --- LD/ST tests ---
        // At this point: r0=12, r1=12, r2=7
        //  20: ST r0, dmem[5]     0xB050  (store r0=12 to dmem addr 5)
        //      encoding: 1011_00_000101_0000 = 16'hB050
        //  21: ST r2, dmem[10]    0xB8A0  (store r2=7  to dmem addr 10)
        //      encoding: 1011_10_001010_0000 = 16'hB8A0
        //  22: LDI r0 decode      0x0000  (overwrite r0)
        //  23: LDI r0 = 0         0x0000  (r0 = 0)
        //  24: LDI r2 decode      0x0800  (overwrite r2)
        //  25: LDI r2 = 0         0x0000  (r2 = 0)
        //  26: LD r0, dmem[5]     0xA050  (load r0 from dmem addr 5, should be 12)
        //      encoding: 1010_00_000101_0000 = 16'hA050
        //  27: LD r2, dmem[10]    0xA8A0  (load r2 from dmem addr 10, should be 7)
        //      encoding: 1010_10_001010_0000 = 16'hA8A0
        dut.program_memory.ram_block[20] = 16'hB050; // ST r0, dmem[5]
        dut.program_memory.ram_block[21] = 16'hB8A0; // ST r2, dmem[10]
        dut.program_memory.ram_block[22] = 16'h0000; // LDI r0 decode
        dut.program_memory.ram_block[23] = 16'h0000; // r0 = 0
        dut.program_memory.ram_block[24] = 16'h0800; // LDI r2 decode
        dut.program_memory.ram_block[25] = 16'h0000; // r2 = 0
        dut.program_memory.ram_block[26] = 16'hA050; // LD r0, dmem[5]
        dut.program_memory.ram_block[27] = 16'hA8A0; // LD r2, dmem[10]

        // Hold reset for a few cycles
        wait_cycles(3);
        resetSignal = 0;

        $display("");
        $monitor("Time:%0t | PC:%0d | Instr:%h | State:%b | R0:%h R1:%h R2:%h | S:%h",
                $time, dut.program_counter.address, dut.instruction,
                dut.control_unit.cur_state,
                dut.r0_out, dut.r1_out, dut.r2_out, dut.s_out);

        // ============================================================
        // LDI r0, 5 — FSM states: decode(1) + LDI1(1) + LDI2(1) = 3 cycles
        // ============================================================
        $display("\n--- Test: LDI r0, 5 ---");
        wait_cycles(3);
        check(dut.r0_out, 16'h0005, "R0 after LDI r0,5");

        // ============================================================
        // LDI r1, 3 — 3 cycles
        // ============================================================
        $display("\n--- Test: LDI r1, 3 ---");
        wait_cycles(3);
        check(dut.r1_out, 16'h0003, "R1 after LDI r1,3");

        // ============================================================
        // INC r0 — decode(1) + INC1(1) + INC2(1) + INC3(1) = 4 cycles
        // ============================================================
        $display("\n--- Test: INC r0 ---");
        wait_cycles(4);
        check(dut.r0_out, 16'h0006, "R0 after INC r0 (5+1=6)");

        // ============================================================
        // DEC r1 — 4 cycles
        // ============================================================
        $display("\n--- Test: DEC r1 ---");
        wait_cycles(4);
        check(dut.r1_out, 16'h0002, "R1 after DEC r1 (3-1=2)");

        // ============================================================
        // MUL r0, r1 — decode(1) + MUL1(1) + MUL2(1) + MUL3(1) = 4 cycles
        // ============================================================
        $display("\n--- Test: MUL r0, r1 ---");
        wait_cycles(4);
        check(dut.r0_out, 16'h000C, "R0 after MUL r0,r1 (6*2=12)");

        // ============================================================
        // LDI r2, 12 — 3 cycles
        // ============================================================
        $display("\n--- Test: LDI r2, 12 ---");
        wait_cycles(3);
        check(dut.r2_out, 16'h000C, "R2 after LDI r2,12");

        // ============================================================
        // CMP r0, r2 — decode(1) + CMP1(1) + CMP2(1) + CMP3(1) = 4 cycles
        // r0=12, r2=12: equal → status[1]=1, status[0]=0
        // ============================================================
        $display("\n--- Test: CMP r0, r2 (equal) ---");
        wait_cycles(4);
        check(dut.s_out[1], 1'b1, "Status[1] (equal) after CMP 12 vs 12");
        check(dut.s_out[0], 1'b0, "Status[0] (higher) after CMP 12 vs 12");

        // ============================================================
        // BREQ +3 — decode(1) + BREQ(1) = 2 cycles
        // Should branch to addr 13, skipping LDI r2,99
        // ============================================================
        $display("\n--- Test: BREQ +3 (taken) ---");
        wait_cycles(2);

        // ============================================================
        // MOV r2, r0 — decode(1) + MOV(1) = 2 cycles
        // r2 should become 12 (from r0), NOT 99
        // ============================================================
        $display("\n--- Test: MOV r2, r0 (after branch) ---");
        wait_cycles(2);
        check(dut.r2_out, 16'h000C, "R2 = 12 (branch skipped LDI r2,99)");

        // ============================================================
        // LDI r2, 7 — 3 cycles
        // ============================================================
        $display("\n--- Test: LDI r2, 7 ---");
        wait_cycles(3);
        check(dut.r2_out, 16'h0007, "R2 after LDI r2,7");

        // ============================================================
        // CMP r0, r2 — 4 cycles
        // r0=12, r2=7: r0 > r2 → status[0]=1, status[1]=0
        // ============================================================
        $display("\n--- Test: CMP r0, r2 (higher) ---");
        wait_cycles(4);
        check(dut.s_out[0], 1'b1, "Status[0] (higher) after CMP 12 vs 7");
        check(dut.s_out[1], 1'b0, "Status[1] (equal) after CMP 12 vs 7");

        // ============================================================
        // BRH +2 — decode(1) + BRH(1) = 2 cycles
        // Should branch to addr 19
        // ============================================================
        $display("\n--- Test: BRH +2 (taken) ---");
        wait_cycles(2);

        // ============================================================
        // MOV r1, r0 — 2 cycles
        // ============================================================
        $display("\n--- Test: MOV r1, r0 (after BRH) ---");
        wait_cycles(2);
        check(dut.r1_out, 16'h000C, "R1 = 12 (BRH skipped to MOV r1,r0)");

        // ============================================================
        // ST r0, dmem[5] — decode(1) + ST1(1) = 2 cycles
        // Stores r0=12 to data memory address 5
        // ============================================================
        $display("\n--- Test: ST r0, dmem[5] ---");
        wait_cycles(2);
        check(dut.data_memory.ram_block[5], 16'h000C, "dmem[5] after ST r0");

        // ============================================================
        // ST r2, dmem[10] — 2 cycles
        // Stores r2=7 to data memory address 10
        // ============================================================
        $display("\n--- Test: ST r2, dmem[10] ---");
        wait_cycles(2);
        check(dut.data_memory.ram_block[10], 16'h0007, "dmem[10] after ST r2");

        // ============================================================
        // LDI r0, 0 — 3 cycles (clear r0 to prove LD works)
        // ============================================================
        $display("\n--- Test: LDI r0, 0 ---");
        wait_cycles(3);
        check(dut.r0_out, 16'h0000, "R0 after LDI r0,0");

        // ============================================================
        // LDI r2, 0 — 3 cycles (clear r2 to prove LD works)
        // ============================================================
        $display("\n--- Test: LDI r2, 0 ---");
        wait_cycles(3);
        check(dut.r2_out, 16'h0000, "R2 after LDI r2,0");

        // ============================================================
        // LD r0, dmem[5] — decode(1) + LD1(1) = 2 cycles
        // Should reload r0 with 12 from data memory
        // ============================================================
        $display("\n--- Test: LD r0, dmem[5] ---");
        wait_cycles(2);
        check(dut.r0_out, 16'h000C, "R0 after LD r0,dmem[5] (should be 12)");

        // ============================================================
        // LD r2, dmem[10] — 2 cycles
        // Should reload r2 with 7 from data memory
        // ============================================================
        $display("\n--- Test: LD r2, dmem[10] ---");
        wait_cycles(2);
        check(dut.r2_out, 16'h0007, "R2 after LD r2,dmem[10] (should be 7)");

        // ============================================================
        // Summary
        // ============================================================
        $display("\n========================================");
        $display("  Results: %0d passed, %0d failed out of %0d tests", pass_count, fail_count, test_num);
        $display("========================================\n");

        #50 $finish;
    end

endmodule

// compile:
// iverilog -o extension_tb alu.v bus_reg.v controller.v d_ff.v fsm.v reg_decoder.v pc.v ram.v extension_tb.v
//
// run:
// vvp extension_tb
