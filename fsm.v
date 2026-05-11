module fsm (instruction, clk, load_reg, drive_reg, add_or_sub, immediate, imm_enable);
  input [15:0] instruction;
  input clk;
  output reg [2:0] load_reg, drive_reg;
  output reg [15:0] immediate;
  output reg add_or_sub, imm_enable;

  reg [3:0] cur_state; // 8 states
  reg [3:0] next_state;

  reg [2:0] ldi_reg_code; // helper as ldi is 2 words

  always @(*) begin
    // reset all signals
    load_reg = 3'b000;
    drive_reg = 3'b000;
    add_or_sub = 0;
    imm_enable = 0;

    case (cur_state)
      4'b0000: begin // decoding
        case (instruction[15:12])
          4'b0000 : next_state = 4'b0001; // LDI part 1
          4'b0001 : next_state = 4'b0011; // MOV
          4'b0010 : next_state = 4'b0100; // ADD part 1
          4'b0011 : next_state = 4'b0111; // SUB part 1
          default : next_state = 4'b0000; // invalid -> waiting state
        endcase
      end

      // LDI part 1
      4'b0001 : begin
        // LDI reg code is assigned on clock edge below
        next_state = 4'b0010; // LDI part 2
      end

      // LDI part 2
      4'b0010 : begin
        // load immediate value to bus
        immediate = instruction;
        imm_enable = 1;
        // load Rx
        load_reg = ldi_reg_code;
        next_state = 4'b0000;
      end

      // MOV
      4'b0011 : begin
        load_reg = instruction[11:10]; // Rx
        drive_reg = instruction[9:8]; // Ry
        next_state = 4'b0000;
      end

      // ADD part 1
      4'b0100 : begin
        drive_reg = instruction[11:10]; // Rx
        load_reg = 3'b100; // A
        next_state = 4'b0101; // ADD part 2
      end

      // ADD part 2
      4'b0101 : begin
        drive_reg = instruction[9:8]; // Ry
        load_reg = 3'b101; // G
        add_or_sub = 0; // add
        next_state = 4'b0110;
      end

      // ADD part 3
      4'b0110 : begin
        drive_reg = 3'b101; // G
        load_reg = instruction[11:10]; // Rx
        next_state = 4'b0000;
      end

      // SUB part 1
      4'b0111: begin
        drive_reg = instruction[11:10]; // Rx
        load_reg = 3'b100; // A
        next_state = 4'b1000; // ADD part 2
      end

      // SUB part 2
      4'b1000 : begin
        drive_reg = instruction[9:8]; // Ry
        load_reg = 3'b101; // G
        add_or_sub = 1; // sub
        next_state = 4'b1001;
      end

      // SUB part 3
      4'b1001 : begin
        drive_reg = 3'b101; // G
        load_reg = instruction[11:10]; // Rx
        next_state = 4'b0000;
      end

      default : next_state = 4'b0000;
    endcase
  end

  always @(posedge clk) begin
    cur_state <= next_state;

    if (cur_state == 4'b0001) // LDI part 1
      ldi_reg_code <= instruction[11:10];
  end

endmodule
