module fft8_dif_sdf (
input wire clk,
input wire valid_in,
input wire signed [15:0] xin_re,
input wire signed [15:0] xin_im,
output reg signed [15:0] xout_re,
output reg signed [15:0] xout_im,
output reg valid_out
);
// ============================================================
// STAGE 1 REGISTERS
// ============================================================
reg signed [15:0] s1_d_re [0:3];
reg signed [15:0] s1_d_im [0:3];
reg [2:0] s1_cnt;
reg s1_phase;
reg signed [15:0] s1_re, s1_im;
reg s1_valid;
// ============================================================
// STAGE 1 ? STAGE 2 PIPE REG
// ============================================================
reg signed [15:0] s1r_re, s1r_im;
reg s1r_valid;
// ============================================================
// STAGE 2 REGISTERS
// ============================================================
reg signed [15:0] s2_d_re [0:1];
reg signed [15:0] s2_d_im [0:1];
reg [3:0] s2_cnt;
reg signed [15:0] s2_re, s2_im;
reg s2_valid;
// ============================================================
// STAGE 2 ? STAGE 3 PIPE REG
// ============================================================
reg signed [15:0] s2r_re, s2r_im;
reg s2r_valid;
// ============================================================
// STAGE 3 REGISTERS
// ============================================================
localparam signed [15:0] C = 16'sd23170;
reg signed [15:0] s3_d_re [0:3];
reg signed [15:0] s3_d_im [0:3];
reg signed [15:0] s3_sum_re [0:3];
reg signed [15:0] s3_sum_im [0:3];
reg [3:0] s3_cnt;
reg s3_phase;
reg signed [31:0] mul1, mul2;
integer i;
// ============================================================
// INITIALIZATION
// ============================================================
initial begin
s1_cnt = 0; s1_phase = 0; s1_valid = 0;
s2_cnt = 0; s2_valid = 0;
s3_cnt = 0; s3_phase = 0;
valid_out = 0;
for (i=0;i<4;i=i+1) begin
s1_d_re[i]=0; s1_d_im[i]=0;
s3_d_re[i]=0; s3_d_im[i]=0;
s3_sum_re[i]=0; s3_sum_im[i]=0;
end
for (i=0;i<2;i=i+1) begin
s2_d_re[i]=0; s2_d_im[i]=0;
end
end
// ============================================================
// STAGE 1 : RADIX-2 DIF SDF
// ============================================================
always @(posedge clk) begin
s1_valid <= 0;
if (!s1_phase) begin
if (valid_in) begin
if (s1_cnt < 4) begin
s1_d_re[s1_cnt] <= xin_re;
s1_d_im[s1_cnt] <= xin_im;
end else begin
s1_re <= s1_d_re[s1_cnt-4] + xin_re;
s1_im <= s1_d_im[s1_cnt-4] + xin_im;
s1_d_re[s1_cnt-4] <= s1_d_re[s1_cnt-4] - xin_re;
s1_d_im[s1_cnt-4] <= s1_d_im[s1_cnt-4] - xin_im;
s1_valid <= 1;
end
s1_cnt <= s1_cnt + 1;
if (s1_cnt == 7) begin
s1_cnt <= 0;
s1_phase <= 1;
end
end
end else begin
s1_re <= s1_d_re[s1_cnt];
s1_im <= s1_d_im[s1_cnt];
s1_valid <= 1;
s1_cnt <= s1_cnt + 1;
if (s1_cnt == 3) begin
s1_cnt <= 0;
s1_phase <= 0;
end
end
end
// ============================================================
// PIPE REG : STAGE 1 ? STAGE 2
// ============================================================
always @(posedge clk) begin
s1r_valid <= s1_valid;
if (s1_valid) begin
s1r_re <= s1_re;
s1r_im <= s1_im;
end
end
// ============================================================
// STAGE 2 : RADIX-2 STREAMING
// ============================================================
always @(posedge clk) begin
s2_valid <= 0;
case (s2_cnt)
0,1: if (s1r_valid) begin
s2_d_re[s2_cnt] <= s1r_re;
s2_d_im[s2_cnt] <= s1r_im;
s2_cnt <= s2_cnt + 1;
end
2,3: begin
s2_re <= s2_d_re[s2_cnt-2] + s1r_re;
s2_im <= s2_d_im[s2_cnt-2] + s1r_im;
s2_d_re[s2_cnt-2] <= s2_d_re[s2_cnt-2] - s1r_re;
s2_d_im[s2_cnt-2] <= s2_d_im[s2_cnt-2] - s1r_im;
s2_valid <= 1;
s2_cnt <= s2_cnt + 1;
end
4: begin
s2_re <= s2_d_re[0];
s2_im <= s2_d_im[0];
s2_valid <= 1;
if (s1r_valid) begin
s2_d_re[0] <= s1r_re;
s2_d_im[0] <= s1r_im;
end
s2_cnt <= 5;
end
5: begin
s2_re <= s2_d_im[1];
s2_im <= -s2_d_re[1];
s2_valid <= 1;
if (s1r_valid) begin
s2_d_re[1] <= s1r_re;
s2_d_im[1] <= s1r_im;
end
s2_cnt <= 6;
end
6,7: begin
s2_re <= s2_d_re[s2_cnt-6] + s1r_re;
s2_im <= s2_d_im[s2_cnt-6] + s1r_im;
s2_d_re[s2_cnt-6] <= s2_d_re[s2_cnt-6] - s1r_re;
s2_d_im[s2_cnt-6] <= s2_d_im[s2_cnt-6] - s1r_im;
s2_valid <= 1;
s2_cnt <= s2_cnt + 1;
end
8: begin
s2_re <= s2_d_re[0];
s2_im <= s2_d_im[0];
s2_valid <= 1;
s2_cnt <= 9;
end
9: begin
s2_re <= s2_d_im[1];
s2_im <= -s2_d_re[1];
s2_valid <= 1;
s2_cnt <= 0;
end
endcase
end
// ============================================================
// PIPE REG : STAGE 2 ? STAGE 3
// ============================================================
always @(posedge clk) begin
s2r_valid <= s2_valid;
if (s2_valid) begin
s2r_re <= s2_re;
s2r_im <= s2_im;
end
end
// ============================================================
// STAGE 3 : RADIX-2 DIF WITH TWIDDLES
// ============================================================
always @(posedge clk) begin
valid_out <= 0;
if (!s3_phase) begin
if (s2r_valid) begin
if (!s3_cnt[0]) begin
s3_d_re[s3_cnt>>1] <= s2r_re;
s3_d_im[s3_cnt>>1] <= s2r_im;
end else begin
s3_sum_re[s3_cnt>>1] <= s3_d_re[s3_cnt>>1] + s2r_re;
s3_sum_im[s3_cnt>>1] <= s3_d_im[s3_cnt>>1] + s2r_im;
s3_d_re[s3_cnt>>1] <= s3_d_re[s3_cnt>>1] - s2r_re;
s3_d_im[s3_cnt>>1] <= s3_d_im[s3_cnt>>1] - s2r_im;
end
s3_cnt <= s3_cnt + 1;
if (s3_cnt == 7) begin
s3_cnt <= 0;
s3_phase <= 1;
end
end
end else begin
case (s3_cnt)
0,1,2,3: begin
xout_re <= s3_sum_re[s3_cnt];
xout_im <= s3_sum_im[s3_cnt];
valid_out <= 1;
end
4: begin
xout_re <= s3_d_re[0];
xout_im <= s3_d_im[0];
valid_out <= 1;
end
5: begin
mul1 = C * (s3_d_re[1] + s3_d_im[1]);
mul2 = C * (s3_d_im[1] - s3_d_re[1]);
xout_re <= mul1 >>> 15;
xout_im <= mul2 >>> 15;
valid_out <= 1;
end
6: begin
xout_re <= s3_d_im[2];
xout_im <= -s3_d_re[2];
valid_out <= 1;
end
7: begin
mul1 = -C * (s3_d_re[3] - s3_d_im[3]);
mul2 = -C * (s3_d_re[3] + s3_d_im[3]);
xout_re <= mul1 >>> 15;
xout_im <= mul2 >>> 15;
valid_out <= 1;
end
endcase
s3_cnt <= s3_cnt + 1;
if (s3_cnt == 7) begin
s3_cnt <= 0;
s3_phase <= 0;
end
end
end
endmodule
