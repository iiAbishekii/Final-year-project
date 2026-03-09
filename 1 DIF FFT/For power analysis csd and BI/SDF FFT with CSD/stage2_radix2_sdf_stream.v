// ============================================================
// Module : stage2_radix2_sdf_stream
// Description : Radix-2 SDF DIF Stage 2 - Delay = 2
//               Twiddles: W^0=1 (pass), W^2=-j (swap/negate).
//               UNCHANGED from original - CSD only in Stage 3.
// ============================================================
module stage2_radix2_sdf_stream (
    input  wire        clk,
    input  wire        valid_in,
    input  wire signed [15:0] xin_re,
    input  wire signed [15:0] xin_im,
    output reg  signed [15:0] xout_re,
    output reg  signed [15:0] xout_im,
    output reg         valid_out
);
    reg signed [15:0] delay_re [0:1];
    reg signed [15:0] delay_im [0:1];
    reg signed [15:0] diff_re  [0:1];
    reg signed [15:0] diff_im  [0:1];
    reg [1:0]  cnt;
    wire       store_phase = (cnt < 2);
    wire       sum_phase   = (cnt >= 2);
    wire [0:0] addr        = cnt[0];
    reg signed [15:0] a_re, a_im, b_re, b_im, d_re, d_im;
    integer i;

    initial begin
        cnt = 0; valid_out = 0;
        for (i = 0; i < 2; i = i + 1) begin
            delay_re[i] = 0; delay_im[i] = 0;
            diff_re[i]  = 0; diff_im[i]  = 0;
        end
    end

    always @(posedge clk) begin
        valid_out <= 0;
        if (valid_in) begin
            if (store_phase) begin
                delay_re[addr] <= xin_re;
                delay_im[addr] <= xin_im;
            end
            if (sum_phase) begin
                a_re = delay_re[addr]; a_im = delay_im[addr];
                b_re = xin_re;         b_im = xin_im;
                xout_re   <= a_re + b_re;
                xout_im   <= a_im + b_im;
                valid_out <= 1;
                d_re = a_re - b_re;
                d_im = a_im - b_im;
                if (addr == 1'b1) begin
                    // W^2 = -j : (re,im) ? (im, -re)
                    diff_re[addr] <=  d_im;
                    diff_im[addr] <= -d_re;
                end else begin
                    // W^0 = 1 : passthrough
                    diff_re[addr] <= d_re;
                    diff_im[addr] <= d_im;
                end
            end
            if (!sum_phase) begin
                xout_re   <= diff_re[addr];
                xout_im   <= diff_im[addr];
                valid_out <= 1;
            end
            cnt <= cnt + 1;
        end
    end
endmodule