module reg_decoder(reg_code, enable);
  input [2:0] reg_code;
  output [4:0] enable;

  always @(reg_code) begin
    case (reg_code)
      3'b001: enable = 5'b00001; // r0
      3'b010: enable = 5'b00010; // r1
      3'b011: enable = 5'b00100; // r2
      3'b100: enable = 5'b01000; // a
      3'b101: enable = 5'b10000; // g
      default: enable = 5'b00000; // none
    endcase
  end
endmodule
