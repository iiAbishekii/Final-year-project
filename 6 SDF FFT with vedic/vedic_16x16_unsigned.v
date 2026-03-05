module vedic_16x16_unsigned (
    input wire [15:0] a,
    input wire [15:0] b,
    output wire [31:0] p
);

wire [15:0] p0, p1, p2, p3;

vedic_8x8 u0 (a[7:0],  b[7:0],  p0);
vedic_8x8 u1 (a[15:8], b[7:0],  p1);
vedic_8x8 u2 (a[7:0],  b[15:8], p2);
vedic_8x8 u3 (a[15:8], b[15:8], p3);

assign p = p0 +
           (p1 << 8) +
           (p2 << 8) +
           (p3 << 16);

endmodule