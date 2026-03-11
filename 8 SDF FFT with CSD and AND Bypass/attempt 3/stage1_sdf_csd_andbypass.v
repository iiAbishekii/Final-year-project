module stage1_sdf_csd_andbypass (
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

    // ----------------------------------------------------------
    // AND-Gate Bypass - isolate adder inputs during store_phase
    //
    // {16{sum_phase}} replicates the 1-bit sum_phase signal into
    // a 16-bit mask:
    //   sum_phase=1  →  16'hFFFF  →  AND passes real value
    //   sum_phase=0  →  16'h0000  →  AND forces zero
    //
    // These are pure combinational wires - zero extra registers.
    // Synthesis maps each bit to a single AND gate (16 gates total
    // per signal = 32 AND gates for re+im pair).
    // ----------------------------------------------------------
    wire signed [15:0] iso_dre = delay_re[addr] & {16{sum_phase}};
    wire signed [15:0] iso_dim = delay_im[addr] & {16{sum_phase}};
    wire signed [15:0] iso_xre = xin_re          & {16{sum_phase}};
    wire signed [15:0] iso_xim = xin_im          & {16{sum_phase}};

    integer k;
    initial begin
        cnt = 0; filled = 0; valid_out = 0;
        for (k = 0; k < 4; k = k + 1) begin
            delay_re[k] = 0; delay_im[k] = 0;
            diff_re[k]  = 0; diff_im[k]  = 0;
        end
    end

    always @(posedge clk) begin
        valid_out <= 0;
        if (valid_in) begin

            // ── STORE PHASE (cnt 0..3) ────────────────────────
            // Save incoming sample into delay buffer.
            // Output stored diff from previous block (if filled).
            // Adder is NOT needed here.
            // iso_dre/iso_xre = 0 during this phase → adder silent.
            if (store_phase) begin
                delay_re[addr] <= xin_re;
                delay_im[addr] <= xin_im;
                if (filled) begin
                    xout_re   <= diff_re[addr];
                    xout_im   <= diff_im[addr];
                    valid_out <= 1;
                end
            end

            // ── SUM PHASE (cnt 4..7) ──────────────────────────
            // Compute butterfly sum and diff using iso_ inputs.
            // iso_dre = delay_re[addr] (sum_phase=1 → mask=all-1s)
            // iso_xre = xin_re         (sum_phase=1 → mask=all-1s)
            // Result identical to delay_re[addr] + xin_re.
            if (sum_phase) begin
                xout_re       <= iso_dre + iso_xre;
                xout_im       <= iso_dim + iso_xim;
                valid_out     <= 1;
                diff_re[addr] <= iso_dre - iso_xre;
                diff_im[addr] <= iso_dim - iso_xim;
            end

            if (cnt == 3'd7) filled <= 1;
            cnt <= cnt + 3'd1;
        end
    end
endmodule
