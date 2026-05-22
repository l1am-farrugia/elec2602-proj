module hex16_to_7seg (
    input  [15:0] data,
    output [6:0] HEX0,
    output [6:0] HEX1
);

    hex_to_7seg h0 (
        .hex(data[3:0]),
        .seg(HEX0)
    );

    hex_to_7seg h1 (
        .hex(data[7:4]),
        .seg(HEX1)
    );

endmodule