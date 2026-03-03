module stage3_radix2_sdf_stream (
 input wire clk,
 input wire valid_in,
 input wire signed [15:0] xin_re,
 input wire signed [15:0] xin_im,
 output reg signed [15:0] xout_re,
 output reg signed [15:0] xout_im,
 output reg valid_out
);
 // W8 = exp(-j*pi/4)
 localparam signed [15:0] C = 16'sd23170;
 // -----------------------------
 // Delay = 1
 // -----------------------------
 reg signed [15:0] d_re, d_im;
 // -----------------------------
 // Stored DIFF (for next cycle)
 // -----------------------------
 reg signed [15:0] diff_re, diff_im;
 reg diff_valid;
 // -----------------------------
 // Control
 // -----------------------------
 reg phase; // 0 = STORE, 1 = COMPUTE
 reg [1:0] tw_cnt; // twiddle index 0..3
 // Temps
 reg signed [31:0] mul1, mul2;
 reg signed [15:0] dr, di;
 initial begin
 d_re = 0;
 d_im = 0;
 diff_re = 0;
 diff_im = 0;
 diff_valid = 0;
 phase = 0;
 tw_cnt = 0;
 valid_out = 0;
 end
 always @(posedge clk) begin
 valid_out <= 1'b0;
 // =================================================
 // OUTPUT PATH (DIFF has priority to avoid bubbles)
 // =================================================
 if (diff_valid) begin
 xout_re <= diff_re;
 xout_im <= diff_im;
 valid_out <= 1'b1;
  diff_valid <= 1'b0;
 end
 // =================================================
 // INPUT / BUTTERFLY
 // =================================================
 if (valid_in) begin
 if (!phase) begin
 // ---------------- STORE ----------------
 d_re <= xin_re;
 d_im <= xin_im;
 phase <= 1'b1;
  end
 else begin
 // ---------------- COMPUTE ----------------
 // SUM (output immediately)
 xout_re <= d_re + xin_re;
 xout_im <= d_im + xin_im;
 valid_out <= 1'b1;
 // DIFF base
 dr = d_re - xin_re;
 di = d_im - xin_im;
 // Apply correct twiddle
 case (tw_cnt)
 // k = 0 : 1
 2'd0: begin
 diff_re <= dr;
 diff_im <= di;
 end
 // k = 1 : exp(-j*pi/4)
 2'd1: begin
 mul1 = C * (dr + di);
 mul2 = C * (di - dr);
 diff_re <= mul1 >>> 15;
 diff_im <= mul2 >>> 15;
 end
 // k = 2 : -j
 2'd2: begin
 diff_re <= di;
 diff_im <= -dr;
 end
 // k = 3 : -exp(-j*pi/4)
 2'd3: begin
 mul1 = -C * (dr - di);
 mul2 = -C * (dr + di);
 diff_re <= mul1 >>> 15;
 diff_im <= mul2 >>> 15;
 end
 endcase
 diff_valid <= 1'b1;
 tw_cnt <= tw_cnt + 1'b1;
 phase <= 1'b0;
 end
 end
 end
endmodule
