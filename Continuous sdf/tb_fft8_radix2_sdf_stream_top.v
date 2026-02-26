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
 // Clock
 always #5 clk = ~clk;
 task apply_input(input signed [15:0] re, input signed [15:0] im);
 begin
 @(posedge clk);
 valid_in = 1;
 xin_re = re;
 xin_im = im;
  end
 endtask
 integer i;
 initial begin
 clk = 0;
 valid_in = 0;
 xin_re = 0;
 xin_im = 0;
 // Real inputs
 apply_input(1,0);
 apply_input(2,0);
 apply_input(3,0);
 apply_input(4,0);
 apply_input(5,0);
 apply_input(6,0);
 apply_input(7,0);
 apply_input(8,0);
 apply_input(1,0);
 apply_input(1,0);
 apply_input(1,0);
 apply_input(1,0);
 apply_input(1,0);
 apply_input(1,0);
 apply_input(1,0);
 apply_input(1,0);
 // Complex inputs
 apply_input(2,1);
 apply_input(-1,3);
 apply_input(4,-2);
 apply_input(0,1);
 apply_input(-3,0);
 apply_input(1,-4);
 apply_input(-2,2);
 apply_input(3,-1);

 // Real inputs
 apply_input(4,0);
 apply_input(4,0);
 apply_input(4,0);
 apply_input(4,0);
 apply_input(4,0);
 apply_input(4,0);
 apply_input(4,0);
 apply_input(4,0);
 // Flush pipeline
 for (i = 0; i < 20; i = i + 1)
 apply_input(0,0);
 #200 $finish;
 end
endmodule