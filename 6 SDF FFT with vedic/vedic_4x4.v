module vedic_4x4 (
    input wire [3:0] a,
    input wire [3:0] b,
    output wire [7:0] p
);

wire [3:0] p0, p1, p2, p3;
wire [7:0] s1, s2;

vedic_2x2 u0 (a[1:0], b[1:0], p0);
vedic_2x2 u1 (a[3:2], b[1:0], p1);
vedic_2x2 u2 (a[1:0], b[3:2], p2);
vedic_2x2 u3 (a[3:2], b[3:2], p3);

assign s1 = (p1 << 2) + (p2 << 2);
assign s2 = s1 + (p3 << 4);
assign p  = p0 + s2;

endmodule