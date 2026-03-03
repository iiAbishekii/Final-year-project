module stage3_radix2_sdf_stream (
    input  wire              clk,
    input  wire              valid_in,
    input  wire signed [15:0] xin_re,
    input  wire signed [15:0] xin_im,
    output reg  signed [15:0] xout_re,
    output reg  signed [15:0] xout_im,
    output reg               valid_out
);

    reg signed [15:0] delay_re, delay_im;
    reg signed [15:0] diff_re, diff_im;

    reg phase;              // 0 = DIFF/STORE, 1 = SUM
    reg [1:0] tw_idx;       // <<< 2-bit twiddle index (0..3)

    reg signed [16:0] d_re, d_im;
    reg signed [17:0] t1, t2;

    initial begin
        phase   = 0;
        tw_idx  = 0;
        valid_out = 0;
        delay_re = 0; delay_im = 0;
        diff_re  = 0; diff_im  = 0;
    end

    always @(posedge clk) begin
        valid_out <= 0;

        if (valid_in) begin
            // ---------- DIFF OUT + STORE ----------
            if (phase == 0) begin
                xout_re  <= diff_re;
                xout_im  <= diff_im;
                valid_out <= 1;

                delay_re <= xin_re;
                delay_im <= xin_im;
            end
            // ---------- SUM + DIFF COMPUTE ----------
            else begin
                xout_re  <= delay_re + xin_re;
                xout_im  <= delay_im + xin_im;
                valid_out <= 1;

                d_re = delay_re - xin_re;
                d_im = delay_im - xin_im;

                case (tw_idx)
                    // W0
                    2'd0: begin
                        diff_re <= d_re[15:0];
                        diff_im <= d_im[15:0];
                    end
                    // W1 ? (1 - j)/?2
                    2'd1: begin
                        t1 = d_re + d_im;
                        t2 = d_im - d_re;
                        diff_re <= (t1 >>> 1) + (t1 >>> 2);
                        diff_im <= (t2 >>> 1) + (t2 >>> 2);
                    end
                    // W2 = -j
                    2'd2: begin
                        diff_re <=  d_im;
                        diff_im <= -d_re;
                    end
                    // W3 = -(1 + j)/?2
                    2'd3: begin
                        t1 = -(d_re - d_im);
                        t2 = -(d_re + d_im);
                        diff_re <= (t1 >>> 1) + (t1 >>> 2);
                        diff_im <= (t2 >>> 1) + (t2 >>> 2);
                   end 

                endcase

                tw_idx <= tw_idx + 1'b1; // advance butterfly
            end

            phase <= ~phase;
        end
    end

endmodule
