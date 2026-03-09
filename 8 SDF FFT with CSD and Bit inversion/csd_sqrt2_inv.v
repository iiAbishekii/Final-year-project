// ============================================================
// Module  : csd_sqrt2_inv
// Project : Optimization of FFT Processor
//
// Description:
//   Canonical Signed Digit (CSD) constant multiplier for 1/?2.
//   Approximates multiplication by (1/?2 ? 0.70703125) using
//   5 arithmetic right-shifts and 4 additions - no multiplier needed.
//
//     out = (in>>>1) + (in>>>3) + (in>>>4) + (in>>>6) + (in>>>8)
//
//   Error < 0.011% vs exact 1/?2 = 0.70710678...
//
//   Input  : 18-bit signed  (butterfly difference, sign-extended)
//   Output : 16-bit signed  (lower 16 bits of 18-bit result)
//
// Instantiated in stage3_radix2_sdf_stream as four instances:
//   CSD_T1   - computes (d_re+d_im)/?2  ?  W^1 real part
//   CSD_T2A  - computes (d_im-d_re)/?2  ?  W^1 imag part
//   CSD_T2B  - computes (d_im-d_re)/?2  ?  W^3 real part
//   CSD_T3   - computes -(d_re+d_im)/?2 ?  W^3 imag part
//
// The instances are driven by registered twiddle inputs
// (t1_reg, t2_reg, t3_reg) which are set in the sum_phase.
// Their combinational outputs are read directly as xout_re/im
// in the following store_phase - inputs are stable, no race.
// ============================================================
module csd_sqrt2_inv (
    input  wire signed [17:0] in,
    output wire signed [15:0] out
);
    wire signed [17:0] s1 = in >>> 1;
    wire signed [17:0] s3 = in >>> 3;
    wire signed [17:0] s4 = in >>> 4;
    wire signed [17:0] s6 = in >>> 6;
    wire signed [17:0] s8 = in >>> 8;

    wire signed [17:0] result = s1 + s3 + s4 + s6 + s8;

    assign out = result[15:0];

endmodule