module non_recursive_filter #(
    parameter M = 32,
    parameter sig_length = 8,
    parameter out_length = 10
) (
    input  wire                             clk,
    input  wire                             rst,
    input  wire                             valid_in,
    input  wire signed [sig_length - 1 : 0] x,
    output wire signed [out_length - 1 : 0] y,  // Changed to wire
    output reg                              valid_out
);

    localparam LOG2_M = $clog2(M);
    localparam SUM_WIDTH = sig_length + LOG2_M;

    // Shift register for the tapped delay line
    reg signed [sig_length - 1 : 0] delay_line [0 : M - 1];
    
    // Combinational adder tree sum
    reg signed [SUM_WIDTH - 1 : 0]  tree_sum;
    
    wire signed [SUM_WIDTH - 1 : 0] rounded_sum = tree_sum + (M >> 1);
    wire signed [SUM_WIDTH - 1 : 0] scaled_out  = rounded_sum >>> LOG2_M;

    // Combinational Output
    assign y = scaled_out[out_length - 1 : 0];

    integer i;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < M; i = i + 1) begin
                delay_line[i] <= 0;
            end
            valid_out <= 0;
        end else if (valid_in) begin
            // Shift data
            delay_line[0] <= x;
            for (i = 1; i < M; i = i + 1) begin
                delay_line[i] <= delay_line[i - 1];
            end
            
            valid_out <= 1'b1;
        end else begin
            valid_out <= 1'b0;
        end
    end

    // Unpipelined Adder Tree (Synthesizes to a parallel cascade of 31 adders)
    integer j;
    always @(*) begin
        tree_sum = 0;
        for (j = 0; j < M; j = j + 1) begin
            tree_sum = tree_sum + delay_line[j];
        end
    end

endmodule