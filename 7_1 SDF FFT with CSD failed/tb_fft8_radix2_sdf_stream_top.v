`timescale 1ns/1ps

module tb_fft8_radix2_sdf_stream_top;

    // --------------------------------------------------------
    // Signal Declarations
    // --------------------------------------------------------
    reg         clk;
    reg         valid_in;
    reg  signed [15:0] xin_re, xin_im;
    wire signed [15:0] xout_re, xout_im;
    wire        valid_out;
    
    integer out_count;
    integer i;

    // --------------------------------------------------------
    // Device Under Test (DUT)
    // --------------------------------------------------------
    fft8_radix2_sdf_stream_top DUT (
        .clk      (clk),
        .valid_in (valid_in),
        .xin_re   (xin_re),
        .xin_im   (xin_im),
        .xout_re  (xout_re),
        .xout_im  (xout_im),
        .valid_out(valid_out)
    );

    // --------------------------------------------------------
    // Clock Generation (100MHz)
    // --------------------------------------------------------
    always #5 clk = ~clk;

    // --------------------------------------------------------
    // Input Task
    // --------------------------------------------------------
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

    // --------------------------------------------------------
    // Output Counter Logic
    // --------------------------------------------------------
    always @(posedge clk) begin
        if (valid_out) begin
            out_count = out_count + 1;
        end
    end

    // --------------------------------------------------------
    // Test Stimulus
    // --------------------------------------------------------
    initial begin
        // Initialize Signals
        clk       = 0;
        valid_in  = 0;
        xin_re    = 0;
        xin_im    = 0;
        out_count = 0;

        // Reset/Startup Delay
        @(posedge clk); 
        #1;

        // SEQ1: Real ramp 1 to 8
        apply_input( 1, 0); apply_input( 2, 0);
        apply_input( 3, 0); apply_input( 4, 0);
        apply_input( 5, 0); apply_input( 6, 0);
        apply_input( 7, 0); apply_input( 8, 0);

        // SEQ2: Zeros (8 samples)
        repeat(8) apply_input(0, 0);

        // SEQ3: Real ones (8 samples)
        repeat(8) apply_input(1, 0);

        // SEQ4: Complex Mixed Data
        apply_input( 2,  1); apply_input(-1,  3);
        apply_input( 4, -2); apply_input( 0,  1);
        apply_input(-3,  0); apply_input( 1, -4);
        apply_input(-2,  2); apply_input( 3, -1);

        // SEQ5: Real constant 4
        repeat(8) apply_input(4, 0);

        // Pipeline Flush (20 cycles of zeros)
        valid_in = 1;
        for (i = 0; i < 20; i = i + 1) begin
            apply_input(0, 0);
        end
        
        valid_in = 0;

        // Wait for final samples to propagate
        #200;
        $finish;
    end

    // --------------------------------------------------------
    // Waveform Generation
    // --------------------------------------------------------
    initial begin
        $dumpfile("fft8_csd.vcd");
        $dumpvars(0, tb_fft8_radix2_sdf_stream_top);
    end

endmodule
