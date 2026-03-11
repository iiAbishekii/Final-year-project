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

    reg signed [16:0] d_re, d_im;
    reg signed [17:0] t1, t2, t3;
    reg signed [17:0] csd_r;

    `define CSD(in) ((in>>>1)+(in>>>3)+(in>>>4)+(in>>>6)+(in>>>8))

    initial begin
        phase = 0; tw_idx = 0; valid_out = 0;
        delay_re = 0; delay_im = 0;
        diff_re  = 0; diff_im  = 0;
    end

    always @(posedge clk) begin
        valid_out <= 0;
        if (valid_in) begin

            d_re = {delay_re[15], delay_re} - {xin_re[15], xin_re};
            d_im = {delay_im[15], delay_im} - {xin_im[15], xin_im};

            // ── STORE PHASE (phase=0) ─────────────────────────
            // Emit previously stored twiddle-rotated diff.
            // Update delay register.
            // Sum adder (delay_re + xin_re) is not written to any
            // output register here, so no iso masking required.
            if (phase == 1'b0) begin
                xout_re   <= diff_re;
                xout_im   <= diff_im;
                valid_out <= 1;
                delay_re  <= xin_re;
                delay_im  <= xin_im;
            end

            // ── SUM PHASE (phase=1) ───────────────────────────
            // Direct adder read from delay registers (stable).
            // CSD twiddle applied to d_re / d_im.
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
                        t1 = {d_re[16],d_re} + {d_im[16],d_im};
                        t2 = {d_im[16],d_im} - {d_re[16],d_re};
                        csd_r = `CSD(t1); diff_re <= csd_r[15:0];
                        csd_r = `CSD(t2); diff_im <= csd_r[15:0];
                    end
                    2'd2: begin  // W^2 = -j
                        diff_re <=  d_im[15:0];
                        diff_im <= -d_re[15:0];
                    end
                    2'd3: begin  // W^3 = -(1+j)/sqrt(2)
                        t2 = {d_im[16],d_im} - {d_re[16],d_re};
                        t3 = -({d_re[16],d_re} + {d_im[16],d_im});
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


