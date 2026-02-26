`timescale 1ns/1ps
module stage1_radix2 (
 input wire clk,
 input wire signed [15:0] xin_re,
 input wire signed [15:0] xin_im,
 output reg signed [15:0] xout_re,
 output reg signed [15:0] xout_im,
 output reg valid
);
 reg signed [15:0] buf_re [0:7];
 reg signed [15:0] buf_im [0:7];
 reg [2:0] in_cnt;
 reg [2:0] out_cnt;
 reg phase; // 0 = input, 1 = output
 integer i;
 initial begin
 in_cnt = 0;
 out_cnt = 0;
 phase = 0;
 valid = 0;
 xout_re = 0;
 xout_im = 0;
 for (i=0;i<8;i=i+1) begin
 buf_re[i] = 0;
 buf_im[i] = 0;
 end
 end
 always @(posedge clk) begin
 valid <= 0;
 // ---------------- INPUT PHASE ----------------
 if (phase == 0) begin
 // DEBUG: show exactly what is loaded
 $display("CLK %0t | LOAD cnt=%0d xin_re=%0d",
 $time, in_cnt, xin_re);
 buf_re[in_cnt] <= xin_re;
 buf_im[in_cnt] <= xin_im;
 if (in_cnt == 7) begin
 phase <= 1;
 out_cnt <= 0;
 end else begin
 in_cnt <= in_cnt + 1;
 end
 end
 // ---------------- OUTPUT PHASE ----------------
 else begin
 case (out_cnt)
 0: begin xout_re <= buf_re[0] + buf_re[4];
 xout_im <= buf_im[0] + buf_im[4]; end
 1: begin xout_re <= buf_re[1] + buf_re[5];
 xout_im <= buf_im[1] + buf_im[5]; end
 2: begin xout_re <= buf_re[2] + buf_re[6];
 xout_im <= buf_im[2] + buf_im[6]; end
 3: begin xout_re <= buf_re[3] + buf_re[7];
 xout_im <= buf_im[3] + buf_im[7]; end
 4: begin xout_re <= buf_re[0] - buf_re[4];
 xout_im <= buf_im[0] - buf_im[4]; end
 5: begin xout_re <= buf_re[1] - buf_re[5];
 xout_im <= buf_im[1] - buf_im[5]; end
 6: begin xout_re <= buf_re[2] - buf_re[6];
 xout_im <= buf_im[2] - buf_im[6]; end
 7: begin xout_re <= buf_re[3] - buf_re[7];
 xout_im <= buf_im[3] - buf_im[7]; end
 endcase
 // DEBUG: show output
 $display("CLK %0t | OUT cnt=%0d xout_re=%0d",
 $time, out_cnt, xout_re);
 valid <= 1;
 if (out_cnt == 7) begin
 phase <= 0;
 in_cnt <= 0;
 end else begin
 out_cnt <= out_cnt + 1;
 end
 end
 end
endmodule
