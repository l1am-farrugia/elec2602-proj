module bus_reg (load, out, in, clk, rst);
  input [15:0] in;
  input load, clk, rst;
  output reg [15:0] out;

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      out <= 16'h0000;
    end
      else if (load) begin
      out <= in;
    end
  end
endmodule
