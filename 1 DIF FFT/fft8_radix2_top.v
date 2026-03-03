`timescale 1ns/1ps
module fft8_radix2_top (
 input wire clk,
 input wire signed [15:0] xin_re,
 input wire signed [15:0] xin_im,
 output wire signed [15:0] xout_re,
 output wire signed [15:0] xout_im,
 output wire valid
);
 // =========================================================
 // Stage-1 outputs
 // =========================================================
 wire signed [15:0] s1_re, s1_im;
 wire s1_valid;
 // =========================================================
 // Stage-2 outputs
 // =========================================================
 wire signed [15:0] s2_re, s2_im;
 wire s2_valid;
 // =========================================================
 // Registered boundaries (MANDATORY for correctness)
 // =========================================================
 reg signed [15:0] s1r_re, s1r_im;
 reg s1r_valid;
 reg signed [15:0] s2r_re, s2r_im;
 reg s2r_valid;
 // =========================================================
 // Stage-1 : Input loading + first DIF butterflies
 // =========================================================
 stage1_radix2 STAGE1 (
 .clk (clk),
 .xin_re (xin_re),
 .xin_im (xin_im),
 .xout_re (s1_re),
 .xout_im (s1_im),
 .valid (s1_valid)
 );
 // =========================================================
 // Register Stage-1 output
 // Capture ONLY when Stage-1 asserts valid
 // =========================================================
 always @(posedge clk) begin
 if (s1_valid) begin
 s1r_re <= s1_re;
 s1r_im <= s1_im;
 s1r_valid <= 1'b1;
 end else begin
 s1r_valid <= 1'b0;
 end
 end
 // =========================================================
 // Stage-2 : Second DIF stage (CORRECTED (a-b)W logic)
 // =========================================================
 stage2_radix2_block_sdf STAGE2 (
 .clk (clk),
 .valid_in (s1r_valid),
 .xin_re (s1r_re),
 .xin_im (s1r_im),
 .xout_re (s2_re),
 .xout_im (s2_im),
 .valid_out (s2_valid)
 );
 // =========================================================
 // Register Stage-2 output
 // Capture ONLY when Stage-2 asserts valid
 // =========================================================
 always @(posedge clk) begin
 if (s2_valid) begin
 s2r_re <= s2_re;
 s2r_im <= s2_im;
 s2r_valid <= 1'b1;
 end else begin
 s2r_valid <= 1'b0;
 end
 end
 // =========================================================
 // Stage-3 : Final DIF stage with 0.707 twiddles
 // =========================================================
 stage3_radix2_block_sdf STAGE3 (
 .clk (clk),
 .valid_in (s2r_valid),
 .xin_re (s2r_re),
 .xin_im (s2r_im),
 .xout_re (xout_re),
 .xout_im (xout_im),
 .valid_out (valid)
 );
endmodule
