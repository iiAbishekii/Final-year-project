// ============================================================
// Module  : fft8_sdf_csd_top
// Desc    : 8-point Radix-2 SDF DIF FFT — SDF + CSD only
//           (Bit inversion REMOVED — overhead > savings)
//
// Power targets (Cadence Genus 45nm):
//   Baseline parallel FFT : 2.317 mW
//   SDF only              : 1.511 mW  (-35%)
//   SDF + CSD (this file) : ~1.15 mW  (-24% from SDF)
//
// Files needed:
//   fft8_sdf_csd_top.v         <- this file
//   stage1_sdf_csd.v
//   stage2_sdf_csd.v
//   stage3_sdf_csd.v
// ============================================================
module fft8_sdf_csd_top (
    input  wire        clk,
    input  wire        valid_in,
    input  wire signed [15:0] xin_re,
    input  wire signed [15:0] xin_im,
    output wire signed [15:0] xout_re,
    output wire signed [15:0] xout_im,
    output wire               valid_out
);
    // Single input register — one cycle latency, no encoding overhead
    reg signed [15:0] r1_re, r1_im;
    reg               r1_valid;
    initial begin r1_re=0; r1_im=0; r1_valid=0; end

    always @(posedge clk) begin
        r1_valid <= valid_in;
        r1_re    <= xin_re;
        r1_im    <= xin_im;
    end

    // Stage 1 — delay-4 butterfly, W^0 = 1
    wire signed [15:0] s1_re, s1_im;
    wire               s1_valid;

    stage1_sdf_csd STAGE1 (
        .clk(clk), .valid_in(r1_valid),
        .xin_re(r1_re), .xin_im(r1_im),
        .xout_re(s1_re), .xout_im(s1_im),
        .valid_out(s1_valid)
    );

    // Single pipeline register Stage1 -> Stage2
    reg signed [15:0] s12_re, s12_im;
    reg               s12_valid;
    initial begin s12_re=0; s12_im=0; s12_valid=0; end

    always @(posedge clk) begin
        s12_valid <= s1_valid;
        s12_re    <= s1_re;
        s12_im    <= s1_im;
    end

    // Stage 2 — delay-2 butterfly, W^0=1 / W^2=-j
    wire signed [15:0] s2_re, s2_im;
    wire               s2_valid;

    stage2_sdf_csd STAGE2 (
        .clk(clk), .valid_in(s12_valid),
        .xin_re(s12_re), .xin_im(s12_im),
        .xout_re(s2_re), .xout_im(s2_im),
        .valid_out(s2_valid)
    );

    // Single pipeline register Stage2 -> Stage3
    reg signed [15:0] s23_re, s23_im;
    reg               s23_valid;
    initial begin s23_re=0; s23_im=0; s23_valid=0; end

    always @(posedge clk) begin
        s23_valid <= s2_valid;
        s23_re    <= s2_re;
        s23_im    <= s2_im;
    end

    // Stage 3 — delay-1 butterfly, CSD twiddles
    wire signed [15:0] s3_re, s3_im;
    wire               s3_valid;

    stage3_sdf_csd STAGE3 (
        .clk(clk), .valid_in(s23_valid),
        .xin_re(s23_re), .xin_im(s23_im),
        .xout_re(s3_re), .xout_im(s3_im),
        .valid_out(s3_valid)
    );

    assign xout_re   = s3_re;
    assign xout_im   = s3_im;
    assign valid_out = s3_valid;

endmodule