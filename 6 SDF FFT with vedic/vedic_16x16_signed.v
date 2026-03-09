module vedic_16x16_signed (
    input wire signed [15:0] a,
    input wire signed [15:0] b,
    output wire signed [31:0] p
);

wire sign;
wire [15:0] a_mag;
wire [15:0] b_mag;
wire [31:0] p_mag;

assign sign  = a[15] ^ b[15];
assign a_mag = a[15] ? (~a + 1'b1) : a;
assign b_mag = b[15] ? (~b + 1'b1) : b;

vedic_16x16_unsigned U0 (
    .a(a_mag),
    .b(b_mag),
    .p(p_mag)
);

assign p = sign ? (~p_mag + 1'b1) : p_mag;

endmodule