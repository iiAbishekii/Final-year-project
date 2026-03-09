// ============================================================
// Module  : stage3_radix2_sdf_stream
// Project : Optimization of FFT Processor
//
// Description:
//   Radix-2 SDF DIF butterfly, Stage 3. Delay = 1.
//   Four twiddle factors applied in rotation (tw_idx 0?3):
//     W^0 =  1            pass-through
//     W^1 = (1-j)/?2     CSD multiply
//     W^2 = -j            swap + negate
//     W^3 = -(1+j)/?2    CSD multiply
//
// ?????????????????????????????????????????????????????????????
// HIERARCHY
// ?????????????????????????????????????????????????????????????
//   DEC_RE  : bit_inv_decoder    BIC decode, real channel
//   DEC_IM  : bit_inv_decoder    BIC decode, imag channel
//   CSD_T1  : csd_sqrt2_inv      computes (d_re+d_im)/?2  ? W^1 re
//   CSD_T2A : csd_sqrt2_inv      computes (d_im-d_re)/?2  ? W^1 im
//   CSD_T2B : csd_sqrt2_inv      computes (d_im-d_re)/?2  ? W^3 re
//   CSD_T3  : csd_sqrt2_inv      computes -(d_re+d_im)/?2 ? W^3 im
//
// ?????????????????????????????????????????????????????????????
// CSD INSTANCE TIMING - HOW IT WORKS
// ?????????????????????????????????????????????????????????????
//   The CSD instances are driven by REGISTERED twiddle inputs:
//   t1_reg, t2_reg, t3_reg.  These registers are written (NBA <=)
//   during the sum_phase.  By the NEXT posedge (store_phase),
//   the registers are stable and the CSD combinational outputs
//   (csd_t1, csd_t2a, csd_t2b, csd_t3) are fully settled.
//
//   In store_phase, when a CSD twiddle is needed (tw_prev=1 or 3),
//   xout_re and xout_im are driven DIRECTLY from the CSD instance
//   output wires - not from a diff_re intermediate register.
//   This avoids any need to write and read diff_re in the same cycle.
//
//   Timeline for W^1 butterfly:
//     Cycle T   sum_phase:    d_re,d_im computed (blocking=)
//                             t1_reg <= d_re+d_im   (NBA)
//                             t2_reg <= d_im-d_re   (NBA)
//                             tw_prev <= 1'b1       (NBA)
//     Cycle T+1 store_phase:  t1_reg, t2_reg are stable
//                             csd_t1 = csd(t1_reg)  wire, valid now
//                             csd_t2a= csd(t2_reg)  wire, valid now
//                             xout_re <= csd_t1     (NBA) ?
//                             xout_im <= csd_t2a    (NBA) ?
//
//   For W^0 and W^2 (no CSD), diff_re/diff_im are written in sum_phase
//   and read in the following store_phase as usual.
// ============================================================
module stage3_radix2_sdf_stream (
    input  wire        clk,
    input  wire        valid_in,
    input  wire signed [15:0] xin_re,
    input  wire signed [15:0] xin_im,
    input  wire               inv_flag_re,
    input  wire               inv_flag_im,
    output reg  signed [15:0] xout_re,
    output reg  signed [15:0] xout_im,
    output reg                valid_out
);

    // ?? BIC Decoders ?????????????????????????????????????????
    wire signed [15:0] dec_re, dec_im;

    bit_inv_decoder DEC_RE (.in(xin_re), .inv_flag(inv_flag_re), .out(dec_re));
    bit_inv_decoder DEC_IM (.in(xin_im), .inv_flag(inv_flag_im), .out(dec_im));

    // ?? Registered twiddle inputs for CSD instances ??????????
    // Written in sum_phase (NBA <=), stable by next store_phase.
    reg signed [17:0] t1_reg, t2_reg, t3_reg;

    // ?? CSD instances - driven by stable registered inputs ???
    wire signed [15:0] csd_t1;    // CSD(t1_reg) = CSD(d_re+d_im)
    wire signed [15:0] csd_t2a;   // CSD(t2_reg) = CSD(d_im-d_re)  [W^1 im]
    wire signed [15:0] csd_t2b;   // CSD(t2_reg) = CSD(d_im-d_re)  [W^3 re]
    wire signed [15:0] csd_t3;    // CSD(t3_reg) = CSD(-(d_re+d_im))

    csd_sqrt2_inv CSD_T1  (.in(t1_reg), .out(csd_t1));
    csd_sqrt2_inv CSD_T2A (.in(t2_reg), .out(csd_t2a));
    csd_sqrt2_inv CSD_T2B (.in(t2_reg), .out(csd_t2b));
    csd_sqrt2_inv CSD_T3  (.in(t3_reg), .out(csd_t3));

    // ?? Butterfly state ???????????????????????????????????????
    reg signed [15:0] delay_re, delay_im;
    reg signed [15:0] diff_re,  diff_im;   // used for W^0 and W^2
    reg               phase;
    reg [1:0]         tw_idx;
    reg [1:0]         tw_prev;  // twiddle index used in previous sum_phase

    // Blocking temporaries (intra-cycle, not registers)
    reg signed [16:0] d_re, d_im;

    initial begin
        phase = 0; tw_idx = 0; tw_prev = 0; valid_out = 0;
        t1_reg = 0; t2_reg = 0; t3_reg = 0;
        delay_re = 0; delay_im = 0;
        diff_re  = 0; diff_im  = 0;
    end

    always @(posedge clk) begin
        valid_out <= 0;

        if (valid_in) begin

            // Sign-extend butterfly difference to 17 bits (blocking=)
            d_re = {delay_re[15], delay_re} - {dec_re[15], dec_re};
            d_im = {delay_im[15], delay_im} - {dec_im[15], dec_im};

            // ?? STORE PHASE ??????????????????????????????????
            // Emit twiddle-multiplied difference from last sum_phase.
            // For W^1/W^3: read directly from CSD instance outputs
            //              (csd_t1/t2a/t2b/t3 are valid - t_regs stable).
            // For W^0/W^2: read from diff_re/diff_im (set last sum_phase).
            if (phase == 1'b0) begin
                case (tw_prev)
                    2'd0: begin xout_re <= diff_re;  xout_im <= diff_im;  end
                    2'd1: begin xout_re <= csd_t1;   xout_im <= csd_t2a;  end
                    2'd2: begin xout_re <= diff_re;  xout_im <= diff_im;  end
                    2'd3: begin xout_re <= csd_t2b;  xout_im <= csd_t3;   end
                endcase
                valid_out <= 1;
                delay_re  <= dec_re;
                delay_im  <= dec_im;
            end

            // ?? SUM PHASE ????????????????????????????????????
            // Emit butterfly sum. Compute and register twiddle terms.
            else begin
                xout_re   <= delay_re + dec_re;
                xout_im   <= delay_im + dec_im;
                valid_out <= 1;

                // Capture which twiddle this sum_phase uses
                tw_prev <= tw_idx;

                case (tw_idx)
                    // W^0 = 1 : store raw difference
                    2'd0: begin
                        diff_re <= d_re[15:0];
                        diff_im <= d_im[15:0];
                    end
                    // W^1 = (1-j)/?2 : register t1, t2 for CSD instances
                    2'd1: begin
                        t1_reg <= {d_re[16], d_re} + {d_im[16], d_im};
                        t2_reg <= {d_im[16], d_im} - {d_re[16], d_re};
                    end
                    // W^2 = -j : store rotated difference
                    2'd2: begin
                        diff_re <=  d_im[15:0];
                        diff_im <= -d_re[15:0];
                    end
                    // W^3 = -(1+j)/?2 : register t2, t3 for CSD instances
                    2'd3: begin
                        t2_reg <= {d_im[16], d_im} - {d_re[16], d_re};
                        t3_reg <= -({d_re[16], d_re} + {d_im[16], d_im});
                    end
                endcase

                tw_idx <= tw_idx + 2'd1;
            end

            phase <= ~phase;
        end
    end

endmodule