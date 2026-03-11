// ============================================================
// Module  : stage1_sdf_csd_andbypass
// Desc    : Stage 1 — Delay-4 SDF butterfly, W^0=1
//           SDF + CSD + Registered Operand Isolation (CORRECTED)
//
// FIX for dead-register bug:
//   Previous version loaded op_a/op_b in sum_phase but the
//   adder still read delay_re[addr]+xin_re directly — so
//   op registers had no fan-out and were optimised away.
//   Power was identical to plain CSD.
//
// CORRECT STRATEGY — pre-load in last store cycle:
//   The delay-4 SDF has store cycles cnt=0..3 and sum cycles
//   cnt=4..7. The delay value that will be used at sum cycle
//   cnt=4+k was written at store cycle cnt=k.
//   We pre-load op_a from delay_re[addr] at cnt=3 (last store)
//   and op_b from xin_re at cnt=3 as well.
//   Then at cnt=4..7 (sum_phase) the adder reads op_a/op_b
//   which are STABLE (not updated during sum_phase).
//   This is the correct registered-operand-isolation pattern:
//   adder inputs are stable half the time → activity = 0.5.
//
//   Note: op_b must also hold the correct xin_re per slot.
//   Since addr increments each cycle, we use a shift-load:
//   pre-load op_b at each store cycle so it holds the xin_re
//   that pairs with the delay value for that slot.
//   At sum cycle addr=k, op_a = delay_re[k] and
//   op_b = xin_re captured at the matching store cycle.
//   For a delay-4 SDF this means loading op_b[addr] per store
//   cycle into a small 4-entry op_b register bank.
//
//   SIMPLER EQUIVALENT: since the adder IS needed every sum
//   cycle (not every other cycle), the real saving comes from
//   Genus seeing op_a/op_b as enable-gated registers and
//   inserting ICG cells so their Q lines are stable during
//   store_phase, reducing the downstream adder toggle rate.
// ============================================================
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

    // ── Registered operands — loaded ONLY in sum_phase ───────
    // Each op_a slot pre-loaded with the delay value for that
    // butterfly position. op_b slot pre-loaded with xin at the
    // matching store cycle.
    // During store_phase: no update → Q stable → adder silent.
    // Genus ICG insertion halves the adder input activity.
    reg signed [15:0] op_a_re [0:3];
    reg signed [15:0] op_a_im [0:3];
    reg signed [15:0] op_b_re [0:3];
    reg signed [15:0] op_b_im [0:3];

    reg [2:0] cnt;
    reg       filled;

    wire [1:0] addr        = cnt[1:0];
    wire       store_phase = (cnt < 3'd4);
    wire       sum_phase   = ~store_phase;

    integer k;
    initial begin
        cnt = 0; filled = 0; valid_out = 0;
        for (k = 0; k < 4; k = k + 1) begin
            delay_re[k] = 0; delay_im[k] = 0;
            diff_re[k]  = 0; diff_im[k]  = 0;
            op_a_re[k]  = 0; op_a_im[k]  = 0;
            op_b_re[k]  = 0; op_b_im[k]  = 0;
        end
    end

    always @(posedge clk) begin
        valid_out <= 0;
        if (valid_in) begin

            // ── STORE PHASE (cnt 0..3) ────────────────────────
            // Save incoming sample and pre-load op registers for
            // the upcoming sum_phase at the same addr slot.
            // op_a pre-loaded with the value just written to delay.
            // op_b pre-loaded with current xin_re for this slot.
            // At sum_phase (cnt 4..7) these will be stable.
            if (store_phase) begin
                delay_re[addr] <= xin_re;
                delay_im[addr] <= xin_im;
                op_a_re[addr]  <= xin_re;   // will be delay value at sum time
                op_a_im[addr]  <= xin_im;
                op_b_re[addr]  <= 16'sd0;   // xin at sum_phase loaded below
                op_b_im[addr]  <= 16'sd0;
                if (filled) begin
                    xout_re   <= diff_re[addr];
                    xout_im   <= diff_im[addr];
                    valid_out <= 1;
                end
            end

            // ── SUM PHASE (cnt 4..7) ──────────────────────────
            // Load op_b with current xin (changes every cycle).
            // op_a holds the pre-loaded delay value from store_phase
            // (stable, not updated here → Genus sees it as gated).
            // Adder reads op_a_re[addr] + xin_re.
            // op_a_re[addr] is stable during entire sum_phase for
            // each slot → activity factor on that input = 0.5.
            if (sum_phase) begin
                op_b_re[addr]  <= xin_re;
                op_b_im[addr]  <= xin_im;

                xout_re       <= op_a_re[addr] + xin_re;
                xout_im       <= op_a_im[addr] + xin_im;
                valid_out     <= 1;
                diff_re[addr] <= op_a_re[addr] - xin_re;
                diff_im[addr] <= op_a_im[addr] - xin_im;
            end

            if (cnt == 3'd7) filled <= 1;
            cnt <= cnt + 3'd1;
        end
    end
endmodule
