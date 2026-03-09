module stage2_radix2_sdf_stream (
 input wire clk,
 input wire valid_in,
 input wire signed [15:0] xin_re,
 input wire signed [15:0] xin_im,
 output reg signed [15:0] xout_re,
 output reg signed [15:0] xout_im,
 output reg valid_out
);

 reg signed [15:0] delay_re [0:1];
 reg signed [15:0] delay_im [0:1];

 reg signed [15:0] diff_re [0:1];
 reg signed [15:0] diff_im [0:1];

 reg [1:0] cnt;

 wire store_phase = (cnt < 2);
 wire sum_phase   = (cnt >= 2);
 wire addr        = cnt[0];

 integer i;

 initial begin
  cnt = 0;
  valid_out = 0;
  for (i = 0; i < 2; i = i + 1) begin
   delay_re[i] = 0;
   delay_im[i] = 0;
   diff_re[i]  = 0;
   diff_im[i]  = 0;
  end
 end

 always @(posedge clk) begin

  valid_out <= 0;

  if (valid_in) begin

   // STORE
   if (store_phase) begin
    delay_re[addr] <= xin_re;
    delay_im[addr] <= xin_im;
   end

   // SUM (unchanged)
   if (sum_phase) begin
    xout_re <= delay_re[addr] + xin_re;
    xout_im <= delay_im[addr] + xin_im;
    valid_out <= 1;

    diff_re[addr] <= delay_re[addr] - xin_re;
    diff_im[addr] <= delay_im[addr] - xin_im;
   end

   // ---------------- DIFF OUTPUT WITH TWIDDLE ----------------
   if (!sum_phase) begin
    valid_out <= 1;

    if (addr == 1) begin
     // multiply by -j : (a+jb) -> (b - ja)
     xout_re <=  diff_im[addr];
     xout_im <= -diff_re[addr];
    end
    else begin
     xout_re <= diff_re[addr];
     xout_im <= diff_im[addr];
    end
   end

   cnt <= cnt + 1;
  end

 end

endmodule