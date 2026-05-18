module controller (instruction, clk, rst);
  input [15:0] instruction;
  input clk, rst;

  reg [15:0] bus; 
  wire [4:0] drive, load;
  wire [2:0] drive_reg_code, load_reg_code;
  wire [15:0] a_to_alu, alu_to_g, immediate;
  wire add_or_sub, imm_enable;
  wire [15:0] r0_out, r1_out, r2_out, g_out;

  fsm control_unit (
    .instruction(instruction),.clk(clk),.rst(rst),
    .load_reg(load_reg_code),.drive_reg(drive_reg_code),
    .add_or_sub(add_or_sub),.immediate(immediate),.imm_enable(imm_enable)
  );

  alu logic_unit (
    .reg_in(a_to_alu),.bus_in(bus), 
    .out(alu_to_g),.add_or_sub(add_or_sub)
  );

  bus_reg r0 (.load(load[0]),.out(r0_out),.in(bus),.clk(clk),.rst(rst));
  bus_reg r1 (.load(load[1]),.out(r1_out),.in(bus),.clk(clk),.rst(rst));
  bus_reg r2 (.load(load[2]),.out(r2_out),.in(bus),.clk(clk),.rst(rst));
  bus_reg g  (.load(load[3]),.out(g_out),.in(alu_to_g),.clk(clk),.rst(rst));
  bus_reg a  (.load(load[4]),.out(a_to_alu),.in(bus),.clk(clk),.rst(rst));

  reg_decoder load_dec (.reg_code(load_reg_code),.enable(load));
  reg_decoder drive_dec (.reg_code(drive_reg_code),.enable(drive));

  always @(*) begin // allows only one register to drive the bus at a time
    case (drive_reg_code) // prevents a contention over bus driving
      3'b000:  bus = r0_out;
      3'b001:  bus = r1_out;
      3'b010:  bus = r2_out;
      3'b011:  bus = g_out;
      3'b101:  bus = immediate; 
      default: bus = 16'h0000;
    endcase
  end
endmodule

