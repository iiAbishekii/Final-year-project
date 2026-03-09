`timescale 1ns/1ps
module stage3_radix2_block_sdf (
 input wire clk,
 input wire valid_in,
 input wire signed [15:0] xin_re,
 input wire signed [15:0] xin_im,
 output reg signed [15:0] xout_re,
 output reg signed [15:0] xout_im,
 output reg valid_out
);
 localparam signed [15:0] C = 16'sd23170; // 0.707 in Q1.15
 reg signed [15:0] s_re [0:7];
 reg signed [15:0] s_im [0:7];
 reg [2:0] in_cnt, out_cnt;
 reg phase;
 reg signed [31:0] mul1, mul2;
 integer i;
 initial begin
 in_cnt = 0;
 out_cnt = 0;
 phase = 0;
 valid_out = 0;
 for (i=0;i<8;i=i+1) begin
 s_re[i] = 0;
 s_im[i] = 0;
 end
 end
 always @(posedge clk) begin
 valid_out <= 0;
 // ---------------- Input-loading timeline ----------------
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
 // ---------------- Processing timeline ----------------
 else begin
 case (out_cnt)
 0: begin xout_re <= s_re[0] + s_re[1];
 xout_im <= s_im[0] + s_im[1]; end
 1: begin xout_re <= s_re[0] - s_re[1];
 xout_im <= s_im[0] - s_im[1]; end
 2: begin xout_re <= s_re[2] + s_re[3];
 xout_im <= s_im[2] + s_im[3]; end
 3: begin
 mul1 = C * ((s_re[2]-s_re[3]) + (s_im[2]-s_im[3]));
 mul2 = C * ((s_im[2]-s_im[3]) - (s_re[2]-s_re[3]));
 xout_re <= mul1 >>> 15;
 xout_im <= mul2 >>> 15;
 end
 4: begin xout_re <= s_re[4] + s_re[5];
 xout_im <= s_im[4] + s_im[5]; end
 5: begin xout_re <= (s_im[4] - s_im[5]);
 xout_im <= -(s_re[4] - s_re[5]); end
 6: begin xout_re <= s_re[6] + s_re[7];
 xout_im <= s_im[6] + s_im[7]; end
 7: begin
 mul1 = -C * ((s_re[6]-s_re[7]) - (s_im[6]-s_im[7]));
 mul2 = -C * ((s_re[6]-s_re[7]) + (s_im[6]-s_im[7]));
 xout_re <= mul1 >>> 15;
 xout_im <= mul2 >>> 15;
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
