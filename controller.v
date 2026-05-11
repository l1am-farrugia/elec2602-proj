module controller (instruction, clk, rst);
  input [15:0] instruction;
  input clk, rst;

  wire [15:0] bus;
  wire [4:0] drive; // 5 regs, r0-r2, A, G
  wire [4:0] load;
  wire [2:0] drive_reg_code;
  wire [2:0] load_reg_code;
  wire [15:0] a_to_alu;
  wire [15:0] alu_to_g;

  bus_reg r0 (.load(load[0]), .drive(drive[0]), .out(bus), .in(bus), .clk(clk), .rst(rst));
  bus_reg r1 (.load(load[1]), .drive(drive[1]), .out(bus), .in(bus), .clk(clk), .rst(rst));
  bus_reg r2 (.load(load[2]), .drive(drive[2]), .out(bus), .in(bus), .clk(clk), .rst(rst));
  bus_reg g (.load(load[3]), .drive(drive[3]), .out(bus), .in(alu_to_g), .clk(clk), .rst(rst));
  d_ff a (.D(bus), .Q(a_to_alu), .clk(clk && load[4]), .rst(rst));

  reg_decoder load_decoder (.reg_code(load_reg_code), .enable(load));
  reg_decoder drive_decoder (.reg_code(drive_reg_code), .enable(drive));

  wire add_or_sub;
  alu alu (.reg_in(a_to_alu), .bus_in(bus), .out(alu_to_g), .add_or_sub(add_or_sub));

  wire immediate_enable;
  wire [15:0] immediate;

  fsm fsm (
    .instruction(instruction),
    .clk(clk),
    .load_reg(load_reg_code),
    .drive_reg(drive_reg_code),
    .add_or_sub(add_or_sub),
    .immediate(immediate),
    .imm_enable(immediate_enable)
  );

  tri_buf immediate_tri_buf (.a(immediate), .b(bus), .enable(immediate_enable));
endmodule
