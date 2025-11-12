module replacement_policy #(
    parameter CACHE_SIZE = 4
)(
    input wire clk,
    input wire reset,
    input wire [CACHE_SIZE-1:0] access_lines,  // Which lines were accessed
    input wire update_policy,                  // Signal to update replacement data
    
    output reg [1:0] replace_index,  // 2 bits for 4 cache lines
    output reg replacement_ready
);

    // Simple round-robin replacement
    reg [1:0] rr_pointer;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            rr_pointer <= 2'b00;
            replacement_ready <= 1'b1;
            replace_index <= 2'b00;  // Initialize replace_index
        end else if (update_policy) begin
            // Move to next line for next replacement
            rr_pointer <= rr_pointer + 1;
            replace_index <= rr_pointer + 1;  // Update replace_index
        end else begin
            replace_index <= rr_pointer;  // Keep current value
        end
    end

endmodule