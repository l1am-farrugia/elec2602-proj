module fsm (instruction, clk, rst, load_reg, drive_reg, add_or_sub, immediate, imm_enable);
  input [15:0] instruction;
  input clk, rst;
  output reg [2:0] load_reg, drive_reg;
  output reg [15:0] immediate;
  output reg add_or_sub, imm_enable;

  reg [3:0] cur_state; 
  reg [3:0] next_state;
  reg [2:0] ldi_reg_code; 
  
  always @(posedge clk or posedge rst) begin
    
    if (rst) begin
      cur_state <= 4'b0000;
      ldi_reg_code <= 3'b000;
    end 
    
    else begin
      cur_state <= next_state;

      if (cur_state == 4'b0000 && instruction[15:12] == 4'b0000) begin
        ldi_reg_code <= instruction[11:10];
      end

    end
    
  end

  always @(*) begin
    // defaults 
    load_reg = 3'b111;
    drive_reg = 3'b111;
    add_or_sub = 0;
    imm_enable = 0;
    immediate = 16'b0;
    next_state = cur_state; 

    case (cur_state) // based on the instruction, we choose which operation to complete
      4'b0000: begin // Decoding
        case (instruction[15:12])
          4'b0000 : next_state = 4'b0001; // LDI
          4'b0001 : next_state = 4'b0011; // MOV
          4'b0010 : next_state = 4'b0100; // ADD
          4'b0011 : next_state = 4'b0111; // SUB
          default : next_state = 4'b0000;
        endcase
      end
      
      // LDI 1 
      4'b0001 : next_state = 4'b0010; 

      // LDI 2
      4'b0010 : begin 
        drive_reg = 3'b101; // immediate onto bus
        load_reg = ldi_reg_code; // loading immediate to that ldi_reg_code
        imm_enable = 1; // we are taking a constant value not a register
        immediate = instruction; // constant value to be loaded is the instruction 
        next_state = 4'b0000;
      end

      // MOV
      4'b0011 : begin
        load_reg = instruction[11:10]; // load to destination register
        drive_reg = instruction[9:8]; // register onto bus
        next_state = 4'b0000;
      end

      // ADD 1
      4'b0100 : begin
        drive_reg = instruction[11:10]; // destination register onto bus
        load_reg = 3'b100; // load to A
        next_state = 4'b0101; 
      end

      // ADD 2
      4'b0101 : begin
        drive_reg = instruction[9:8]; // register onto bus
        load_reg = 3'b011; // load to G
        add_or_sub = 0; 
        next_state = 4'b0110;
      end

      // ADD 3 
      4'b0110 : begin
        drive_reg = 3'b011; // G onto bus         
        load_reg = instruction[11:10]; // load to destination register
        next_state = 4'b0000;          
      end

      // SUB 1
      4'b0111: begin
        drive_reg = instruction[11:10]; // destination register onto bus
        load_reg = 3'b100; // load to A
        next_state = 4'b1000; 
      end

      // SUB 2
      4'b1000 : begin
        drive_reg = instruction[9:8]; // register onto bus
        load_reg = 3'b011; // load to G 
        add_or_sub = 1; // subtract operation
        next_state = 4'b1001;
      end

      // SUB 3 
      4'b1001 : begin
        drive_reg = 3'b011; // G onto bus      
        load_reg = instruction[11:10]; // load to destination register
        next_state = 4'b0000;
      end

      default : next_state = 4'b0000;

      // after an operation is complete we return to state 0, awaiting next instruciton
    endcase
  end
endmodule
