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

    // Blocking temporaries
    reg signed [16:0] d_re, d_im;
    reg signed [17:0] t1, t2, t3;
    reg signed [17:0] csd_r;

    `define CSD(in) ((in>>>1)+(in>>>3)+(in>>>4)+(in>>>6)+(in>>>8))

    // ----------------------------------------------------------
    // AND-Gate Bypass for Stage 3 sum adder
    //
    // phase=1 (sum_phase): iso signals = real values → adder works
    // phase=0 (store_phase): iso signals = 0 → adder silent
    //
    // Note: delay_re/xin_re are 16-bit; {16{phase}} is the mask.
    // ----------------------------------------------------------
    wire signed [15:0] iso_dre = delay_re & {16{phase}};
    wire signed [15:0] iso_dim = delay_im & {16{phase}};
    wire signed [15:0] iso_xre = xin_re   & {16{phase}};
    wire signed [15:0] iso_xim = xin_im   & {16{phase}};

    initial begin
        phase = 0; tw_idx = 0; valid_out = 0;
        delay_re = 0; delay_im = 0;
        diff_re  = 0; diff_im  = 0;
    end

    always @(posedge clk) begin
        valid_out <= 0;
        if (valid_in) begin

            // 17-bit sign-extended difference
            // Used only in sum_phase (phase=1) for twiddle computation.
            d_re = {delay_re[15], delay_re} - {xin_re[15], xin_re};
            d_im = {delay_im[15], delay_im} - {xin_im[15], xin_im};

            // ── STORE PHASE (phase=0) ─────────────────────────
            // Emit twiddle-multiplied diff stored from last sum_phase.
            // Update delay register with current input.
            // iso_dre = 0, iso_xre = 0 → sum adder sees 0+0 = silent.
            if (phase == 1'b0) begin
                xout_re   <= diff_re;
                xout_im   <= diff_im;
                valid_out <= 1;
                delay_re  <= xin_re;
                delay_im  <= xin_im;
            end

            // ── SUM PHASE (phase=1) ───────────────────────────
            // iso_dre = delay_re, iso_xre = xin_re (phase=1 → mask=all-1s)
            // Sum output through AND-gated inputs.
            // CSD twiddle applied to butterfly difference d_re/d_im.
            else begin
                xout_re   <= iso_dre + iso_xre;
                xout_im   <= iso_dim + iso_xim;
                valid_out <= 1;

                case (tw_idx)
                    2'd0: begin  // W^0 = 1 - pass diff unchanged
                        diff_re <= d_re[15:0];
                        diff_im <= d_im[15:0];
                    end
                    2'd1: begin  // W^1 = (1-j)/sqrt(2) - CSD on t1, t2
                        t1    = {d_re[16],d_re} + {d_im[16],d_im};
                        t2    = {d_im[16],d_im} - {d_re[16],d_re};
                        csd_r = `CSD(t1); diff_re <= csd_r[15:0];
                        csd_r = `CSD(t2); diff_im <= csd_r[15:0];
                    end
                    2'd2: begin  // W^2 = -j - rotate diff -90 deg
                        diff_re <=  d_im[15:0];
                        diff_im <= -d_re[15:0];
                    end
                    2'd3: begin  // W^3 = -(1+j)/sqrt(2) - CSD on t2, t3
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