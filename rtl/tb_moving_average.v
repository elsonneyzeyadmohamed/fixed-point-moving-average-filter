`timescale 1ns/1ps

module tb_moving_average;

    parameter M = 32;
    parameter sig_length = 8;
    parameter out_length = 10;
    parameter REFRESH = 64;

    reg clk;
    reg rst;
    
    // Stimulus
    reg signed [sig_length - 1 : 0] x;
    reg valid_in;
    
    // Outputs from Refreshed Filter
    wire ready_out_ref;
    wire signed [out_length - 1 : 0] y_ref;
    wire valid_out_ref;

    // Outputs from Non-Recursive Filter
    wire signed [out_length - 1 : 0] y_non_rec;
    wire valid_out_non_rec;

    // Instantiate Shadow/Refreshed Filter
    refreshed_filter #(
        .M(M), .sig_length(sig_length), .out_length(out_length), .REFRESH(REFRESH)
    ) uut_refreshed (
        .clk(clk),
        .rst(rst),
        .x(x),
        .valid_in(valid_in),
        .ready_out(ready_out_ref),
        .y(y_ref),
        .valid_out(valid_out_ref)
    );

    // Instantiate Baseline Non-Recursive Filter
    non_recursive_filter #(
        .M(M), .sig_length(sig_length), .out_length(out_length)
    ) uut_non_rec (
        .clk(clk),
        .rst(rst),
        .valid_in(valid_in && ready_out_ref), // Stall when refreshed filter stalls
        .x(x),
        .y(y_non_rec),
        .valid_out(valid_out_non_rec)
    );

    // Clock Generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz clock
    end

    integer i;
    integer errors = 0;

    // Stimulus Generation
    initial begin
        rst = 1;
        x = 0;
        valid_in = 0;
        
        #20;
        rst = 0;
        
        // Feed 500 random samples
        for (i = 0; i < 500; i = i + 1) begin
            // Wait until the refreshed filter is ready to accept data
            wait(ready_out_ref == 1'b1);
            
            @(posedge clk);
            valid_in = 1;
            // Generate full 8-bit signed range (-128 to +127)
            x = ($random % 256) - 128; 
        end
        
        @(posedge clk);
        valid_in = 0;
        
        // Wait for final pipelines to clear
        #100;
        
        // Print Final Verdict
        if (errors == 0) begin
            $display("========================================");
            $display("SUCCESS: All outputs matched perfectly!");
            $display("========================================");
        end else begin
            $display("========================================");
            $display("FAILED: %0d mismatches detected.", errors);
            $display("========================================");
        end
        $stop;
    end

    // Automatic Checker (Self-Checking Logic)
    always @(posedge clk) begin
        if (valid_out_ref && valid_out_non_rec) begin
            if (y_ref !== y_non_rec) begin
                $display("ERROR at time %0t: y_ref = %d, y_non_rec = %d", $time, y_ref, y_non_rec);
                errors = errors + 1;
            end
        end
    end

endmodule