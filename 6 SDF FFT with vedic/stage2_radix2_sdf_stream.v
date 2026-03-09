module stage2_radix2_sdf_stream (
 input wire clk,
 input wire valid_in,
 input wire signed [15:0] xin_re,
 input wire signed [15:0] xin_im,
 output reg signed [15:0] xout_re,
 output reg signed [15:0] xout_im,
 output reg valid_out
);
 // Delay = 2
 reg signed [15:0] delay_re [0:1];
 reg signed [15:0] delay_im [0:1];
 // Stored DIFFs (after twiddle)
 reg signed [15:0] diff_re [0:1];
 reg signed [15:0] diff_im [0:1];
 // Modulo-4 counter (unchanged)
 reg [1:0] cnt;
 wire store_phase = (cnt < 2);
 wire sum_phase = (cnt >= 2);
 wire [0:0] addr = cnt[0]; // modulo-2
 // temp variables
 reg signed [15:0] a_re, a_im;
 reg signed [15:0] b_re, b_im;
 reg signed [15:0] d_re, d_im;
 integer i;
 initial begin
 cnt = 0;
 valid_out = 0;
 for (i = 0; i < 2; i = i + 1) begin
 delay_re[i] = 0;
 delay_im[i] = 0;
 diff_re[i] = 0;
 diff_im[i] = 0;
 end
 end
 always @(posedge clk) begin
 valid_out <= 0;
 if (valid_in) begin
 // ---------------- STORE ----------------
 if (store_phase) begin
 delay_re[addr] <= xin_re;
 delay_im[addr] <= xin_im;
  end
 // ---------------- SUM ----------------
 if (sum_phase) begin
 a_re = delay_re[addr];
 a_im = delay_im[addr];
 b_re = xin_re;
 b_im = xin_im;
 // SUM
 xout_re <= a_re + b_re;
 xout_im <= a_im + b_im;
 valid_out <= 1;
 // raw DIFF
 d_re = a_re - b_re;
 d_im = a_im - b_im;
 // apply twiddle
 if (addr == 1'b1) begin
 // multiply by -j
 diff_re[addr] <= d_im;
 diff_im[addr] <= -d_re;
 end else begin
 diff_re[addr] <= d_re;
 diff_im[addr] <= d_im;
 end
  end
 // ---------------- DIFF OUTPUT ----------------
 if (!sum_phase) begin
 xout_re <= diff_re[addr];
 xout_im <= diff_im[addr];
 valid_out <= 1;
  end
 cnt <= cnt + 1;
 end
 end
endmodule