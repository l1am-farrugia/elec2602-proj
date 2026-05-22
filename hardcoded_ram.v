module hardcoded_ram(
	input[5:0] address,
	output reg[15:0] instruction
);

	always @(address) begin
		case (address)
			// Program:
			//   0: LDI r0 decode    0x0000
			//   1: LDI r0 = 5       0x0005
			//   2: LDI r1 decode    0x0400
			//   3: LDI r1 = 3       0x0003
			//   4: INC r0            0x4000   (r0 = 5+1 = 6)
			//   5: DEC r1            0x5400   (r1 = 3-1 = 2)
			//   6: MUL r0, r1       0x6100   (r0 = 6*2 = 12)
			//   7: LDI r2 decode    0x0800
			//   8: LDI r2 = 12      0x000C
			//   9: CMP r0, r2       0x7200   (r0 vs r2: equal, status[1]=1)
			//  10: BREQ +3          0x8180   (branch to addr 13 if equal)
			//  11: LDI r2 decode    0x0800   (SKIPPED by branch)
			//  12: LDI r2 = 99      0x0063   (SKIPPED by branch)
			//  13: MOV r2, r0       0x1800   (r2 = r0 = 12)
			//  14: LDI r2 decode    0x0800   (for BRH test)
			//  15: LDI r2 = 7       0x0007
			//  16: CMP r0, r2       0x7200   (r0=12 vs r2=7: higher, status[0]=1)
			//  17: BRH +2           0x9100   (branch to addr 19 if higher)
			//  18: LDI r2 = 0       0x0000   (SKIPPED)
			//  19: MOV r1, r0       0x1400   (r1 = r0 = 12)
			6'd0: instruction = 16'h0000;
			6'd1: instruction = 16'h0005;
			6'd2: instruction = 16'h0400;
			6'd3: instruction = 16'h0003;
			6'd4: instruction = 16'h4000;
			6'd5: instruction = 16'h5400;
			6'd6: instruction = 16'h6100;
			6'd7: instruction = 16'h0800;
			6'd8: instruction = 16'h000C;
			6'd9: instruction = 16'h7200;
			6'd10: instruction = 16'h8180;
			6'd11: instruction = 16'h0800;
			6'd12: instruction = 16'h0063;
			6'd13: instruction = 16'h1800;
			6'd14: instruction = 16'h0800;
			6'd15: instruction = 16'h0007;
			6'd16: instruction = 16'h7200;
			6'd17: instruction = 16'h9100;
			6'd18: instruction = 16'h0000;
			6'd19: instruction = 16'h1400;
			6'd20: instruction = 16'h1400;
			6'd19: instruction = 16'h1400;
			
			default: instruction = 16'h0000;
		endcase
	end

endmodule