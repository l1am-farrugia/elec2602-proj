module controller (clk, rst, start, pmem_in, pmem_write, r0_out, r1_out, r2_out);
  input clk, rst, start, pmem_write;
  input [15:0] pmem_in;

  reg [15:0] bus; 
  wire [8:0] drive, load;
  wire [2:0] drive_reg_code, load_reg_code;
  wire [15:0] a_to_alu, alu_to_g, immediate;
  wire [1:0] alu_op;
  wire imm_enable;
  output[15:0] r0_out, r1_out, r2_out;
  wire[15:0] g_out, s_out;
  wire branch, inc_pc;
  wire [5:0] address;
  wire [15:0] instruction;
  wire [15:0] dmem_out;
  wire [5:0] dmem_address;
  wire dmem_write;

  fsm control_unit (
    .instruction(instruction),.clk(clk),.rst(rst),
    .load_reg(load_reg_code),.drive_reg(drive_reg_code),
    .alu_op(alu_op),.immediate(immediate),.imm_enable(imm_enable),
    .status(s_out), .branch(branch), .inc_pc(inc_pc),
    .dmem_write(dmem_write), .dmem_address(dmem_address)
  );

  alu logic_unit (
    .reg_in(a_to_alu),.bus_in(bus), 
    .out(alu_to_g), .alu_op(alu_op)
  );

  pc program_counter (
    .clk(clk),
    .rst(rst),
    .start(start),
    .inc_pc(inc_pc),
    .branch(branch),
    .bus(bus),
    .address(address)
  );

 ram program_memory (
   .clk(clk),
   .write_enable(pmem_write),
   .address(address),
   .data_in(pmem_in),
   .data_out(instruction)
 );

	// hardcoded_ram (
	// 	.address(address),
	// 	.instruction(instruction)
	// );


  ram data_memory (
    .clk(clk),
    .write_enable(dmem_write),
    .address(dmem_address),
    .data_in(bus),
    .data_out(dmem_out)
  );

  bus_reg r0 (.load(load[0]),.out(r0_out),.in(bus),.clk(clk),.rst(rst));
  bus_reg r1 (.load(load[1]),.out(r1_out),.in(bus),.clk(clk),.rst(rst));
  bus_reg r2 (.load(load[2]),.out(r2_out),.in(bus),.clk(clk),.rst(rst));
  bus_reg g  (.load(load[3]),.out(g_out),.in(alu_to_g),.clk(clk),.rst(rst));
  bus_reg a  (.load(load[4]),.out(a_to_alu),.in(bus),.clk(clk),.rst(rst));
  bus_reg sreg (.load(load[5]),.out(s_out),.in(bus),.clk(clk),.rst(rst));

  reg_decoder load_dec (.reg_code(load_reg_code),.enable(load));
  reg_decoder drive_dec (.reg_code(drive_reg_code),.enable(drive));

  always @(*) begin // allows only one register to drive the bus at a time
    case (drive_reg_code) // prevents a contention over bus driving
      3'b000:  bus = r0_out;
      3'b001:  bus = r1_out;
      3'b010:  bus = r2_out;
      3'b011:  bus = g_out;
      3'b101:  bus = immediate; 
      3'b110:  bus = dmem_out;
      default: bus = 16'h0000;
    endcase
  end
endmodule

