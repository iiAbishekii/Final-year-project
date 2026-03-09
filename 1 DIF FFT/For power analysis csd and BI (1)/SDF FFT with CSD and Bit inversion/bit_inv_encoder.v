// ============================================================
// Module  : bit_inv_encoder
// Project : Optimization of FFT Processor
//
// Description:
//   Bus Invert Coding (BIC) encoder. Counts 1s in a 16-bit word.
//   If ones > 8: inverts all bits, sets inv_flag=1  (fewer 1s sent)
//   If ones ? 8: passes through,   sets inv_flag=0
//
// This module is instantiated in fft8_radix2_sdf_stream_top as:
//   ENC1_RE, ENC1_IM  - Bus 1 (input ? stage1), fed from raw_reg
//   ENC2_RE, ENC2_IM  - Bus 2 (stage1 ? stage2), fed from s1 regs
//   ENC3_RE, ENC3_IM  - Bus 3 (stage2 ? stage3), fed from s2 regs
//
// All encoder instances are driven by REGISTERED signals so their
// combinational outputs are stable before each posedge - no race.
// ============================================================
module bit_inv_encoder (
    input  wire signed [15:0] in,
    output wire signed [15:0] out,
    output wire               inv_flag
);
    wire [4:0] ones_count =
          in[0]  + in[1]  + in[2]  + in[3]  +
          in[4]  + in[5]  + in[6]  + in[7]  +
          in[8]  + in[9]  + in[10] + in[11] +
          in[12] + in[13] + in[14] + in[15];

    assign inv_flag = (ones_count > 5'd8);
    assign out      = inv_flag ? ~in : in;

endmodule