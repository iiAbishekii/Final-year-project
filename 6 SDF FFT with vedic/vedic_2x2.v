module vedic_2x2 (
    input wire [1:0] a,
    input wire [1:0] b,
    output wire [3:0] p
);

assign p[0] = a[0] & b[0];
assign p[1] = (a[1] & b[0]) ^ (a[0] & b[1]);
assign p[2] = (a[1] & b[1]) ^ ((a[1] & b[0]) & (a[0] & b[1]));
assign p[3] = (a[1] & b[1]) & ((a[1] & b[0]) & (a[0] & b[1]));

endmodule