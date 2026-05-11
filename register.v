module register (D, clk, rst, Q);
  input [15:0] D;
  input clk;
  output reg [15:0] Q;

  always @(posedge clk, posedge rst) begin
    if (rst==1'b1) begin
      Q = 0;
    end else begin
      Q = D;
    end
  end
endmodule
