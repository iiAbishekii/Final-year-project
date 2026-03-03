
module tb_fft8_dif_sdf;
// -------------------------------
// DUT signals
// -------------------------------
reg clk;
reg valid_in;
reg signed [15:0] xin_re;
reg signed [15:0] xin_im;
wire signed [15:0] xout_re;
wire signed [15:0] xout_im;
wire valid_out;
// -------------------------------
// Instantiate DUT
// -------------------------------
fft8_dif_sdf dut (
.clk (clk),
.valid_in (valid_in),
.xin_re (xin_re),
.xin_im (xin_im),
.xout_re (xout_re),
.xout_im (xout_im),
.valid_out (valid_out)
);
// -------------------------------
// Clock generation (10 ns period)
// -------------------------------
initial begin
clk = 0;
forever #5 clk = ~clk;
end
// -------------------------------
// Stimulus
// -------------------------------
initial begin
// INIT
valid_in = 0;
xin_re = 0;
xin_im = 0;
// Wait for a clean edge
@(posedge clk);
// Start streaming
valid_in = 1;
// Sample Input Stream (one sample per clock)
xin_re = 16'sd2; xin_im = 16'sd1; @(posedge clk); // 2 + j1
xin_re = -16'sd1; xin_im = 16'sd3; @(posedge clk); // -1 + j3
xin_re = 16'sd4; xin_im = -16'sd2; @(posedge clk); // 4 - j2
xin_re = 16'sd0; xin_im = 16'sd1; @(posedge clk); // 0 + j1
xin_re = -16'sd3; xin_im = 16'sd0; @(posedge clk); // -3 + j0
xin_re = 16'sd1; xin_im = -16'sd4; @(posedge clk); // 1 - j4
xin_re = -16'sd2; xin_im = 16'sd2; @(posedge clk); // -2 + j2
xin_re = 16'sd3; xin_im = -16'sd1; @(posedge clk); // 3 - j1
// Stop input stream
valid_in = 0;
xin_re = 0;
xin_im = 0;
// Let pipeline flush
repeat (40) @(posedge clk);
$finish;
end
// -------------------------------
// Monitor (very useful for debug)
// -------------------------------
initial begin
$display("TIME | vin | xin_re | xin_im || vout | xout_re | xout_im");
$monitor("%4t | %b | %6d | %6d || %b | %7d | %7d",
$time, valid_in, xin_re, xin_im,
valid_out, xout_re, xout_im);
end
endmodule
