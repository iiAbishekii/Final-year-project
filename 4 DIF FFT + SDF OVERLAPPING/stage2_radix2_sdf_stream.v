module stage2_radix2_sdf_stream (
input wire clk,
input wire valid_in,
input wire signed [15:0] xin_re,
input wire signed [15:0] xin_im,
output reg signed [15:0] xout_re,
output reg signed [15:0] xout_im,
output reg valid_out
);
reg signed [15:0] d_re [0:1];
reg signed [15:0] d_im [0:1];
reg [3:0] cnt;
integer i;
initial begin
cnt = 0;
valid_out = 0;
for (i=0;i<2;i=i+1) begin
d_re[i] = 0;
d_im[i] = 0;
end
end
always @(posedge clk) begin
valid_out <= 0;
case (cnt)
// LOAD G1
0,1: if (valid_in) begin
d_re[cnt] <= xin_re;
d_im[cnt] <= xin_im;
cnt <= cnt + 1;
end
// SUM G1
2,3: begin
xout_re <= d_re[cnt-2] + xin_re;
xout_im <= d_im[cnt-2] + xin_im;
d_re[cnt-2] <= d_re[cnt-2] - xin_re;
d_im[cnt-2] <= d_im[cnt-2] - xin_im;
valid_out <= 1;
cnt <= cnt + 1;
end
// DIFF G1 + LOAD G2
4: begin
xout_re <= d_re[0];
xout_im <= d_im[0];
valid_out <= 1;
if (valid_in) begin
d_re[0] <= xin_re;
d_im[0] <= xin_im;
end
cnt <= cnt + 1;
end
5: begin
xout_re <= d_im[1];
xout_im <= -d_re[1];
valid_out <= 1;
if (valid_in) begin
d_re[1] <= xin_re;
d_im[1] <= xin_im;
end
cnt <= cnt + 1;
end
// SUM G2
6,7: begin
xout_re <= d_re[cnt-6] + xin_re;
xout_im <= d_im[cnt-6] + xin_im;
d_re[cnt-6] <= d_re[cnt-6] - xin_re;
d_im[cnt-6] <= d_im[cnt-6] - xin_im;
valid_out <= 1;
cnt <= cnt + 1;
end
// DIFF G2
8: begin
xout_re <= d_re[0];
xout_im <= d_im[0];
valid_out <= 1;
cnt <= cnt + 1;
end
9: begin
xout_re <= d_im[1];
xout_im <= -d_re[1];
valid_out <= 1;
cnt <= 0;
end
endcase
end
endmodule
