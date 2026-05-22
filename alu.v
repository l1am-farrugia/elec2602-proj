module alu (reg_in, bus_in, out, alu_op);
  input [15:0] reg_in, bus_in;
  input [1:0] alu_op;
  output reg [15:0] out;

  always @(*) begin
    if (alu_op == 2'b00)
      // add
      out = reg_in + bus_in;
    else if (alu_op == 2'b01)
      // sub
      out = reg_in - bus_in;
    else if (alu_op == 2'b10)
      // mul
      out = reg_in * bus_in;
    else if (alu_op == 2'b11) begin
      // compare
      out[0] = reg_in > bus_in;
      out[1] = reg_in == bus_in;
    end
  end
endmodule
