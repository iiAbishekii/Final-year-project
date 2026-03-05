module stage3_radix2_sdf_stream (
    input  wire        clk,
    input  wire        valid_in,
    input  wire signed [15:0] xin_re,
    input  wire signed [15:0] xin_im,
    output reg  signed [15:0] xout_re,
    output reg  signed [15:0] xout_im,
    output reg         valid_out
);

    // -------------------------------------------------------------------------
    // Q1.15 constant: round(0.707107 * 2^15) = 23170 = 0x5A82
    // -------------------------------------------------------------------------
    localparam signed [15:0] SQRT2_INV_Q15 = 16'sh5A82;

    // -------------------------------------------------------------------------
    // Registered state
    // -------------------------------------------------------------------------
    reg signed [15:0] delay_re, delay_im;   // 1-sample delay buffer
    reg signed [15:0] diff_re,  diff_im;    // stored twiddle-rotated difference
    reg               phase;                // 0 = STORE+DIFF-OUT, 1 = BUTTERFLY
    reg        [1:0]  tw_idx;              // twiddle index 0..3

    // -------------------------------------------------------------------------
    // Combinational difference - WIRES from stable registered + input signals
    //   delay_re/delay_im : registered, stable before posedge clk
    //   xin_re/xin_im     : inputs, stable before posedge clk
    //   => d_re/d_im settle combinationally, Vedic sees correct values
    // -------------------------------------------------------------------------
    wire signed [16:0] d_re = {delay_re[15], delay_re} - {xin_re[15], xin_re};
    wire signed [16:0] d_im = {delay_im[15], delay_im} - {xin_im[15], xin_im};

    // -------------------------------------------------------------------------
    // Twiddle sum terms - all combinational wires (18-bit)
    //
    //  W^1 = (1-j)/sqrt(2):
    //    diff_re = (d_re + d_im) * 0.707   ->  w1_t1
    //    diff_im = (d_im - d_re) * 0.707   ->  w1_t2
    //
    //  W^3 = -(1+j)/sqrt(2):
    //    diff_re = -(d_re - d_im) * 0.707
    //            =  (d_im - d_re) * 0.707  ->  w1_t2  (identical, reused)
    //    diff_im = -(d_re + d_im) * 0.707  ->  w3_t2
    // -------------------------------------------------------------------------
    wire signed [17:0] w1_t1 = {d_re[16], d_re} + {d_im[16], d_im}; //  d_re + d_im
    wire signed [17:0] w1_t2 = {d_im[16], d_im} - {d_re[16], d_re}; //  d_im - d_re
    wire signed [17:0] w3_t2 = -({d_re[16], d_re} + {d_im[16], d_im}); // -(d_re + d_im)

    // -------------------------------------------------------------------------
    // Vedic multiplier inputs: arithmetic >>2 to fit 18-bit into 16-bit port
    // -------------------------------------------------------------------------
    wire signed [15:0] vmul_w1_re_in = w1_t1[17:2];  //  (d_re + d_im) >> 2
    wire signed [15:0] vmul_w1_im_in = w1_t2[17:2];  //  (d_im - d_re) >> 2
    wire signed [15:0] vmul_w3_re_in = w1_t2[17:2];  //  (d_im - d_re) >> 2  [same as W1_IM]
    wire signed [15:0] vmul_w3_im_in = w3_t2[17:2];  // -(d_re + d_im) >> 2

    // -------------------------------------------------------------------------
    // Vedic 16x16 signed multiplier instances
    // -------------------------------------------------------------------------
    wire signed [31:0] prod_w1_re, prod_w1_im;
    wire signed [31:0] prod_w3_re, prod_w3_im;

    vedic_16x16_signed U_W1_RE (
        .a (vmul_w1_re_in),
        .b (SQRT2_INV_Q15),
        .p (prod_w1_re)
    );

    vedic_16x16_signed U_W1_IM (
        .a (vmul_w1_im_in),
        .b (SQRT2_INV_Q15),
        .p (prod_w1_im)
    );

    vedic_16x16_signed U_W3_RE (
        .a (vmul_w3_re_in),
        .b (SQRT2_INV_Q15),
        .p (prod_w3_re)
    );

    vedic_16x16_signed U_W3_IM (
        .a (vmul_w3_im_in),
        .b (SQRT2_INV_Q15),
        .p (prod_w3_im)
    );

    // -------------------------------------------------------------------------
    // Q1.15 result extraction:
    //   Input was >>2 (÷4), so extract product[28:13] instead of [30:15]
    //   Net: t * 23170 >> 15  =  t * 0.70709  =  t / sqrt(2)
    // -------------------------------------------------------------------------
    wire signed [15:0] result_w1_re = prod_w1_re[28:13];
    wire signed [15:0] result_w1_im = prod_w1_im[28:13];
    wire signed [15:0] result_w3_re = prod_w3_re[28:13];
    wire signed [15:0] result_w3_im = prod_w3_im[28:13];

    // -------------------------------------------------------------------------
    // Initialisation
    // -------------------------------------------------------------------------
    initial begin
        phase     = 0;
        tw_idx    = 0;
        valid_out = 0;
        delay_re  = 0;  delay_im = 0;
        diff_re   = 0;  diff_im  = 0;
    end

    // -------------------------------------------------------------------------
    // Clocked butterfly logic
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        valid_out <= 0;

        if (valid_in) begin

            // ------------------------------------------------------------------
            // PHASE 0: output stored diff, latch new input into delay register
            // ------------------------------------------------------------------
            if (phase == 0) begin
                xout_re   <= diff_re;
                xout_im   <= diff_im;
                valid_out <= 1;
                delay_re  <= xin_re;
                delay_im  <= xin_im;
            end

            // ------------------------------------------------------------------
            // PHASE 1: butterfly
            //   Sum  -> drive output immediately
            //   Diff -> apply twiddle, latch result into diff_re/diff_im
            //
            //   All Vedic inputs are combinational wires already settled ->
            //   result_wX_re/im are valid and stable at this clock edge.
            // ------------------------------------------------------------------
            else begin
                // Sum output (W^0 = 1 on sum path always)
                xout_re   <= delay_re + xin_re;
                xout_im   <= delay_im + xin_im;
                valid_out <= 1;

                case (tw_idx)

                    // ----------------------------------------------------------
                    // W^0 = 1  : passthrough
                    // ----------------------------------------------------------
                    2'd0: begin
                        diff_re <= d_re[15:0];
                        diff_im <= d_im[15:0];
                    end

                    // ----------------------------------------------------------
                    // W^1 = (1 - j) / sqrt(2)
                    //   diff_re = (d_re + d_im) * 0.707
                    //   diff_im = (d_im - d_re) * 0.707
                    // ----------------------------------------------------------
                    2'd1: begin
                        diff_re <= result_w1_re;
                        diff_im <= result_w1_im;
                    end

                    // ----------------------------------------------------------
                    // W^2 = -j  : sign/swap
                    //   diff_re =  d_im
                    //   diff_im = -d_re
                    // ----------------------------------------------------------
                    2'd2: begin
                        diff_re <=  d_im[15:0];
                        diff_im <= -d_re[15:0];
                    end

                    // ----------------------------------------------------------
                    // W^3 = -(1 + j) / sqrt(2)
                    //   diff_re = -(d_re - d_im) * 0.707 = (d_im - d_re) * 0.707
                    //   diff_im = -(d_re + d_im) * 0.707
                    // ----------------------------------------------------------
                    2'd3: begin
                        diff_re <= result_w3_re;
                        diff_im <= result_w3_im;
                    end

                endcase

                tw_idx <= tw_idx + 1'b1;
            end

            phase <= ~phase;
        end
    end

endmodule
