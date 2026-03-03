module tb_fft8_radix2_sdf_stream_top;
 reg clk;
 reg valid_in;
 reg signed [15:0] xin_re, xin_im;
 wire signed [15:0] xout_re, xout_im;
 wire valid_out;
 // =================================================
 // DUT
 // =================================================
 fft8_radix2_sdf_stream_top DUT (
 .clk (clk),
 .valid_in (valid_in),
 .xin_re (xin_re),
 .xin_im (xin_im),
 .xout_re (xout_re),
 .xout_im (xout_im),
 .valid_out (valid_out)
 );
 // =================================================
 // Clock generation (100 MHz)
 // =================================================
 always #5 clk = ~clk;
 // =================================================
 // Stimulus
 // =================================================
 initial begin
 clk = 0;
 valid_in = 0;
 xin_re = 0;
 xin_im = 0;
 // -----------------------------
 // Start streaming
 // -----------------------------
 @(posedge clk);
 valid_in = 1;
 // -------- Input samples --------
 xin_re = 1; xin_im = 0; @(posedge clk);
 xin_re = 2; xin_im = 0; @(posedge clk);
 xin_re = 3; xin_im = 0; @(posedge clk);
 xin_re = 4; xin_im = 0; @(posedge clk);
 xin_re = 5; xin_im = 0; @(posedge clk);
 xin_re = 6; xin_im = 0; @(posedge clk);
 xin_re = 7; xin_im = 0; @(posedge clk);
 xin_re = 8; xin_im = 0; @(posedge clk);
 // -----------------------------
 // Stop input stream
 // -----------------------------
 valid_in = 0;
 // Let pipeline drain
 repeat (40) @(posedge clk);

 $finish;
 end
 // =================================================
 // DEBUG: INPUT MONITOR
 // =================================================
 always @(posedge clk) begin
 if (valid_in) begin

 end
 end
 // =================================================
 // DEBUG: FINAL FFT OUTPUT MONITOR
 // =================================================
 integer out_count = 0;
 always @(posedge clk) begin
 if (valid_out) begin
 out_count = out_count + 1;

 end
 end
endmodule