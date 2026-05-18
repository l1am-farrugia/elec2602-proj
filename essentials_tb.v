`timescale 1ns/1ps 

module essentials_tb; 
    reg [15:0] instructionSignal; 
    reg clockSignal; 
    reg resetSignal; 

    controller dut (
        .instruction(instructionSignal),
        .clk(clockSignal),
        .rst(resetSignal)
    ); 

    always begin
        #5;
        clockSignal = ~clockSignal; 
    end

    initial begin 
        $monitor("Time:%0t | Instr:%h | Bus:%h | State:%b | R0:%h | R1:%h | R2:%h", 
                $time, instructionSignal, dut.bus, dut.control_unit.cur_state, 
                dut.r0_out, dut.r1_out, dut.r2_out);
        
        $dumpfile("essentials_tb.vcd"); 
        $dumpvars(0, essentials_tb); 

        clockSignal = 0; 
        resetSignal = 1; 
        instructionSignal = 16'h0000;
        
        // initial pause to get rid of xxxx
        @(negedge clockSignal);
        @(negedge clockSignal);
        @(negedge clockSignal); 
        resetSignal = 0; 

        // using hex for simplicity
        // load 15 into register 0 (LDI) takes 3 cycles to execute
        instructionSignal = 16'h0000; // ldi r0
        @(negedge clockSignal);     
        instructionSignal = 16'h000F; // 15
        @(negedge clockSignal); 
        @(negedge clockSignal); 

        // load 10 into register 1 (LDI) takes 3 cycles to execute
        instructionSignal = 16'h0400; // ldi r1
        @(negedge clockSignal); 
        instructionSignal = 16'h000A; // 10 
        @(negedge clockSignal); 
        @(negedge clockSignal); 

        // register 0 += register 1 (ADD) takes 4 cycles to execute
        instructionSignal = 16'h2100; 
        @(negedge clockSignal);
        @(negedge clockSignal);
        @(negedge clockSignal);
        @(negedge clockSignal); 

        // register 0 -= register 1 (SUB) takes 4 cycles to execute
        instructionSignal = 16'h3100; 
        @(negedge clockSignal);
        @(negedge clockSignal);
        @(negedge clockSignal);
        @(negedge clockSignal);

        // register 2 = register 0 (MOV) takes 2 cycles to execute
        instructionSignal = 16'h1800; 
        @(negedge clockSignal);
        @(negedge clockSignal); 

        // clears teh bus
        instructionSignal = 16'h0000;

        #20 $finish;
    end

endmodule

// compile
// iverilog -o essentials alu.v bus_reg.v controller.v fsm.v reg_decoder.v essentials_tb.v

//run
// vvp essentials
