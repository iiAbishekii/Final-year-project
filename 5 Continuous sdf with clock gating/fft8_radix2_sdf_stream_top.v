module fft8_radix2_sdf_stream_top (
    input  wire              clk,
    input  wire              valid_in,
    input  wire signed [15:0] xin_re,
    input  wire signed [15:0] xin_im,
    output wire signed [15:0] xout_re,
    output wire signed [15:0] xout_im,
    output wire              valid_out
);

    // ======================================================
    // Stage outputs
    // ======================================================
    wire signed [15:0] s1_re, s1_im;
    wire               s1_valid;

    wire signed [15:0] s2_re, s2_im;
    wire               s2_valid;

    wire signed [15:0] s3_re, s3_im;
    wire               s3_valid;

    // ======================================================
    // Inter-stage registers
    // ======================================================
    reg signed [15:0] s12_re, s12_im;
    reg               s12_valid;

    reg signed [15:0] s23_re, s23_im;
    reg               s23_valid;

    // ======================================================
    // Warm-up counters
    // ======================================================
    reg [2:0] s1_warmup_cnt;  // drop first 4
    reg [1:0] s2_warmup_cnt;  // drop first 2

    // ======================================================
    // Stage-1
    // ======================================================
    stage1_radix2_sdf STAGE1 (
        .clk       (clk),
        .valid_in  (valid_in),
        .xin_re    (xin_re),
        .xin_im    (xin_im),
        .xout_re   (s1_re),
        .xout_im   (s1_im),
        .valid_out (s1_valid)
    );

    // ======================================================
    // Stage-1 ? Stage-2 (Warmup Drop 4)
    // ======================================================
    always @(posedge clk) begin
        s12_valid <= 0;

        if (s1_valid) begin
            if (s1_warmup_cnt < 4) begin
                s1_warmup_cnt <= s1_warmup_cnt + 1;
            end
            else begin
                s12_re    <= s1_re;
                s12_im    <= s1_im;
                s12_valid <= 1;
            end
        end
    end

    // ======================================================
    // Stage-2
    // ======================================================
    stage2_radix2_sdf_stream STAGE2 (
        .clk       (clk),
        .valid_in  (s12_valid),
        .xin_re    (s12_re),
        .xin_im    (s12_im),
        .xout_re   (s2_re),
        .xout_im   (s2_im),
        .valid_out (s2_valid)
    );

    // ======================================================
    // Stage-2 ? Stage-3 (Warmup Drop 2)
    // ======================================================
    always @(posedge clk) begin
        s23_valid <= 0;

        if (s2_valid) begin
            if (s2_warmup_cnt < 2) begin
                s2_warmup_cnt <= s2_warmup_cnt + 1;
            end
            else begin
                s23_re    <= s2_re;
                s23_im    <= s2_im;
                s23_valid <= 1;
            end
        end
    end

    // ======================================================
    // Stage-3
    // ======================================================
    stage3_radix2_sdf_stream STAGE3 (
        .clk       (clk),
        .valid_in  (s23_valid),
        .xin_re    (s23_re),
        .xin_im    (s23_im),
        .xout_re   (s3_re),
        .xout_im   (s3_im),
        .valid_out (s3_valid)
    );

    assign xout_re   = s3_re;
    assign xout_im   = s3_im;
    assign valid_out = s3_valid;

    // ======================================================
    // Initialization
    // ======================================================
    initial begin
        s1_warmup_cnt = 0;
        s2_warmup_cnt = 0;
        s12_valid     = 0;
        s23_valid     = 0;
    end

endmodule