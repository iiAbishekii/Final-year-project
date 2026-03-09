// Stage 3 — Delay-1 SDF butterfly, CSD twiddles W^0..W^3
//
// CSD formula: 1/sqrt(2) ≈ (t>>>1)+(t>>>3)+(t>>>4)+(t>>>6)+(t>>>8)
//   = 0.5 + 0.125 + 0.0625 + 0.015625 + 0.00390625 = 0.70703125
//   Error vs exact 1/sqrt(2) = 0.70710678 : < 0.011%
//
// CSD is INLINED (not submodule instances) to:
//   1. Avoid duplicate logic (no CSD_T2A/CSD_T2B issue)
//   2. Let synthesis properly optimize/share shift terms
//   3. No extra port wiring overhead
//
// tw_idx cycles 0->3, increments each sum_phase:
//   0: W^0 =  1          → diff = d (pass through)
//   1: W^1 = (1-j)/√2    → diff_re = CSD(d_re+d_im), diff_im = CSD(d_im-d_re)
//   2: W^2 = -j           → diff_re = d_im, diff_im = -d_re
//   3: W^3 = -(1+j)/√2   → diff_re = CSD(d_im-d_re), diff_im = CSD(-(d_re+d_im))
//
// No bit inversion decoders — inputs are clean registered values.
module stage3_sdf_csd (
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

    // Blocking temporaries (used within always block only)
    reg signed [16:0] d_re, d_im;
    reg signed [17:0] t1, t2, t3;
    reg signed [17:0] csd_r;

    // CSD function macro via task (pure combinational, blocking)
    // Returns: (in>>>1)+(in>>>3)+(in>>>4)+(in>>>6)+(in>>>8), truncated to 16b
    `define CSD(in) ((in>>>1)+(in>>>3)+(in>>>4)+(in>>>6)+(in>>>8))

    initial begin
        phase = 0; tw_idx = 0; valid_out = 0;
        delay_re = 0; delay_im = 0;
        diff_re  = 0; diff_im  = 0;
    end

    always @(posedge clk) begin
        valid_out <= 0;
        if (valid_in) begin
            // 17-bit sign-extended difference
            d_re = {delay_re[15], delay_re} - {xin_re[15], xin_re};
            d_im = {delay_im[15], delay_im} - {xin_im[15], xin_im};

            // ── STORE PHASE: emit diff from previous sum_phase ──
            if (phase == 1'b0) begin
                xout_re   <= diff_re;
                xout_im   <= diff_im;
                valid_out <= 1;
                delay_re  <= xin_re;
                delay_im  <= xin_im;
            end

            // ── SUM PHASE: emit sum, compute and store twiddle diff ──
            else begin
                xout_re   <= delay_re + xin_re;
                xout_im   <= delay_im + xin_im;
                valid_out <= 1;

                case (tw_idx)
                    2'd0: begin  // W^0 = 1
                        diff_re <= d_re[15:0];
                        diff_im <= d_im[15:0];
                    end
                    2'd1: begin  // W^1 = (1-j)/sqrt(2)
                        t1 = {d_re[16],d_re} + {d_im[16],d_im};  // d_re + d_im
                        t2 = {d_im[16],d_im} - {d_re[16],d_re};  // d_im - d_re
                        csd_r   = `CSD(t1); diff_re <= csd_r[15:0];
                        csd_r   = `CSD(t2); diff_im <= csd_r[15:0];
                    end
                    2'd2: begin  // W^2 = -j
                        diff_re <=  d_im[15:0];
                        diff_im <= -d_re[15:0];
                    end
                    2'd3: begin  // W^3 = -(1+j)/sqrt(2)
                        t2 = {d_im[16],d_im} - {d_re[16],d_re};   // d_im - d_re
                        t3 = -({d_re[16],d_re} + {d_im[16],d_im});// -(d_re+d_im)
                        csd_r   = `CSD(t2); diff_re <= csd_r[15:0];
                        csd_r   = `CSD(t3); diff_im <= csd_r[15:0];
                    end
                endcase

                tw_idx <= tw_idx + 2'd1;
            end

            phase <= ~phase;
        end
    end
endmodule