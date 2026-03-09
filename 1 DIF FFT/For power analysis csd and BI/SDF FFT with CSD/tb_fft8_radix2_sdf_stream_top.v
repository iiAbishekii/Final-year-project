// ============================================================
// Module : tb_fft8_radix2_sdf_stream_top
// Description : Testbench for fft8_radix2_sdf_stream_top
//               with CSD twiddle multiplier in Stage 3.
//
// Input sequences (identical to original PDF testbench):
//   SEQ1: Real ramp    re=[1..8],  im=0
//   SEQ2: Zeros        re=0,       im=0  x8
//   SEQ3: Real ones    re=1,       im=0  x8
//   SEQ4: Complex      re=[2,-1,4,0,-3,1,-2,3], im=[1,3,-2,1,0,-4,2,-1]
//   SEQ5: Real const   re=4,       im=0  x8
//   Flush: zeros x20
//
// Expected outputs (CSD approximates 1/sqrt(2) to 0.011% error):
//   SEQ1: X[0]=36+j0, X[1]=-4+j10, X[2]=-4+j4,  X[3]=-4+j2
//         X[4]=-4+j0, X[5]=-4-j2,  X[6]=-4-j4,  X[7]=-4-j10
//   SEQ2: all zero
//   SEQ3: X[0]=8+j0,  X[1..7]=0
//   SEQ4: X[0]=4+j0,  X[1]=8+j2,  X[2]=-4+j4, X[3]=15+j7
//         X[4]=-2+j2, X[5]=-6-j12,X[6]=-2-j2, X[7]=3+j7
//   SEQ5: X[0]=32+j0, X[1..7]=0
//
// Note: W1/W3 bins (X[1],X[3],X[5],X[7]) use CSD - results
//       match expected to within ±1 LSB (0.011% approximation)
// ============================================================
`timescale 1ns/1ps

module tb_fft8_radix2_sdf_stream_top;

    reg        clk;
    reg        valid_in;
    reg  signed [15:0] xin_re, xin_im;
    wire signed [15:0] xout_re, xout_im;
    wire        valid_out;

    // DUT
    fft8_radix2_sdf_stream_top DUT (
        .clk      (clk),
        .valid_in (valid_in),
        .xin_re   (xin_re),
        .xin_im   (xin_im),
        .xout_re  (xout_re),
        .xout_im  (xout_im),
        .valid_out(valid_out)
    );

    // Clock: 10 ns period
    always #5 clk = ~clk;

    // Task: apply one sample on next posedge
    task apply_input;
        input signed [15:0] re;
        input signed [15:0] im;
        begin
            @(posedge clk);
            valid_in = 1;
            xin_re   = re;
            xin_im   = im;
        end
    endtask

    // Output monitor
    integer out_count;
    always @(posedge clk) begin
        if (valid_out) begin
            $display("OUT[%02d]  re=%6d  im=%6d", out_count, xout_re, xout_im);
            out_count = out_count + 1;
        end
    end

    integer i;

    initial begin
        clk       = 0;
        valid_in  = 0;
        xin_re    = 0;
        xin_im    = 0;
        out_count = 0;

        @(posedge clk); #1;

        $display("====================================================");
        $display(" FFT8 Radix-2 SDF + CSD Twiddle Multiplier");
        $display("====================================================");

        // ---- SEQ1: Real ramp 1..8 ----
        $display("\n--- SEQ1: Real ramp re=[1..8], im=0 ---");
        $display("    Expected: X[0]=36,  X[1]=-4+j10, X[2]=-4+j4,  X[3]=-4+j2");
        $display("              X[4]=-4,  X[5]=-4-j2,  X[6]=-4-j4,  X[7]=-4-j10");
        apply_input( 1, 0); apply_input( 2, 0);
        apply_input( 3, 0); apply_input( 4, 0);
        apply_input( 5, 0); apply_input( 6, 0);
        apply_input( 7, 0); apply_input( 8, 0);

        // ---- SEQ2: Zeros x8 ----
        $display("\n--- SEQ2: Zeros x8 ---");
        $display("    Expected: all zero");
        repeat(8) apply_input(0, 0);

        // ---- SEQ3: Real ones x8 ----
        $display("\n--- SEQ3: Real ones x8 ---");
        $display("    Expected: X[0]=8, X[1..7]=0");
        repeat(8) apply_input(1, 0);

        // ---- SEQ4: Complex mixed ----
        $display("\n--- SEQ4: Complex mixed ---");
        $display("    Expected: X[0]=4+j0,  X[1]=8+j2,   X[2]=-4+j4, X[3]=15+j7");
        $display("              X[4]=-2+j2, X[5]=-6-j12, X[6]=-2-j2, X[7]=3+j7");
        apply_input( 2,  1); apply_input(-1,  3);
        apply_input( 4, -2); apply_input( 0,  1);
        apply_input(-3,  0); apply_input( 1, -4);
        apply_input(-2,  2); apply_input( 3, -1);

        // ---- SEQ5: Real constant 4 ----
        $display("\n--- SEQ5: Real const re=4, im=0 x8 ---");
        $display("    Expected: X[0]=32, X[1..7]=0");
        repeat(8) apply_input(4, 0);

        // ---- Pipeline flush ----
        $display("\n--- Flush ---");
        valid_in = 1;
        for (i = 0; i < 20; i = i + 1)
            apply_input(0, 0);
        valid_in = 0;

        #200;
        $display("\n====================================================");
        $display(" Total outputs: %0d", out_count);
        $display("====================================================");
        $finish;
    end

    // Waveform dump
    initial begin
        $dumpfile("fft8_csd.vcd");
        $dumpvars(0, tb_fft8_radix2_sdf_stream_top);
    end

endmodule