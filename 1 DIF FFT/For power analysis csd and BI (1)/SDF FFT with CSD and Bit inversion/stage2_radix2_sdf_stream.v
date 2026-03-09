// ============================================================
// Module  : stage2_radix2_sdf_stream
// Project : Optimization of FFT Processor
//
// Description:
//   Radix-2 SDF DIF butterfly, Stage 2. Delay = 2.
//   W^0 = 1 (addr=0),  W^2 = -j (addr=1)
//
// Hierarchy:
//   DEC_RE : bit_inv_decoder   real-channel BIC decode
//   DEC_IM : bit_inv_decoder   imag-channel BIC decode
// ============================================================
module stage2_radix2_sdf_stream (
    input  wire        clk,
    input  wire        valid_in,
    input  wire signed [15:0] xin_re,
    input  wire signed [15:0] xin_im,
    input  wire               inv_flag_re,
    input  wire               inv_flag_im,
    output reg  signed [15:0] xout_re,
    output reg  signed [15:0] xout_im,
    output reg                valid_out
);

    wire signed [15:0] dec_re, dec_im;

    bit_inv_decoder DEC_RE (.in(xin_re), .inv_flag(inv_flag_re), .out(dec_re));
    bit_inv_decoder DEC_IM (.in(xin_im), .inv_flag(inv_flag_im), .out(dec_im));

    reg signed [15:0] delay_re [0:1];
    reg signed [15:0] delay_im [0:1];
    reg signed [15:0] diff_re  [0:1];
    reg signed [15:0] diff_im  [0:1];
    reg [1:0] cnt;
    reg       filled;

    wire       addr        = cnt[0];
    wire       store_phase = (cnt < 2'd2);
    wire       sum_phase   = (cnt >= 2'd2);

    reg signed [15:0] a_re, a_im, d_re, d_im;

    integer k;
    initial begin
        cnt = 0; filled = 0; valid_out = 0;
        for (k = 0; k < 2; k = k + 1) begin
            delay_re[k]=0; delay_im[k]=0; diff_re[k]=0; diff_im[k]=0;
        end
    end

    always @(posedge clk) begin
        valid_out <= 0;
        if (valid_in) begin
            if (store_phase) begin
                delay_re[addr] <= dec_re;
                delay_im[addr] <= dec_im;
                if (filled) begin
                    xout_re   <= diff_re[addr];
                    xout_im   <= diff_im[addr];
                    valid_out <= 1;
                end
            end
            if (sum_phase) begin
                a_re = delay_re[addr]; a_im = delay_im[addr];
                xout_re   <= a_re + dec_re;
                xout_im   <= a_im + dec_im;
                valid_out <= 1;
                d_re = a_re - dec_re; d_im = a_im - dec_im;
                if (addr == 1'b1) begin   // W^2 = -j
                    diff_re[addr] <=  d_im;
                    diff_im[addr] <= -d_re;
                end else begin            // W^0 = 1
                    diff_re[addr] <= d_re;
                    diff_im[addr] <= d_im;
                end
            end
            if (cnt == 2'd3) filled <= 1;
            cnt <= cnt + 2'd1;
        end
    end

endmodule
