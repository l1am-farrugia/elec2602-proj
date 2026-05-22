module fsm (
    instruction,
    clk,
    rst,
    load_reg,
    drive_reg,
    alu_op,
    immediate,
    imm_enable,
    status,
    branch,
    inc_pc,
    dmem_write,
    dmem_address
);
  input [15:0] instruction;
  input clk, rst;
  input [15:0] status;
  output reg [2:0] load_reg, drive_reg;
  output reg [15:0] immediate;
  output reg [1:0] alu_op;
  output reg imm_enable;
  output reg branch, inc_pc;
  output reg dmem_write;
  output reg [5:0] dmem_address;

  reg [5:0] cur_state;
  reg [5:0] next_state;
  reg [2:0] ldi_reg_code;

  always @(posedge clk or posedge rst) begin

    if (rst) begin
      cur_state <= 6'b000000;
      ldi_reg_code <= 3'b000;
    end else begin
      cur_state <= next_state;

      if (cur_state == 6'b000000 && instruction[15:12] == 4'b0000) begin
        ldi_reg_code <= instruction[11:10];
      end

    end

  end

  always @(*) begin
    // defaults 
    load_reg   = 3'b111;
    drive_reg  = 3'b111;
    alu_op = 0;
    imm_enable = 0;
    immediate  = 16'b0;
    next_state = cur_state;
    branch = 0;
    inc_pc = 0;
    dmem_write = 0;
    dmem_address = 6'b0;

    case (cur_state)
      6'b000000: begin  // Decoding
        case (instruction[15:12])
          4'b0000: next_state = 6'b000001;  // LDI
          4'b0001: next_state = 6'b000011;  // MOV
          4'b0010: next_state = 6'b000100;  // ADD
          4'b0011: next_state = 6'b000111;  // SUB
          4'b0100: next_state = 6'b001010;  // INC
          4'b0101: next_state = 6'b001101;  // DEC
          4'b0110: next_state = 6'b010000;  // MUL
          4'b0111: next_state = 6'b010011;  // CMP
          4'b1000: next_state = 6'b010110;  // BREQ
          4'b1001: next_state = 6'b010111;  // BRH
          4'b1010: next_state = 6'b011000;  // LD
          4'b1011: next_state = 6'b011001;  // ST
          default: next_state = 6'b000000;
        endcase
      end

      6'b000001: begin
        inc_pc = 1;
        next_state = 6'b000010;
      end

      // LDI 2
      6'b000010: begin
        drive_reg  = 3'b101;
        load_reg   = ldi_reg_code;
        imm_enable = 1;
        immediate  = instruction;
        next_state = 6'b000000;
        inc_pc = 1;
      end

      // MOV
      6'b000011: begin
        load_reg   = instruction[11:10];
        drive_reg  = instruction[9:8];
        next_state = 6'b000000;
        inc_pc = 1;
      end

      // ADD 1
      6'b000100: begin
        drive_reg  = instruction[11:10];
        load_reg   = 3'b100;  // A
        next_state = 6'b000101;
      end

      // ADD 2
      6'b000101: begin
        drive_reg  = instruction[9:8];
        load_reg   = 3'b011;  // G
        alu_op = 0;
        next_state = 6'b000110;
      end

      // ADD 3
      6'b000110: begin
        drive_reg  = 3'b011;
        load_reg   = instruction[11:10];
        next_state = 6'b000000;
        inc_pc = 1;
      end

      // SUB 1
      6'b000111: begin
        drive_reg  = instruction[11:10];
        load_reg   = 3'b100;  // A
        next_state = 6'b001000;
      end

      // SUB 2
      6'b001000: begin
        drive_reg  = instruction[9:8];
        load_reg   = 3'b011;  // G
        alu_op = 1;
        next_state = 6'b001001;
      end

      // SUB 3
      6'b001001: begin
        drive_reg  = 3'b011;
        load_reg   = instruction[11:10];
        next_state = 6'b000000;
        inc_pc = 1;
      end

      // INC 1
      6'b001010: begin
        drive_reg  = instruction[11:10];
        load_reg   = 3'b100;  // A
        next_state = 6'b001011;
      end

      // INC 2
      6'b001011: begin
        immediate = 1;
        imm_enable = 1;
        drive_reg  = 3'b101;
        alu_op = 0;
        load_reg   = 3'b011;  // G
        next_state = 6'b001100;
      end

      // INC 3
      6'b001100: begin
        drive_reg  = 3'b011;
        load_reg   = instruction[11:10];
        next_state = 6'b000000;
        inc_pc = 1;
      end

      // DEC 1
      6'b001101: begin
        drive_reg  = instruction[11:10];
        load_reg   = 3'b100;  // A
        next_state = 6'b001110;
      end

      // DEC 2
      6'b001110: begin
        immediate = 1;
        imm_enable = 1;
        alu_op = 1;
        drive_reg  = 3'b101;
        load_reg   = 3'b011;  // G
        next_state = 6'b001111;
      end

      // DEC 3
      6'b001111: begin
        drive_reg  = 3'b011;
        load_reg   = instruction[11:10];
        next_state = 6'b000000;
        inc_pc = 1;
      end

      // MUL 1
      6'b010000: begin
        drive_reg  = instruction[11:10];
        load_reg   = 3'b100;  // A
        next_state = 6'b010001;
      end

      // MUL 2
      6'b010001: begin
        drive_reg  = instruction[9:8];
        load_reg   = 3'b011;  // G
        alu_op = 2'b10;
        next_state = 6'b010010;
      end

      // MUL 3
      6'b010010: begin
        drive_reg  = 3'b011;
        load_reg   = instruction[11:10];
        next_state = 6'b000000;
        inc_pc = 1;
      end

      // CMP 1
      6'b010011: begin
        drive_reg  = instruction[11:10];
        load_reg   = 3'b100;  // A
        next_state = 6'b010100;
      end

      // CMP 2
      6'b010100: begin
        drive_reg  = instruction[9:8];
        load_reg   = 3'b011;  // G (capture ALU compare result)
        alu_op = 2'b11;
        next_state = 6'b010101;
      end

      // CMP 3
      6'b010101: begin
        drive_reg  = 3'b011;           // drive G onto bus
        load_reg   = 3'b110;           // load status reg from bus
        next_state = 6'b000000;
        inc_pc = 1;
      end

      // BREQ 1
      6'b010110: begin
        if (status[1]) begin
          immediate = instruction[11:7];
          drive_reg  = 3'b101;
          imm_enable = 1;
          branch = 1;
        end else
          inc_pc = 1;

        next_state = 6'b000000;
      end

      // BRH 1
      6'b010111: begin
        if (status[0]) begin
          immediate = instruction[11:7];
          drive_reg  = 3'b101;
          imm_enable = 1;
          branch = 1;
        end else
          inc_pc = 1;

        next_state = 6'b000000;
      end

      // LD 1 — read data memory into register
      6'b011000: begin
        dmem_address = instruction[9:4];
        drive_reg  = 3'b110;             // drive dmem_out onto bus
        load_reg   = instruction[11:10]; // load destination register
        next_state = 6'b000000;
        inc_pc = 1;
      end

      // ST 1 — write register to data memory
      6'b011001: begin
        dmem_address = instruction[9:4];
        drive_reg  = instruction[11:10]; // drive source register onto bus
        dmem_write = 1;
        next_state = 6'b000000;
        inc_pc = 1;
      end

      default: next_state = 6'b000000;
    endcase
  end
endmodule
