module ram (
  input clk,
  input write_enable,
  input [5:0] address,
  input [15:0] data_in,
  output [15:0] data_out
);
  reg [15:0]ram_block[0:1023];

  assign data_out = ram_block[address];

  always @(posedge clk) begin
    if (write_enable)
      ram_block[address] <= data_in;
  end
  
endmodule



