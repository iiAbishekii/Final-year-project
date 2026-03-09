// ============================================================
// Module  : fft8_radix2_sdf_stream_top
// Project : Optimization of FFT Processor
//
// Description:
//   8-point Radix-2 SDF DIF FFT integrating two optimisations:
//     1. CSD twiddle multipliers (W^1, W^3) in Stage 3
//     2. Bus Invert Coding (BIC) on all three inter-stage buses
//
// ?????????????????????????????????????????????????????????????
// COMPLETE MODULE HIERARCHY
// ?????????????????????????????????????????????????????????????
//   fft8_radix2_sdf_stream_top
//   ??? [raw_reg]                       pipeline register (Bus1 stage A)
//   ??? ENC1_RE : bit_inv_encoder       Bus1 real  encoder
//   ??? ENC1_IM : bit_inv_encoder       Bus1 imag  encoder
//   ??? [bus1_reg]                      Bus1 register (Bus1 stage B)
//   ??? STAGE1  : stage1_radix2_sdf
//   ?   ??? DEC_RE : bit_inv_decoder
//   ?   ??? DEC_IM : bit_inv_decoder
//   ??? ENC2_RE : bit_inv_encoder       Bus2 real  encoder
//   ??? ENC2_IM : bit_inv_encoder       Bus2 imag  encoder
//   ??? [s12_reg]                       Bus2 register
//   ??? STAGE2  : stage2_radix2_sdf_stream
//   ?   ??? DEC_RE : bit_inv_decoder
//   ?   ??? DEC_IM : bit_inv_decoder
//   ??? ENC3_RE : bit_inv_encoder       Bus3 real  encoder
//   ??? ENC3_IM : bit_inv_encoder       Bus3 imag  encoder
//   ??? [s23_reg]                       Bus3 register
//   ??? STAGE3  : stage3_radix2_sdf_stream
//       ??? DEC_RE  : bit_inv_decoder
//       ??? DEC_IM  : bit_inv_decoder
//       ??? CSD_T1  : csd_sqrt2_inv
//       ??? CSD_T2A : csd_sqrt2_inv
//       ??? CSD_T2B : csd_sqrt2_inv
//       ??? CSD_T3  : csd_sqrt2_inv
//
// ?????????????????????????????????????????????????????????????
// BIC ENCODER INSTANTIATION - TWO-STAGE PIPELINE ON BUS 1
// ?????????????????????????????????????????????????????????????
// bit_inv_encoder is purely combinational. Its inputs must be
// stable BEFORE the always block fires at posedge, otherwise
// the block reads a stale combinational output (delta-cycle race).
//
// Bus1 uses a two-stage pipeline to achieve this:
//
//   Stage A (raw_reg): at posedge, latch xin_re/xin_im directly
//                      into raw_re/raw_im registers. No encoding.
//
//   Encoder instances ENC1_RE, ENC1_IM read from raw_re/raw_im
//   (stable registers) - their outputs enc1_re, enc1_im are valid
//   combinational wires, stable well before the next posedge.
//
//   Stage B (bus1_reg): at posedge, latch enc1_re/enc1_flag_re
//                       into r1_re/r1_flag_re registers ? STAGE1.
//
// Bus2 and Bus3 are simpler: stage1/stage2 outputs (s1_re, s2_re)
// are already NBA-settled registers. ENC2/ENC3 instances are driven
// by those stable registers, so their outputs are immediately valid
// combinational wires that bus1_reg/s23_reg can latch without a race.
//
// ?????????????????????????????????????????????????????????????
// COMPILE COMMAND
// ?????????????????????????????????????????????????????????????
//   iverilog -o sim \
//     fft8_radix2_sdf_stream_top.v \
//     stage1_radix2_sdf.v          \
//     stage2_radix2_sdf_stream.v   \
//     stage3_radix2_sdf_stream.v   \
//     bit_inv_encoder.v            \
//     bit_inv_decoder.v            \
//     csd_sqrt2_inv.v              \
//     tb_fft8_radix2_sdf_stream_top.v && vvp sim
// ============================================================
module fft8_radix2_sdf_stream_top (
    input  wire                  clk,
    input  wire                  valid_in,
    input  wire signed [15:0]    xin_re,
    input  wire signed [15:0]    xin_im,
    output wire signed [15:0]    xout_re,
    output wire signed [15:0]    xout_im,
    output wire                  valid_out
);

    // ==========================================================
    // BUS 1 - Two-stage pipeline: raw_reg ? ENC1 ? bus1_reg
    // ==========================================================

    // ?? Stage A: raw register (latch inputs directly, no encoding) ??
    reg signed [15:0] raw_re, raw_im;
    reg               raw_valid;

    initial begin raw_re=0; raw_im=0; raw_valid=0; end

    always @(posedge clk) begin : raw_reg
        raw_re    <= xin_re;
        raw_im    <= xin_im;
        raw_valid <= valid_in;
    end

    // ?? ENC1: encoder instances driven by stable raw registers ??
    wire signed [15:0] enc1_re,  enc1_im;
    wire               enc1_flag_re, enc1_flag_im;

    bit_inv_encoder ENC1_RE (.in(raw_re), .out(enc1_re),  .inv_flag(enc1_flag_re));
    bit_inv_encoder ENC1_IM (.in(raw_im), .out(enc1_im),  .inv_flag(enc1_flag_im));

    // ?? Stage B: bus1 register (latch encoder outputs) ??????????
    reg signed [15:0] r1_re,      r1_im;
    reg               r1_flag_re, r1_flag_im;
    reg               r1_valid;

    initial begin r1_re=0; r1_im=0; r1_flag_re=0; r1_flag_im=0; r1_valid=0; end

    always @(posedge clk) begin : bus1_reg
        r1_re      <= enc1_re;
        r1_im      <= enc1_im;
        r1_flag_re <= enc1_flag_re;
        r1_flag_im <= enc1_flag_im;
        r1_valid   <= raw_valid;
    end

    // ==========================================================
    // STAGE 1 - Delay-4 butterfly, W^0 = 1
    // ==========================================================
    wire signed [15:0] s1_re, s1_im;
    wire               s1_valid;

    stage1_radix2_sdf STAGE1 (
        .clk        (clk),
        .valid_in   (r1_valid),
        .xin_re     (r1_re),
        .xin_im     (r1_im),
        .inv_flag_re(r1_flag_re),
        .inv_flag_im(r1_flag_im),
        .xout_re    (s1_re),
        .xout_im    (s1_im),
        .valid_out  (s1_valid)
    );

    // ==========================================================
    // BUS 2 - ENC2 instances driven by stable s1 registers
    // ==========================================================
    wire signed [15:0] enc2_re,  enc2_im;
    wire               enc2_flag_re, enc2_flag_im;

    bit_inv_encoder ENC2_RE (.in(s1_re), .out(enc2_re),  .inv_flag(enc2_flag_re));
    bit_inv_encoder ENC2_IM (.in(s1_im), .out(enc2_im),  .inv_flag(enc2_flag_im));

    reg signed [15:0] s12_re,      s12_im;
    reg               s12_flag_re, s12_flag_im;
    reg               s12_valid;

    initial begin s12_re=0; s12_im=0; s12_flag_re=0; s12_flag_im=0; s12_valid=0; end

    always @(posedge clk) begin : s12_reg
        s12_re      <= enc2_re;
        s12_im      <= enc2_im;
        s12_flag_re <= enc2_flag_re;
        s12_flag_im <= enc2_flag_im;
        s12_valid   <= s1_valid;
    end

    // ==========================================================
    // STAGE 2 - Delay-2 butterfly, W^0=1 / W^2=-j
    // ==========================================================
    wire signed [15:0] s2_re, s2_im;
    wire               s2_valid;

    stage2_radix2_sdf_stream STAGE2 (
        .clk        (clk),
        .valid_in   (s12_valid),
        .xin_re     (s12_re),
        .xin_im     (s12_im),
        .inv_flag_re(s12_flag_re),
        .inv_flag_im(s12_flag_im),
        .xout_re    (s2_re),
        .xout_im    (s2_im),
        .valid_out  (s2_valid)
    );

    // ==========================================================
    // BUS 3 - ENC3 instances driven by stable s2 registers
    // ==========================================================
    wire signed [15:0] enc3_re,  enc3_im;
    wire               enc3_flag_re, enc3_flag_im;

    bit_inv_encoder ENC3_RE (.in(s2_re), .out(enc3_re),  .inv_flag(enc3_flag_re));
    bit_inv_encoder ENC3_IM (.in(s2_im), .out(enc3_im),  .inv_flag(enc3_flag_im));

    reg signed [15:0] s23_re,      s23_im;
    reg               s23_flag_re, s23_flag_im;
    reg               s23_valid;

    initial begin s23_re=0; s23_im=0; s23_flag_re=0; s23_flag_im=0; s23_valid=0; end

    always @(posedge clk) begin : s23_reg
        s23_re      <= enc3_re;
        s23_im      <= enc3_im;
        s23_flag_re <= enc3_flag_re;
        s23_flag_im <= enc3_flag_im;
        s23_valid   <= s2_valid;
    end

    // ==========================================================
    // STAGE 3 - Delay-1 butterfly, CSD twiddles
    //           Contains: DEC_RE, DEC_IM, CSD_T1, CSD_T2A, CSD_T2B, CSD_T3
    // ==========================================================
    wire signed [15:0] s3_re, s3_im;
    wire               s3_valid;

    stage3_radix2_sdf_stream STAGE3 (
        .clk        (clk),
        .valid_in   (s23_valid),
        .xin_re     (s23_re),
        .xin_im     (s23_im),
        .inv_flag_re(s23_flag_re),
        .inv_flag_im(s23_flag_im),
        .xout_re    (s3_re),
        .xout_im    (s3_im),
        .valid_out  (s3_valid)
    );

    assign xout_re   = s3_re;
    assign xout_im   = s3_im;
    assign valid_out = s3_valid;

endmodule