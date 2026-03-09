`timescale 1ns/1ps
// ============================================================
// Module : csd_sqrt2_inv
// Description : Constant Coefficient Multiplier for 1/sqrt(2)
//               using Canonical Signed Digit (CSD) shift-add.
//
// Formula (5-term):
//   out = (in>>1) + (in>>3) + (in>>4) + (in>>6) + (in>>8)
//       = 0.5 + 0.125 + 0.0625 + 0.015625 + 0.00390625
//       = 0.70703125
//
// Exact 1/sqrt(2) = 0.70710678  ?  error = 0.000076 (< 0.011%)
//
// Input  : 18-bit signed (twiddle sum terms t1/t2/t3 from stage3)
// Output : 16-bit signed (truncated result, matches diff register)
//
// Gate count : 5 wire shifts (zero gates) + 4 x 18-bit adders
// Compare    : Vedic 16x16 uses hundreds of AND/XOR gate cells
//
// Why 18-bit input?
//   d_re, d_im are 17-bit (16-bit subtract with sign extension)
//   t1 = d_re + d_im ? 18-bit to hold the carry
//   t2 = d_im - d_re ? 18-bit
//   t3 = -(d_re+d_im) ? 18-bit
// ============================================================
module csd_sqrt2_inv (
    input  wire signed [17:0] in,
    output wire signed [15:0] out
);
    // All shifts are free - just wire renamings, zero gate cost
    // Intermediate sums use 18-bit to prevent overflow during addition
    wire signed [17:0] s1 = in >>> 1;   // * 0.500000
    wire signed [17:0] s3 = in >>> 3;   // * 0.125000
    wire signed [17:0] s4 = in >>> 4;   // * 0.062500
    wire signed [17:0] s6 = in >>> 6;   // * 0.015625
    wire signed [17:0] s8 = in >>> 8;   // * 0.003906
                                         // total = 0.707031

    // Tree of adders - 4 additions, fully combinational
    wire signed [17:0] sum01 = s1 + s3;          // 0.625
    wire signed [17:0] sum02 = sum01 + s4;        // 0.687500
    wire signed [17:0] sum03 = sum02 + s6;        // 0.703125
    wire signed [17:0] result = sum03 + s8;       // 0.707031

    // Truncate to 16-bit - upper bits are always sign extension
    assign out = result[15:0];

endmodule
