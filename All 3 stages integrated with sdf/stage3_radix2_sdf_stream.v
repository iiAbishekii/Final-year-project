module stage3_radix2_sdf_stream (
 input wire clk,
 input wire valid_in,
 input wire signed [15:0] xin_re,
 input wire signed [15:0] xin_im,
 output reg signed [15:0] xout_re,
 output reg signed [15:0] xout_im,
 output reg valid_out
);
 localparam signed [15:0] C = 16'sd23170;
 reg signed [15:0] d_re [0:3];
 reg signed [15:0] d_im [0:3];
 reg signed [15:0] sum_re [0:3];
 reg signed [15:0] sum_im [0:3];
 reg [3:0] cnt;
 reg phase; // 0 = SUM CAPTURE, 1 = DIFF OUTPUT
 reg signed [31:0] mul1, mul2;
 integer i;
 initial begin
 cnt = 0;
 phase = 0;
 valid_out = 0;
 for (i=0;i<4;i=i+1) begin
 d_re[i] = 0; d_im[i] = 0;
 sum_re[i] = 0; sum_im[i] = 0;
 end
 end
 always @(posedge clk) begin
 valid_out <= 0;
 // -------- SUM PHASE (streaming capture) --------
 if (!phase) begin
 if (valid_in) begin
 if (cnt[0] == 0) begin
 d_re[cnt>>1] <= xin_re;
 d_im[cnt>>1] <= xin_im;
 end else begin
 sum_re[cnt>>1] <= d_re[cnt>>1] + xin_re;
 sum_im[cnt>>1] <= d_im[cnt>>1] + xin_im;
 d_re[cnt>>1] <= d_re[cnt>>1] - xin_re;
 d_im[cnt>>1] <= d_im[cnt>>1] - xin_im;
 end
 cnt <= cnt + 1;
 if (cnt == 7) begin
 cnt <= 0;
 phase <= 1;
 end
 end
 end
 // -------- OUTPUT SUMS THEN DIFFS --------
 else begin
 case (cnt)
 // SUM outputs
 0,1,2,3: begin
 xout_re <= sum_re[cnt];
 xout_im <= sum_im[cnt];
 valid_out <= 1;
 end
 // DIFF outputs
 4: begin xout_re <= d_re[0]; xout_im <= d_im[0]; valid_out <= 1; end
 5: begin
 mul1 = C * (d_re[1] + d_im[1]);
 mul2 = C * (d_im[1] - d_re[1]);
 xout_re <= mul1 >>> 15;
 xout_im <= mul2 >>> 15;
 valid_out <= 1;
 end
 6: begin xout_re <= d_im[2]; xout_im <= -d_re[2]; valid_out <= 1; end
 7: begin
 mul1 = -C * (d_re[3] - d_im[3]);
 mul2 = -C * (d_re[3] + d_im[3]);
 xout_re <= mul1 >>> 15;
 xout_im <= mul2 >>> 15;
 valid_out <= 1;
 end
 endcase
 cnt <= cnt + 1;
 if (cnt == 7) begin
 cnt <= 0;
 phase <= 0;
 end
 end
 end
endmodule