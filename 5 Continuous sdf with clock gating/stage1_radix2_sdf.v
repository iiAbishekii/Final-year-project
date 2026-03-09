module stage1_radix2_sdf (
 input wire clk,
 input wire valid_in,
 input wire signed [15:0] xin_re,
 input wire signed [15:0] xin_im,
 output reg signed [15:0] xout_re,
 output reg signed [15:0] xout_im,
 output reg valid_out
);

 // Delay = 4
 reg signed [15:0] delay_re [0:3];
 reg signed [15:0] delay_im [0:3];

 // Stored DIFFs
 reg signed [15:0] diff_re [0:3];
 reg signed [15:0] diff_im [0:3];

 // Modulo-8 counter
 reg [2:0] cnt;

 wire store_phase = (cnt < 4);
 wire sum_phase   = (cnt >= 4);
 wire [1:0] addr  = cnt[1:0];

 integer i;

 initial begin
  cnt = 0;
  valid_out = 0;
  for (i = 0; i < 4; i = i + 1) begin
   delay_re[i] = 0;
   delay_im[i] = 0;
   diff_re[i]  = 0;
   diff_im[i]  = 0;
  end
 end

 // ---------------- CLOCK ENABLE STYLE GATING ----------------
 // All heavy logic toggles ONLY when valid_in = 1
 always @(posedge clk) begin

  // default (same as original)
  valid_out <= 0;

  if (valid_in) begin

   // STORE
   if (store_phase) begin
    delay_re[addr] <= xin_re;
    delay_im[addr] <= xin_im;
   end

   // SUM
   if (sum_phase) begin
    xout_re <= delay_re[addr] + xin_re;
    xout_im <= delay_im[addr] + xin_im;
    valid_out <= 1;

    diff_re[addr] <= delay_re[addr] - xin_re;
    diff_im[addr] <= delay_im[addr] - xin_im;
   end

   // DIFF OUTPUT
   if (!sum_phase && cnt >= 0) begin
    xout_re <= diff_re[addr];
    xout_im <= diff_im[addr];
    valid_out <= 1;
   end

   cnt <= cnt + 1;
  end

 end

endmodule