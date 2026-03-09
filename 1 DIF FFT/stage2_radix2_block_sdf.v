`timescale 1ns/1ps
module stage2_radix2_block_sdf (
 input wire clk,
 input wire valid_in,
 input wire signed [15:0] xin_re,
 input wire signed [15:0] xin_im,
 output reg signed [15:0] xout_re,
 output reg signed [15:0] xout_im,
 output reg valid_out
);
 reg signed [15:0] s_re [0:7];
 reg signed [15:0] s_im [0:7];
 reg [2:0] in_cnt, out_cnt;
 reg phase;
 integer i;
 initial begin
 in_cnt = 0;
 out_cnt = 0;
 phase = 0;
 valid_out = 0;
 for (i=0; i<8; i=i+1) begin
 s_re[i] = 0;
 s_im[i] = 0;
 end
 end
 always @(posedge clk) begin
 valid_out <= 0;
 // ---------------- INPUT PHASE ----------------
 if (!phase) begin
 if (valid_in) begin
 s_re[in_cnt] <= xin_re;
 s_im[in_cnt] <= xin_im;
 if (in_cnt == 7) begin
 phase <= 1;
 out_cnt <= 0;
 end else begin
 in_cnt <= in_cnt + 1;
 end
 end
 end
 // ---------------- OUTPUT PHASE ----------------
 else begin
 case (out_cnt)
 // ---- sums first (canonical DIF order) ----
 // sum(0,2)
 0: begin
 xout_re <= s_re[0] + s_re[2];
 xout_im <= s_im[0] + s_im[2];
 end
 // sum(1,3)
 1: begin
 xout_re <= s_re[1] + s_re[3];
 xout_im <= s_im[1] + s_im[3];
 end
 // diff(0,2) * W=1
 2: begin
 xout_re <= s_re[0] - s_re[2];
 xout_im <= s_im[0] - s_im[2];
 end
 // diff(1,3) * W=-j ? (a-b)*W
 3: begin
 xout_re <= (s_im[1] - s_im[3]);
 xout_im <= -(s_re[1] - s_re[3]);
 end
 // sum(4,6)
 4: begin
 xout_re <= s_re[4] + s_re[6];
 xout_im <= s_im[4] + s_im[6];
 end
 // sum(5,7)
 5: begin
 xout_re <= s_re[5] + s_re[7];
 xout_im <= s_im[5] + s_im[7];
 end
 // diff(4,6) * W=1
 6: begin
 xout_re <= s_re[4] - s_re[6];
 xout_im <= s_im[4] - s_im[6];
 end
 // diff(5,7) * W=-j
 7: begin
 xout_re <= (s_im[5] - s_im[7]);
 xout_im <= -(s_re[5] - s_re[7]);
 end
 endcase
 valid_out <= 1;
 if (out_cnt == 7) begin
 phase <= 0;
 in_cnt <= 0;
 end else begin
 out_cnt <= out_cnt + 1;
 end
 end
 end
endmodule