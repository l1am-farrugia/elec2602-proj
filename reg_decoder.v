module reg_decoder(reg_code, enable);
  input [2:0] reg_code;
  output reg [8:0] enable;

  always @(*) begin
    case (reg_code)
      3'b000:  enable = 9'b000000001; // r0
      3'b001:  enable = 9'b000000010; // r1
      3'b010:  enable = 9'b000000100; // r2
      3'b011:  enable = 9'b000001000; // g
      3'b100:  enable = 9'b000010000; // a
      3'b110:  enable = 9'b000100000; // status
      default: enable = 0;
    endcase
  end
endmodule