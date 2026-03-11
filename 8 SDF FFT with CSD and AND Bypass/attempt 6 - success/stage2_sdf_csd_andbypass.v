// ============================================================
// Module  : stage2_sdf_csd_andbypass
// Desc    : Stage 2 — Delay-2 SDF butterfly, W^0=1 / W^2=-j
//           SDF + CSD + Registered Operand Isolation (CORRECTED)
//
// Same fix as stage1: op_a_re pre-loaded in store_phase so
// the adder input is stable during sum_phase (activity = 0.5).
// Adder reads op_a_re[addr] + xin_re — NOT delay_re directly.
// W^2=-j twiddle: diff_re = d_im, diff_im = -d_re.
// ============================================================
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

    // ── Registered operands — loaded ONLY in store_phase ─────
    reg signed [15:0] op_a_re [0:1];
    reg signed [15:0] op_a_im [0:1];

    reg [1:0] cnt;
    reg       filled;

    wire       addr        = cnt[0];
    wire       store_phase = (cnt < 2'd2);
    wire       sum_phase   = ~store_phase;

    reg signed [15:0] d_re, d_im;

    integer k;
    initial begin
        cnt = 0; filled = 0; valid_out = 0;
        for (k = 0; k < 2; k = k + 1) begin
            delay_re[k] = 0; delay_im[k] = 0;
            diff_re[k]  = 0; diff_im[k]  = 0;
            op_a_re[k]  = 0; op_a_im[k]  = 0;
        end
    end

    always @(posedge clk) begin
        valid_out <= 0;
        if (valid_in) begin

            if (store_phase) begin
                // ── STORE PHASE (cnt 0..1) ────────────────────
                // Pre-load op_a with the current xin which becomes
                // the delay value for the upcoming sum_phase slot.
                delay_re[addr] <= xin_re;
                delay_im[addr] <= xin_im;
                op_a_re[addr]  <= xin_re;  // stable during sum_phase
                op_a_im[addr]  <= xin_im;
                if (filled) begin
                    xout_re   <= diff_re[addr];
                    xout_im   <= diff_im[addr];
                    valid_out <= 1;
                end
            end

            if (sum_phase) begin
                // ── SUM PHASE (cnt 2..3) ──────────────────────
                // op_a_re[addr] is stable (not written here).
                // Adder input activity = 0.5 on the op_a side.
                xout_re   <= op_a_re[addr] + xin_re;
                xout_im   <= op_a_im[addr] + xin_im;
                valid_out <= 1;

                d_re = op_a_re[addr] - xin_re;
                d_im = op_a_im[addr] - xin_im;

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
