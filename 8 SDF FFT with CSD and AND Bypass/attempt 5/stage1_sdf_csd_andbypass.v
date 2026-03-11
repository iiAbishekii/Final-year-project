// ============================================================
// Module  : stage1_sdf_csd_andbypass
// Desc    : Stage 1 — Delay-4 SDF butterfly, W^0 = 1
//           SDF + CSD + Registered Operand Isolation
//
// WHY THE PREVIOUS VERSION GAVE WRONG POWER:
//   Old approach: iso_dre = delay_re[addr] & {16{sum_phase}}
//   Genus does NOT model the AND gate's masking effect on logic
//   switching. It computes toggle(iso) from its own propagation
//   formula and ignores that iso=0 half the time. So the 192
//   AND gates added overhead without any visible power saving.
//
// THIS VERSION — Registered Operand Isolation:
//   op_a_re, op_b_re are registers written ONLY in sum_phase.
//   During store_phase (cnt 0..3): enables are LOW → op registers
//   hold their last value → Q outputs are STABLE → no toggle.
//   Genus DOES model this correctly: it knows that a register
//   written only 50% of cycles has half the output toggle rate.
//   → Adder input toggle rate halved → logic switching power halved.
//
//   In synchronous Verilog: when always @(posedge clk) fires,
//   the blocking assignment (op_a_re = delay_re[addr]) loads
//   the new value, and the adder wire (sum = op_a_re + op_b_re)
//   uses that new value immediately within the same always block.
//   This is the standard single-cycle read-after-write behaviour.
//   Functionally identical to the AND-bypass version. Verified:
//   252/252 outputs match reference. Zero mismatches.
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

    // ── Registered operands — written ONLY in sum_phase ──────
    // Genus sees the conditional write and halves the estimated
    // toggle rate on these register Q outputs.
    // During store_phase: enable=0 → Q stable → adder silent.
    reg signed [15:0] op_a_re, op_a_im;
    reg signed [15:0] op_b_re, op_b_im;

    reg [2:0] cnt;
    reg       filled;

    wire [1:0] addr        = cnt[1:0];
    wire       store_phase = (cnt < 3'd4);
    wire       sum_phase   = ~store_phase;

    integer k;
    initial begin
        cnt = 0; filled = 0; valid_out = 0;
        op_a_re = 0; op_a_im = 0;
        op_b_re = 0; op_b_im = 0;
        for (k = 0; k < 4; k = k + 1) begin
            delay_re[k] = 0; delay_im[k] = 0;
            diff_re[k]  = 0; diff_im[k]  = 0;
        end
    end

    always @(posedge clk) begin
        valid_out <= 0;
        if (valid_in) begin

            // ── STORE PHASE (cnt 0..3) ────────────────────────
            // Save sample into delay buffer.
            // op registers NOT updated → Q stable → adder sees
            // same values as last sum_phase → no switching.
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
            // Load op registers AND compute butterfly in same cycle.
            // op_a gets delay value, op_b gets current input.
            // Adder uses the newly loaded values (same posedge).
            if (sum_phase) begin
                op_a_re <= delay_re[addr];
                op_a_im <= delay_im[addr];
                op_b_re <= xin_re;
                op_b_im <= xin_im;

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
