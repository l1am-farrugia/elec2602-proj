module controller_instantiate (
	input CLOCK_50,
	input[3:0] KEY,
	output[6:0] HEX0,
	output[6:0] HEX1,
	output[6:0] HEX2,
	output[6:0] HEX3,
	output[6:0] HEX4,
	output[6:0] HEX5
);

	// Synchronous falling edge detector for KEY3
	reg KEY3_d;
	wire rst;
	
	always @(posedge CLOCK_50) begin
		KEY3_d <= KEY[3];
	end
	
	assign rst = KEY3_d & ~KEY[3];
	
	// Synthetic 1S Clock
	reg[31:0] MHz_counter;
	reg CLOCK_1S;
	
	always @(posedge CLOCK_50) begin
		if (rst) begin
			MHz_counter = 0;
			CLOCK_1S = 0;
		end
	
		MHz_counter = MHz_counter + 1;
		
		if (MHz_counter == 25000000 - 1) begin
			CLOCK_1S <= ~CLOCK_1S;
			MHz_counter <= 0;
		end 
	end
		
	// controller setup
	wire r0, r1, r2;
	
	controller controller_inst(
		.clk(CLOCK_1S),
		.rst(rst),
		.start(),
		.pmem_in(),
		.pmem_write(),
		.r0_out(r0),
		.r1_out(r1),
		.r2_out(r2)
	);
	
	// display registers
	hex16_to_7seg r0_display(
		.data(r0),
		.HEX0(HEX0),
		.HEX1(HEX1)
	);
	
	hex16_to_7seg r1_display(
		.data(r1),
		.HEX0(HEX2),
		.HEX1(HEX3)
	);
	
	hex16_to_7seg r2_display(
		.data(5),
		.HEX0(HEX4),
		.HEX1(HEX5)
	);

endmodule