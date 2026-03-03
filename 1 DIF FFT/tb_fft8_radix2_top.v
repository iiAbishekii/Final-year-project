`timescale 1ns/1ps
module tb_fft8_radix2_top;
 // ---------------- Clock ----------------
 reg clk;
 always #5 clk = ~clk;
 // ---------------- Inputs ----------------
 reg signed [15:0] xin_re;
 reg signed [15:0] xin_im;
 // ---------------- Outputs ----------------
 wire signed [15:0] xout_re;
 wire signed [15:0] xout_im;
 wire valid;
 integer cycle;
 integer i;
 // ---------------- DUT ----------------
 fft8_radix2_top DUT (
 .clk(clk),
 .xin_re(xin_re),
 .xin_im(xin_im),
 .xout_re(xout_re),
 .xout_im(xout_im),
 .valid(valid)
 );
 // ---------------- Cycle counter ----------------
 always @(posedge clk)
 cycle <= cycle + 1;
 // ---------------- Stimulus ----------------
 initial begin
 clk = 0;
 cycle = 0;
 xin_re = 0;
 xin_im = 0;
 @(posedge clk);
 // ================= TESTCASE =================
 // Real and Imag inputs:

 xin_re = 4; xin_im = 0; @(posedge clk);
 xin_re = 4; xin_im = 0; @(posedge clk);
 xin_re = 4; xin_im = 0; @(posedge clk);
 xin_re = 4; xin_im = 0; @(posedge clk);
 xin_re = 4; xin_im = 0; @(posedge clk);
 xin_re = 4; xin_im = 0; @(posedge clk);
 xin_re = 4; xin_im = 0; @(posedge clk);
 xin_re = 4; xin_im = 0; @(posedge clk);
 // Clear input (important for clean frame boundary)
 xin_re = 0;
 xin_im = 0;
 // Allow FFT to complete
 repeat (50) @(posedge clk);
 $finish;
 end
 // ---------------- Output monitor ----------------
 always @(posedge clk) begin
 if (valid) begin
 $display("CYCLE %0d | FFT OUT re=%0d im=%0d",
 cycle, xout_re, xout_im);
 end
 end
endmodule