module refreshed_filter #(
    parameter M = 32,
    parameter sig_length = 8,
    parameter out_length = 10,
    parameter REFRESH = 64
) (
    input  wire signed [sig_length - 1 : 0] x,
    input  wire                             clk,
    input  wire                             rst,

    // Handshake signals
    input  wire                             valid_in,
    output wire                             ready_out,

    output wire signed [out_length - 1 : 0] y,
    output reg                              valid_out
);

    // Calculate required bit widths
    localparam LOG2_M      = $clog2(M);
    localparam SUM_WIDTH   = sig_length + LOG2_M;
    localparam TIMER_WIDTH = $clog2(REFRESH); 

    // Memory for delay line (Circular Buffer)
    // Only one write/read port needed now
    reg signed [sig_length - 1 : 0] delay_line [0 : M - 1];
    reg [LOG2_M - 1 : 0] wr_ptr;

    // Datapath Registers
    reg signed [SUM_WIDTH - 1 : 0] running_sum;    
    reg signed [SUM_WIDTH - 1 : 0] shadow_sum;
    reg [TIMER_WIDTH - 1  : 0]     timer;

    // Bit-true rounding: add (M/2) before truncation to avoid zeroing 
    wire signed [SUM_WIDTH - 1 : 0] rounded_sum = running_sum + (M >> 1);
    wire signed [SUM_WIDTH - 1 : 0] scaled_out  = rounded_sum >>> LOG2_M;

    // Output assignments
    assign y = scaled_out[out_length - 1 : 0];
    assign ready_out = 1'b1; // Never stalls upstream data

    integer i;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            running_sum <= 0;
            shadow_sum  <= 0;
            timer       <= 0;
            wr_ptr      <= 0;
            valid_out   <= 1'b0;

            for (i = 0; i < M; i = i + 1) begin
                delay_line[i] <= 0;
            end
        end else begin
            valid_out <= valid_in; // Pass valid signal through

            if (valid_in) begin
                // 1. Update Circular Buffer (Write newest, overwrites oldest naturally)
                delay_line[wr_ptr] <= x;
                wr_ptr <= wr_ptr + 1;

                // 2. Timer Control & Shadow Accumulator Logic
                if (timer == REFRESH - 1) begin
                    // Swap exact sum into the main accumulator, add final sample
                    running_sum <= shadow_sum + x;
                    timer <= 0;
                end else begin
                    // Normal Recursive Moving Average
                    running_sum <= running_sum + x - delay_line[wr_ptr];
                    timer <= timer + 1;

                    // Background Shadow Adder logic
                    if (timer == (REFRESH - M)) begin
                        shadow_sum <= x; // Wake up and start fresh sum
                    end else if (timer > (REFRESH - M)) begin
                        shadow_sum <= shadow_sum + x; // Accumulate in the background
                    end
                end
            end else begin
                valid_out <= 1'b0; // De-assert if no valid input
            end
        end
    end

endmodule