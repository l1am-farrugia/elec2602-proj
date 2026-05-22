module pc(
  input clk,
  input rst,
  input start,
  input inc_pc,
  input branch,
  input [15:0] bus,
  output reg [15:0] address
);

parameter num_bits = 6;
wire low_val;
assign low_val = 1'b0;

reg [6:0] temp, temp1, temp2;

always @(posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        address <= {num_bits{low_val}};

    else if (start == 1'b1)
        address <= 6'b000001;

    else if (inc_pc == 1'b1)
        address <= address + 6'b000001;

    else if (branch == 1'b1)
    begin
        // Compute PC-relative branch target
        temp  = {1'b0, address} + {1'b0, bus[5:0]};

        // Reduce modulo 64 so it fits back into 6 bits
        temp1 = temp >> 6;
        temp2 = temp1 << 6;

        address <= temp - temp2;
    end
end

endmodule
