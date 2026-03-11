module stage2_sdf_csd_andbypass (
    input  wire        clk,
    input  wire        valid_in,
    input  wire signed [15:0] xin_re,
    input  wire signed [15:0] xin_im,
    output reg  signed [15:0] xout_re,
    output reg  signed [15:0] xout_im,
    output reg                valid_out
);
    reg signed [15:0] delay_re [0:1];
    reg signed [15:0] delay_im [0:1];
    reg signed [15:0] diff_re  [0:1];
    reg signed [15:0] diff_im  [0:1];

    reg [1:0] cnt;
    reg       filled;

    wire       addr        = cnt[0];
    wire       store_phase = (cnt < 2'd2);
    wire       sum_phase   = (cnt >= 2'd2);

    reg signed [15:0] d_re, d_im;

    integer k;
    initial begin
        cnt = 0; filled = 0; valid_out = 0;
        for (k = 0; k < 2; k = k + 1) begin
            delay_re[k] = 0; delay_im[k] = 0;
            diff_re[k]  = 0; diff_im[k]  = 0;
        end
    end

    always @(posedge clk) begin
        valid_out <= 0;
        if (valid_in) begin

            // ── STORE PHASE (cnt 0..1) ────────────────────────
            if (store_phase) begin
                delay_re[addr] <= xin_re;
                delay_im[addr] <= xin_im;
                if (filled) begin
                    xout_re   <= diff_re[addr];
                    xout_im   <= diff_im[addr];
                    valid_out <= 1;
                end
            end

            // ── SUM PHASE (cnt 2..3) ──────────────────────────
            if (sum_phase) begin
                xout_re   <= delay_re[addr] + xin_re;
                xout_im   <= delay_im[addr] + xin_im;
                valid_out <= 1;
                d_re = delay_re[addr] - xin_re;
                d_im = delay_im[addr] - xin_im;
                if (addr == 1'b1) begin  // W^2 = -j
                    diff_re[addr] <=  d_im;
                    diff_im[addr] <= -d_re;
                end else begin           // W^0 = 1
                    diff_re[addr] <= d_re;
                    diff_im[addr] <= d_im;
                end
            end

            if (cnt == 2'd3) filled <= 1;
            cnt <= cnt + 2'd1;
        end
    end
endmodule
