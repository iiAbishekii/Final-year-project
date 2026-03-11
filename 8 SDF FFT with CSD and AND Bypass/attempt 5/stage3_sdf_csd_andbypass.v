// ============================================================
// Module  : stage3_sdf_csd_andbypass
// Desc    : Stage 3 — Delay-1 SDF butterfly + CSD twiddles
//           SDF + CSD + Registered Operand Isolation
//
// Stage 3 has a 2-cycle period (phase 0/1, not cnt 0..7).
// phase=0 (store): save input to delay register, emit diff
// phase=1 (sum):   compute butterfly sum and CSD-twiddle diff
//
// The op_a register is loaded only when phase=1.
// During phase=0: op_a holds previous value → adder stable.
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

    reg signed [15:0] op_a_re, op_a_im;

    reg signed [16:0] d_re, d_im;
    reg signed [17:0] t1, t2, t3, csd_r;

    `define CSD(in) ((in>>>1)+(in>>>3)+(in>>>4)+(in>>>6)+(in>>>8))

    initial begin
        phase = 0; tw_idx = 0; valid_out = 0;
        delay_re = 0; delay_im = 0;
        diff_re  = 0; diff_im  = 0;
        op_a_re  = 0; op_a_im  = 0;
    end

    always @(posedge clk) begin
        valid_out <= 0;
        if (valid_in) begin

            d_re = {delay_re[15], delay_re} - {xin_re[15], xin_re};
            d_im = {delay_im[15], delay_im} - {xin_im[15], xin_im};

            if (phase == 1'b0) begin
                // ── STORE PHASE ───────────────────────────────
                // Emit stored diff, update delay register.
                // op_a NOT updated → adder sees stable inputs.
                xout_re   <= diff_re;
                xout_im   <= diff_im;
                valid_out <= 1;
                delay_re  <= xin_re;
                delay_im  <= xin_im;
            end else begin
                // ── SUM PHASE ─────────────────────────────────
                // Load op_a register and compute sum in same cycle.
                op_a_re <= delay_re;
                op_a_im <= delay_im;

                xout_re   <= delay_re + xin_re;
                xout_im   <= delay_im + xin_im;
                valid_out <= 1;

                case (tw_idx)
                    2'd0: begin
                        diff_re <= d_re[15:0];
                        diff_im <= d_im[15:0];
                    end
                    2'd1: begin
                        t1    = {d_re[16],d_re} + {d_im[16],d_im};
                        t2    = {d_im[16],d_im} - {d_re[16],d_re};
                        csd_r = `CSD(t1); diff_re <= csd_r[15:0];
                        csd_r = `CSD(t2); diff_im <= csd_r[15:0];
                    end
                    2'd2: begin
                        diff_re <=  d_im[15:0];
                        diff_im <= -d_re[15:0];
                    end
                    2'd3: begin
                        t2    = {d_im[16],d_im} - {d_re[16],d_re};
                        t3    = -({d_re[16],d_re} + {d_im[16],d_im});
                        csd_r = `CSD(t2); diff_re <= csd_r[15:0];
                        csd_r = `CSD(t3); diff_im <= csd_r[15:0];
                    end
                endcase

                tw_idx <= tw_idx + 2'd1;
            end

            phase <= ~phase;
        end
    end
endmodule
