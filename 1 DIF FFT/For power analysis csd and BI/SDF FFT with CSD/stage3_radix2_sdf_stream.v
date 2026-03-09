// ============================================================
// Module : stage3_radix2_sdf_stream
// Description : Radix-2 SDF DIF Stage 3 - Delay = 1
//
// Twiddle factors:
//   W^0 =  1              ? passthrough (no multiply)
//   W^1 =  (1-j)/sqrt(2)  ? CSD constant coefficient multiply
//   W^2 = -j              ? sign/swap (no multiply)
//   W^3 = -(1+j)/sqrt(2)  ? CSD constant coefficient multiply
//
// CSD Multiplier (csd_sqrt2_inv):
//   Replaces the original (t>>>1)+(t>>>2) = 0.75 approximation
//   with a 5-term shift-add = 0.70703125 (error < 0.011%)
//   Formula: (t>>1)+(t>>3)+(t>>4)+(t>>6)+(t>>8)
//   Cost: 4 adders + 5 wire shifts vs original 1 adder
//   But 0.75 has 6.1% error vs 0.011% for CSD - 550x more accurate
//
// Twiddle sum terms (all combinational wires from stable regs):
//   t1 = d_re + d_im  : for W^1 real part
//   t2 = d_im - d_re  : for W^1 imag part / W^3 real part
//   t3 = -(d_re+d_im) : for W^3 imag part
//
// d_re/d_im declared as WIRES (not regs) - combinational from
// stable delay register + stable input, so CSD sees correct
// values at every clock edge. (Fix from Vedic PDF bug note.)
// ============================================================
module stage3_radix2_sdf_stream (
    input  wire        clk,
    input  wire        valid_in,
    input  wire signed [15:0] xin_re,
    input  wire signed [15:0] xin_im,
    output reg  signed [15:0] xout_re,
    output reg  signed [15:0] xout_im,
    output reg         valid_out
);

    // ----------------------------------------------------------
    // Registered state
    // ----------------------------------------------------------
    reg signed [15:0] delay_re, delay_im;   // 1-sample delay buffer
    reg signed [15:0] diff_re,  diff_im;    // stored twiddle-rotated difference
    reg               phase;                 // 0=STORE+DIFF-OUT, 1=BUTTERFLY
    reg [1:0]         tw_idx;               // twiddle index 0..3

    // ----------------------------------------------------------
    // Combinational difference - WIRES from stable regs + input
    // Ensures CSD sees correct values before posedge latches result
    // ----------------------------------------------------------
    wire signed [16:0] d_re = {delay_re[15], delay_re} - {xin_re[15], xin_re};
    wire signed [16:0] d_im = {delay_im[15], delay_im} - {xin_im[15], xin_im};

    // ----------------------------------------------------------
    // Twiddle sum terms - 18-bit combinational wires
    //   W^1: diff_re = (d_re + d_im) / sqrt(2)  ? t1
    //        diff_im = (d_im - d_re) / sqrt(2)  ? t2
    //   W^3: diff_re = (d_im - d_re) / sqrt(2)  ? t2  (reused)
    //        diff_im = -(d_re + d_im) / sqrt(2) ? t3
    // ----------------------------------------------------------
    wire signed [17:0] t1 = {d_re[16], d_re} + {d_im[16], d_im}; // d_re + d_im
    wire signed [17:0] t2 = {d_im[16], d_im} - {d_re[16], d_re}; // d_im - d_re
    wire signed [17:0] t3 = -({d_re[16], d_re} + {d_im[16], d_im}); // -(d_re+d_im)

    // ----------------------------------------------------------
    // CSD multiplier instances - 4 adders each, purely comb
    // One instance per twiddle output channel (re/im for W1/W3)
    // W1 and W3 share t2 on their real/imag respectively ? reuse
    // ----------------------------------------------------------
    wire signed [15:0] csd_w1_re, csd_w1_im;
    wire signed [15:0] csd_w3_re, csd_w3_im;

    csd_sqrt2_inv U_W1_RE (.in(t1), .out(csd_w1_re));  // W1 real
    csd_sqrt2_inv U_W1_IM (.in(t2), .out(csd_w1_im));  // W1 imag
    csd_sqrt2_inv U_W3_RE (.in(t2), .out(csd_w3_re));  // W3 real (reuses t2)
    csd_sqrt2_inv U_W3_IM (.in(t3), .out(csd_w3_im));  // W3 imag

    // ----------------------------------------------------------
    // Initialisation
    // ----------------------------------------------------------
    initial begin
        phase     = 0;
        tw_idx    = 0;
        valid_out = 0;
        delay_re  = 0; delay_im = 0;
        diff_re   = 0; diff_im  = 0;
    end

    // ----------------------------------------------------------
    // Clocked butterfly logic
    // ----------------------------------------------------------
    always @(posedge clk) begin
        valid_out <= 0;
        if (valid_in) begin

            // ---------- PHASE 0: output stored diff, latch new input ----------
            if (phase == 0) begin
                xout_re   <= diff_re;
                xout_im   <= diff_im;
                valid_out <= 1;
                delay_re  <= xin_re;
                delay_im  <= xin_im;
            end

            // ---------- PHASE 1: butterfly ----------
            else begin
                // Sum output (W^0 = 1 on sum path always)
                xout_re   <= delay_re + xin_re;
                xout_im   <= delay_im + xin_im;
                valid_out <= 1;

                case (tw_idx)
                    // W^0 = 1 : passthrough
                    2'd0: begin
                        diff_re <= d_re[15:0];
                        diff_im <= d_im[15:0];
                    end
                    // W^1 = (1-j)/sqrt(2)
                    // diff_re = (d_re + d_im) * 1/sqrt(2)  [CSD on t1]
                    // diff_im = (d_im - d_re) * 1/sqrt(2)  [CSD on t2]
                    2'd1: begin
                        diff_re <= csd_w1_re;
                        diff_im <= csd_w1_im;
                    end
                    // W^2 = -j : sign/swap, no multiply
                    2'd2: begin
                        diff_re <=  d_im[15:0];
                        diff_im <= -d_re[15:0];
                    end
                    // W^3 = -(1+j)/sqrt(2)
                    // diff_re = (d_im - d_re) * 1/sqrt(2)  [CSD on t2]
                    // diff_im = -(d_re + d_im) * 1/sqrt(2) [CSD on t3]
                    2'd3: begin
                        diff_re <= csd_w3_re;
                        diff_im <= csd_w3_im;
                    end
                endcase

                tw_idx <= tw_idx + 1'b1;
            end

            phase <= ~phase;
        end
    end

endmodule