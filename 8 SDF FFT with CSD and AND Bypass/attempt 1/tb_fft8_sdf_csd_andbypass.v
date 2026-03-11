`timescale 1ns/1ps
module tb_fft8_sdf_csd_andbypass;

    reg                  clk;
    reg                  valid_in;
    reg  signed [15:0]   xin_re, xin_im;
    wire signed [15:0]   xout_re, xout_im;
    wire                 valid_out;

    fft8_sdf_csd_andbypass_top DUT (
        .clk(clk), .valid_in(valid_in),
        .xin_re(xin_re), .xin_im(xin_im),
        .xout_re(xout_re), .xout_im(xout_im),
        .valid_out(valid_out)
    );

    initial clk = 0;
    always  #5 clk = ~clk;

    integer out_cnt, pass_cnt, fail_cnt;

    reg signed [15:0] exp_re [0:55];
    reg signed [15:0] exp_im [0:55];

    task init_expected;
        integer k;
        begin
            for (k = 0; k < 56; k = k + 1) begin
                exp_re[k] = 0; exp_im[k] = 0;
            end
            exp_re[ 1] =  36; exp_im[ 1] =   0;
            exp_re[ 2] =  -4; exp_im[ 2] =   0;
            exp_re[ 3] =  -4; exp_im[ 3] =   4;
            exp_re[ 4] =  -8; exp_im[ 4] =   0;
            exp_re[ 5] = -16; exp_im[ 5] =   0;
            exp_re[17] =   8; exp_im[17] =   0;
            exp_re[25] =   4; exp_im[25] =   0;
            exp_re[26] =  -2; exp_im[26] =   2;
            exp_re[27] =  -4; exp_im[27] =   4;
            exp_re[28] =  -6; exp_im[28] =   0;
            exp_re[29] =   6; exp_im[29] =   6;
            exp_re[30] = -12; exp_im[30] = -16;
            exp_re[31] =   4; exp_im[31] =   4;
            exp_re[32] =   7; exp_im[32] =   0;
            exp_re[33] =  32; exp_im[33] =   0;
        end
    endtask

    always @(negedge clk) begin
        if (valid_out) begin
            if (out_cnt < 56) begin
                if (xout_re === exp_re[out_cnt] &&
                    xout_im === exp_im[out_cnt]) begin
                    $display("[OUT%02d] re=%6d  im=%6d  PASS",
                        out_cnt, xout_re, xout_im);
                    pass_cnt = pass_cnt + 1;
                end else begin
                    $display("[OUT%02d] re=%6d  im=%6d  FAIL (exp re=%6d im=%6d)",
                        out_cnt, xout_re, xout_im,
                        exp_re[out_cnt], exp_im[out_cnt]);
                    fail_cnt = fail_cnt + 1;
                end
            end else begin
                if (xout_re !== 16'sd0 || xout_im !== 16'sd0) begin
                    $display("[OUT%02d] re=%6d  im=%6d  FAIL (exp zero)",
                        out_cnt, xout_re, xout_im);
                    fail_cnt = fail_cnt + 1;
                end else begin
                    $display("[OUT%02d] re=%6d  im=%6d  PASS",
                        out_cnt, xout_re, xout_im);
                    pass_cnt = pass_cnt + 1;
                end
            end
            out_cnt = out_cnt + 1;
        end
    end

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

        $display("=====================================================");
        $display("  FFT8 SDF + CSD + AND-Gate Bypass TB");
        $display("=====================================================");

        $display("--- SEQ1: re=[1..8] ---");
        for (i=1; i<=8; i=i+1) apply(i, 0);

        $display("--- SEQ2: zeros x8 ---");
        for (i=0; i<8; i=i+1) apply(0, 0);

        $display("--- SEQ3: re=1 x8 ---");
        for (i=0; i<8; i=i+1) apply(1, 0);

        $display("--- SEQ4: complex ---");
        apply( 2, 1); apply(-1, 3); apply( 4,-2); apply(0, 1);
        apply(-3, 0); apply( 1,-4); apply(-2, 2); apply(3,-1);

        $display("--- SEQ5: re=4 x8 ---");
        for (i=0; i<8; i=i+1) apply(4, 0);

        $display("--- Flush: zeros x22 ---");
        for (i=0; i<22; i=i+1) apply(0, 0);

        @(posedge clk); valid_in = 0;
        repeat(15) @(posedge clk);

        $display("=====================================================");
        $display("  Outputs: %0d  PASS: %0d  FAIL: %0d",
            out_cnt, pass_cnt, fail_cnt);
        $display("  STATUS: %s",
            (fail_cnt==0) ? "ALL PASS" : "FAILURES DETECTED");
        $display("=====================================================");
        $finish;
    end

endmodule