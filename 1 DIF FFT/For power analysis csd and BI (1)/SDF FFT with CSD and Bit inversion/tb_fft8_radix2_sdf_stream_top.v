// ============================================================
// tb_fft8_radix2_sdf_stream_top  - self-checking, 5 sequences
// Inputs applied at posedge (blocking =).
// DUT registered input stage clocks them in cleanly.
// Monitor at negedge reads stable post-NBA values.
// ============================================================
`timescale 1ns/1ps
module tb_fft8_radix2_sdf_stream_top;

    reg        clk;
    reg        valid_in;
    reg  signed [15:0] xin_re, xin_im;
    wire signed [15:0] xout_re, xout_im;
    wire        valid_out;

    fft8_radix2_sdf_stream_top DUT (
        .clk(clk), .valid_in(valid_in),
        .xin_re(xin_re), .xin_im(xin_im),
        .xout_re(xout_re), .xout_im(xout_im),
        .valid_out(valid_out)
    );

    always #5 clk = ~clk;

    // ----------------------------------------------------------
    // Output checker - at negedge (stable values)
    // ----------------------------------------------------------
    integer out_cnt, pass_cnt, fail_cnt;
    reg signed [15:0] exp_re [0:55];
    reg signed [15:0] exp_im [0:55];

    task init_expected;
        integer k;
        begin
            for (k=0; k<56; k=k+1) begin exp_re[k]=0; exp_im[k]=0; end
            // SEQ1: re=[1..8]
            exp_re[1]=36;   exp_im[1]=0;
            exp_re[2]=-4;   exp_im[2]=0;
            exp_re[3]=-4;   exp_im[3]=4;
            exp_re[4]=-8;   exp_im[4]=0;
            exp_re[5]=-16;  exp_im[5]=0;
            // [6..16] = 0
            // SEQ3: re=1 x8 ? X[0]=8
            exp_re[17]=8;   exp_im[17]=0;
            // [18..24] = 0
            // SEQ4
            exp_re[25]=4;   exp_im[25]=0;
            exp_re[26]=-2;  exp_im[26]=2;
            exp_re[27]=-4;  exp_im[27]=4;
            exp_re[28]=-6;  exp_im[28]=0;
            exp_re[29]=6;   exp_im[29]=6;
            exp_re[30]=-12; exp_im[30]=-16;
            exp_re[31]=4;   exp_im[31]=4;
            // SEQ5: re=4 x8 ? X[0]=32, X[1]=CSD approx
            exp_re[32]=7;   exp_im[32]=0;
            exp_re[33]=32;  exp_im[33]=0;
            // [34..55] = 0
        end
    endtask

    always @(negedge clk) begin
        if (valid_out) begin
            if (out_cnt < 56) begin
                if (xout_re === exp_re[out_cnt] &&
                    xout_im === exp_im[out_cnt]) begin
                    $display("[OUT%02d] re=%5d im=%5d  PASS",
                        out_cnt, xout_re, xout_im);
                    pass_cnt = pass_cnt + 1;
                end else begin
                    $display("[OUT%02d] re=%5d im=%5d  FAIL (exp re=%5d im=%5d)",
                        out_cnt, xout_re, xout_im,
                        exp_re[out_cnt], exp_im[out_cnt]);
                    fail_cnt = fail_cnt + 1;
                end
            end else begin
                if (xout_re !== 16'sd0 || xout_im !== 16'sd0) begin
                    $display("[OUT%02d] re=%5d im=%5d  FAIL (exp zero)",
                        out_cnt, xout_re, xout_im);
                    fail_cnt = fail_cnt + 1;
                end else begin
                    $display("[OUT%02d] re=%5d im=%5d  PASS",
                        out_cnt, xout_re, xout_im);
                    pass_cnt = pass_cnt + 1;
                end
            end
            out_cnt = out_cnt + 1;
        end
    end

    // ----------------------------------------------------------
    // Input driver - apply at posedge (DUT input_reg clocks it in)
    // ----------------------------------------------------------
    task apply;
        input signed [15:0] re, im;
        begin
            @(posedge clk);
            valid_in = 1; xin_re = re; xin_im = im;
        end
    endtask

    integer i;
    initial begin
        clk=0; valid_in=0; xin_re=0; xin_im=0;
        out_cnt=0; pass_cnt=0; fail_cnt=0;
        init_expected;

        @(posedge clk);
        $display("=========================================");
        $display("  FFT8 SDF + CSD + Bit Inversion TB");
        $display("=========================================");

        // SEQ1
        $display("--- SEQ1: re=[1..8] ---");
        for (i=1; i<=8; i=i+1) apply(i, 0);

        // SEQ2
        $display("--- SEQ2: zeros x8 ---");
        for (i=0; i<8; i=i+1) apply(0, 0);

        // SEQ3
        $display("--- SEQ3: re=1 x8 ---");
        for (i=0; i<8; i=i+1) apply(1, 0);

        // SEQ4
        $display("--- SEQ4: complex ---");
        apply( 2, 1); apply(-1, 3); apply( 4,-2); apply( 0, 1);
        apply(-3, 0); apply( 1,-4); apply(-2, 2); apply( 3,-1);

        // SEQ5
        $display("--- SEQ5: re=4 x8 ---");
        for (i=0; i<8; i=i+1) apply(4, 0);

        // Flush
        $display("--- Flush: zeros x22 ---");
        for (i=0; i<22; i=i+1) apply(0, 0);

        @(posedge clk); valid_in=0;
        repeat(15) @(posedge clk);

        $display("=========================================");
        $display("  Outputs: %0d  PASS: %0d  FAIL: %0d",
            out_cnt, pass_cnt, fail_cnt);
        $display("  STATUS: %s",
            (fail_cnt==0) ? "ALL PASS" : "FAILURES DETECTED");
        $display("=========================================");
        $finish;
    end

endmodule