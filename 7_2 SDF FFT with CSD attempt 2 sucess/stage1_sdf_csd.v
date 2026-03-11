// Stage 1 — Delay-4 SDF butterfly, W^0=1 (trivial twiddle)
// No bit inversion decoders needed.
module stage1_sdf_csd (
    input  wire        clk,
    input  wire        valid_in,
    input  wire signed [15:0] xin_re,
    input  wire signed [15:0] xin_im,
    output reg  signed [15:0] xout_re,
    output reg  signed [15:0] xout_im,
    output reg                valid_out
);
    reg signed [15:0] delay_re [0:3];
    reg signed [15:0] delay_im [0:3];
    reg signed [15:0] diff_re  [0:3];
    reg signed [15:0] diff_im  [0:3];

    reg [2:0] cnt;
    reg       filled;

    wire [1:0] addr        = cnt[1:0];
    wire       store_phase = (cnt < 3'd4);
    wire       sum_phase   = (cnt >= 3'd4);

    integer k;
    initial begin
        cnt = 0; filled = 0; valid_out = 0;
        for (k = 0; k < 4; k = k + 1) begin
            delay_re[k]=0; delay_im[k]=0;
            diff_re[k]=0;  diff_im[k]=0;
        end
    end

    always @(posedge clk) begin
        valid_out <= 0;
        if (valid_in) begin
            if (store_phase) begin
                delay_re[addr] <= xin_re;
                delay_im[addr] <= xin_im;
                if (filled) begin
                    xout_re   <= diff_re[addr];
                    xout_im   <= diff_im[addr];
                    valid_out <= 1;
                end
            end
            if (sum_phase) begin
                xout_re       <= delay_re[addr] + xin_re;
                xout_im       <= delay_im[addr] + xin_im;
                valid_out     <= 1;
                diff_re[addr] <= delay_re[addr] - xin_re;
                diff_im[addr] <= delay_im[addr] - xin_im;
            end
            if (cnt == 3'd7) filled <= 1;
            cnt <= cnt + 3'd1;
        end
    end
endmodule