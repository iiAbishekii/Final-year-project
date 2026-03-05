module vedic_8x8 (
    input wire [7:0] a,
    input wire [7:0] b,
    output wire [15:0] p
);

wire [7:0] p0, p1, p2, p3;
wire [15:0] s1, s2;

vedic_4x4 u0 (a[3:0], b[3:0], p0);
vedic_4x4 u1 (a[7:4], b[3:0], p1);
vedic_4x4 u2 (a[3:0], b[7:4], p2);
vedic_4x4 u3 (a[7:4], b[7:4], p3);

assign s1 = (p1 << 4) + (p2 << 4);
assign s2 = s1 + (p3 << 8);
assign p  = p0 + s2;

endmodule