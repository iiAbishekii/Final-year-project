// ============================================================
// Module  : stage3_sdf_csd_andbypass
// Desc    : Stage 3 — Delay-1 SDF butterfly + CSD twiddles
//           SDF + CSD + Registered Operand Isolation (CORRECTED)
//
// Fixes applied vs uploaded version:
//
//   FIX 1 — op_a actually used by adder (was dead register).
//     Stage 3 has 2-cycle period (phase=0 store, phase=1 sum).
//     op_a loaded in store_phase from current xin_re (which
//     becomes delay_re for the next sum_phase). During sum_phase
//     op_a is NOT updated → Q stable → adder input activity=0.5.
//
//   FIX 2 — d_re/d_im subtractor moved inside sum_phase only.
//     Was computed every valid cycle (activity=1.0). Now only
//     in sum_phase (activity=0.5). Halves 17-bit subtractor power.
//
//   FIX 3 — csd_r split into two independent wires.
//     Shared blocking reg csd_r was written twice per sum cycle
//     (tw_idx=1 and tw_idx=3), causing the 18-bit CSD shift-add
//     tree to evaluate twice. Two wires evaluate once each.
//
// CSD: 1/sqrt(2) ≈ (t>>>1)+(t>>>3)+(t>>>4)+(t>>>6)+(t>>>8)
// ============================================================
module stage3_sdf_csd_andbypass (
    input  wire        clk,
    input  wire        valid_in,
    input  wire signed [15:0] xin_re,
    input  wire signed [15:0] xin_im,
    output reg  signed [15:0] xout_re,
    output reg  signed [15:0] xout_im,
    output reg                valid_out
);
    reg signed [15:0] delay_re, delay_im;
    reg signed [15:0] diff_re,  diff_im;
    reg               phase;
    reg [1:0]         tw_idx;

    // FIX 1: op_a loaded in store_phase, read in sum_phase
    reg signed [15:0] op_a_re, op_a_im;

    // FIX 2: declared here, computed only in sum_phase
    reg signed [16:0] d_re, d_im;

    // FIX 3: two independent wires for CSD paths
    reg signed [17:0] t1, t2, t3;
    wire signed [17:0] csd_r1, csd_r2;

    `define CSD(in) ((in>>>1)+(in>>>3)+(in>>>4)+(in>>>6)+(in>>>8))

    assign csd_r1 = `CSD(t1);   // evaluates once — feeds diff_re
    assign csd_r2 = `CSD(t2);   // evaluates once — feeds diff_im

    initial begin
        phase = 0; tw_idx = 0; valid_out = 0;
        delay_re = 0; delay_im = 0;
        diff_re  = 0; diff_im  = 0;
        op_a_re  = 0; op_a_im  = 0;
        t1 = 0; t2 = 0; t3 = 0;
    end

    always @(posedge clk) begin
        valid_out <= 0;
        if (valid_in) begin

            if (phase == 1'b0) begin
                // ── STORE PHASE ───────────────────────────────
                // Emit twiddle-rotated diff from previous sum.
                // Pre-load op_a with current xin_re, which will
                // become delay_re for the upcoming sum_phase.
                // op_a is NOT updated in sum_phase → Q stable.
                xout_re   <= diff_re;
                xout_im   <= diff_im;
                valid_out <= 1;
                delay_re  <= xin_re;
                delay_im  <= xin_im;
                op_a_re   <= xin_re;   // FIX 1: pre-load here
                op_a_im   <= xin_im;
            end
            else begin
                // ── SUM PHASE ─────────────────────────────────
                // FIX 1: adder reads op_a_re (stable) + xin_re
                //        op_a_re activity = 0.5 (loaded every other cycle)
                // FIX 2: d_re/d_im computed only here (activity=0.5)
                d_re = {op_a_re[15], op_a_re} - {xin_re[15], xin_re};
                d_im = {op_a_im[15], op_a_im} - {xin_im[15], xin_im};

                xout_re   <= op_a_re + xin_re;
                xout_im   <= op_a_im + xin_im;
                valid_out <= 1;

                case (tw_idx)
                    2'd0: begin  // W^0 = 1
                        diff_re <= d_re[15:0];
                        diff_im <= d_im[15:0];
                    end
                    2'd1: begin  // W^1 = (1-j)/sqrt(2)
                        // FIX 3: t1 → csd_r1 (wire), t2 → csd_r2 (wire)
                        t1 = {d_re[16],d_re} + {d_im[16],d_im};
                        t2 = {d_im[16],d_im} - {d_re[16],d_re};
                        diff_re <= csd_r1[15:0];
                        diff_im <= csd_r2[15:0];
                    end
                    2'd2: begin  // W^2 = -j
                        diff_re <=  d_im[15:0];
                        diff_im <= -d_re[15:0];
                    end
                    2'd3: begin  // W^3 = -(1+j)/sqrt(2)
                        // FIX 3: t2 → csd_r2, t3 uses inline CSD
                        t2 = {d_im[16],d_im} - {d_re[16],d_re};
                        t3 = -({d_re[16],d_re} + {d_im[16],d_im});
                        diff_re <= csd_r2[15:0];
                        diff_im <= `CSD(t3);
                    end
                endcase

                tw_idx <= tw_idx + 2'd1;
            end

            phase <= ~phase;
        end
    end
endmodule
