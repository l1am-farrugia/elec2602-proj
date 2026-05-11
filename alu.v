module alu (reg_in, bus_in, out, add_or_sub);
  input [15:0] reg_in, bus_in;
  input add_or_sub;
  output reg [15:0] out;

  always @(*) begin
    if (add_or_sub == 1'b0)
      out = reg_in + bus_in;
    else
      out = reg_in - bus_in;
  end
endmodule
