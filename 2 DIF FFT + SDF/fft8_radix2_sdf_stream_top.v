module fft8_radix2_sdf_stream_top (
 input wire clk,
 input wire valid_in,
 input wire signed [15:0] xin_re,
 input wire signed [15:0] xin_im,
 output wire signed [15:0] xout_re,
 output wire signed [15:0] xout_im,
 output wire valid_out
);
 // ---------------- Stage-1 outputs ----------------
 wire signed [15:0] s1_re, s1_im;
 wire s1_valid;
 // ---------------- Stage-2 outputs ----------------
 wire signed [15:0] s2_re, s2_im;
 wire s2_valid;
 // ---------------- Register boundaries ----------------
 reg signed [15:0] s1r_re, s1r_im;
 reg s1r_valid;
 reg signed [15:0] s2r_re, s2r_im;
 reg s2r_valid;
 // =====================================================
 // Stage-1 SDF (original, frozen)
 // =====================================================
 stage1_radix2_sdf STAGE1 (
 .clk (clk),
 .valid_in (valid_in),
 .xin_re (xin_re),
 .xin_im (xin_im),
 .xout_re (s1_re),
 .xout_im (s1_im),
 .valid_out (s1_valid)
 );
 // -------- Register Stage-1 ? Stage-2 --------
 always @(posedge clk) begin
 if (s1_valid) begin
 s1r_re <= s1_re;
 s1r_im <= s1_im;
 s1r_valid <= 1'b1;
 end else begin
 s1r_valid <= 1'b0;
 end
 end
 // =====================================================
 // Stage-2 STREAM (gap-free, frozen)
 // =====================================================
 stage2_radix2_sdf_stream STAGE2 (
 .clk (clk),
 .valid_in (s1r_valid),
 .xin_re (s1r_re),
 .xin_im (s1r_im),
 .xout_re (s2_re),
 .xout_im (s2_im),
 .valid_out (s2_valid)
 );
 // -------- Register Stage-2 ? Stage-3 --------
 always @(posedge clk) begin
 if (s2_valid) begin
 s2r_re <= s2_re;
 s2r_im <= s2_im;
 s2r_valid <= 1'b1;
 end else begin
 s2r_valid <= 1'b0;
 end
 end
 // =====================================================
 // Stage-3 STREAM (gap-free, order-correct, frozen)
 // =====================================================
 stage3_radix2_sdf_stream STAGE3 (
 .clk (clk),
 .valid_in (s2r_valid),
 .xin_re (s2r_re),
 .xin_im (s2r_im),
 .xout_re (xout_re),
 .xout_im (xout_im),
 .valid_out (valid_out)
 );
endmodule
