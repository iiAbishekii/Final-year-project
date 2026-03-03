module stage1_radix2_sdf (
 input wire clk,
 input wire valid_in,
 input wire signed [15:0] xin_re,
 input wire signed [15:0] xin_im,
 output reg signed [15:0] xout_re,
 output reg signed [15:0] xout_im,
 output reg valid_out
);
 reg signed [15:0] d_re [0:3];
 reg signed [15:0] d_im [0:3];
 reg [2:0] cnt;
 reg phase;
 integer i;
 initial begin
 cnt = 0;
 phase = 0;
 valid_out = 0;
 for (i=0;i<4;i=i+1) begin
 d_re[i] = 0;
 d_im[i] = 0;
 end
 end
 always @(posedge clk) begin
 valid_out <= 0;
 if (!phase) begin
 if (valid_in) begin
 if (cnt < 4) begin
 d_re[cnt] <= xin_re;
 d_im[cnt] <= xin_im;
 end else begin
 xout_re <= d_re[cnt-4] + xin_re;
 xout_im <= d_im[cnt-4] + xin_im;
 d_re[cnt-4] <= d_re[cnt-4] - xin_re;
 d_im[cnt-4] <= d_im[cnt-4] - xin_im;
 valid_out <= 1;
 end
 cnt <= cnt + 1;
 if (cnt == 7) begin
 cnt <= 0;
 phase <= 1;
 end
 end
 end else begin
 xout_re <= d_re[cnt];
 xout_im <= d_im[cnt];
 valid_out <= 1;
 cnt <= cnt + 1;
 if (cnt == 3) begin
 cnt <= 0;
 phase <= 0;
 end
 end
 end
endmodule
