module tb_fft8_radix2_sdf_stream_top;
 reg clk;
 reg valid_in;
 reg signed [15:0] xin_re, xin_im;
 wire signed [15:0] xout_re, xout_im;
 wire valid_out;
 fft8_radix2_sdf_stream_top DUT (
 .clk (clk),
 .valid_in (valid_in),
 .xin_re (xin_re),
 .xin_im (xin_im),
 .xout_re (xout_re),
 .xout_im (xout_im),
 .valid_out (valid_out)
 );
 always #5 clk = ~clk;
 initial begin
 clk = 0;
 valid_in = 0;
 xin_re = 0;
 xin_im = 0;
 @(posedge clk);
 valid_in = 1;
 // ===== RAW TIME-DOMAIN INPUT =====
// [3 -2 5 1 -4 7 -6 2]
// [(3+2j) (-1+4j) (5-3j) (2+1j) (-4+2j) (6-1j) (-2-5j) (1+3j)]
xin_re = 3; xin_im = 2; @(posedge clk);
xin_re = -1; xin_im = 4; @(posedge clk);
xin_re = 5; xin_im = -3; @(posedge clk);
xin_re = 2; xin_im = 1; @(posedge clk);
xin_re = -4; xin_im = 2; @(posedge clk);
xin_re = 6; xin_im = -1; @(posedge clk);
xin_re = -2; xin_im = -5; @(posedge clk);
xin_re = 1; xin_im = 3; @(posedge clk);
 valid_in = 0;
 repeat (120) @(posedge clk);
 $finish;
 end
 always @(posedge clk)
 if (valid_out)
 $display("FINAL STREAM FFT OUT -> (%0d,%0d)", xout_re, xout_im);
endmodule