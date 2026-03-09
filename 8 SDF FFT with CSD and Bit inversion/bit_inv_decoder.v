// ============================================================
// Module  : bit_inv_decoder
// Project : Optimization of FFT Processor
//
// Description:
//   Bus Invert Coding (BIC) decoder. Companion to bit_inv_encoder.
//   If inv_flag=1: inverts all bits to recover original value.
//   If inv_flag=0: passes through unchanged.
//
// Instantiated as DEC_RE / DEC_IM inside every stage module:
//   stage1_radix2_sdf, stage2_radix2_sdf_stream, stage3_radix2_sdf_stream
// ============================================================
module bit_inv_decoder (
    input  wire signed [15:0] in,
    input  wire               inv_flag,
    output wire signed [15:0] out
);
    assign out = inv_flag ? ~in : in;

endmodule