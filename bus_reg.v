module bus_reg (drive, load, out, in, clk, rst);
  input [15:0] in;
  input drive, load, clk, rst;
  output [15:0] out;

  assign gated_clk = clk && load;

  wire [15:0] q_to_a;
  d_ff register (.D(in), .Q(q_to_a), .clk(gated_clk), .rst(rst));
  tri_buf tri_buf (.a(q_to_a), .b(out), .enable(drive));
endmodule
