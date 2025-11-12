module cache_memory_array #(
    parameter CACHE_SIZE = 4,    // Smaller for testing
    parameter BLOCK_SIZE = 1,    // Simpler: 1 byte per block
    parameter ADDR_WIDTH = 8,    // Smaller for testing
    parameter DATA_WIDTH = 8
)(
    input wire clk,
    input wire reset,
    
    // Cache access interface
    input wire [CACHE_SIZE-1:0] line_select,
    input wire write_enable,
    input wire [ADDR_WIDTH-1:0] tag_in,
    input wire [DATA_WIDTH-1:0] data_in,  // Single byte now
    input wire set_valid,
    input wire set_dirty,
    input wire clear_dirty,
    
    // Individual outputs for each cache line
    output wire [ADDR_WIDTH-1:0] tag_out_0, tag_out_1, tag_out_2, tag_out_3,
    output wire [DATA_WIDTH-1:0] data_out_0, data_out_1, data_out_2, data_out_3,
    output wire valid_0, valid_1, valid_2, valid_3,
    output wire dirty_0, dirty_1, dirty_2, dirty_3
);

    // Internal storage
    reg [ADDR_WIDTH-1:0] tag_0, tag_1, tag_2, tag_3;
    reg [DATA_WIDTH-1:0] data_0, data_1, data_2, data_3;
    reg valid_0_reg, valid_1_reg, valid_2_reg, valid_3_reg;
    reg dirty_0_reg, dirty_1_reg, dirty_2_reg, dirty_3_reg;

    integer i;

    // Cache memory update logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Initialize all cache lines
            tag_0 <= 0; tag_1 <= 0; tag_2 <= 0; tag_3 <= 0;
            data_0 <= 0; data_1 <= 0; data_2 <= 0; data_3 <= 0;
            valid_0_reg <= 0; valid_1_reg <= 0; valid_2_reg <= 0; valid_3_reg <= 0;
            dirty_0_reg <= 0; dirty_1_reg <= 0; dirty_2_reg <= 0; dirty_3_reg <= 0;
        end else begin
            // Update line 0
            if (line_select[0]) begin
                if (write_enable) data_0 <= data_in;
                tag_0 <= tag_in;
                if (set_valid) valid_0_reg <= 1'b1;
                if (set_dirty) dirty_0_reg <= 1'b1;
                else if (clear_dirty) dirty_0_reg <= 1'b0;
            end
            
            // Update line 1
            if (line_select[1]) begin
                if (write_enable) data_1 <= data_in;
                tag_1 <= tag_in;
                if (set_valid) valid_1_reg <= 1'b1;
                if (set_dirty) dirty_1_reg <= 1'b1;
                else if (clear_dirty) dirty_1_reg <= 1'b0;
            end
            
            // Update line 2
            if (line_select[2]) begin
                if (write_enable) data_2 <= data_in;
                tag_2 <= tag_in;
                if (set_valid) valid_2_reg <= 1'b1;
                if (set_dirty) dirty_2_reg <= 1'b1;
                else if (clear_dirty) dirty_2_reg <= 1'b0;
            end
            
            // Update line 3
            if (line_select[3]) begin
                if (write_enable) data_3 <= data_in;
                tag_3 <= tag_in;
                if (set_valid) valid_3_reg <= 1'b1;
                if (set_dirty) dirty_3_reg <= 1'b1;
                else if (clear_dirty) dirty_3_reg <= 1'b0;
            end
        end
    end

    // Continuous output assignment
    assign tag_out_0 = tag_0;
    assign tag_out_1 = tag_1;
    assign tag_out_2 = tag_2;
    assign tag_out_3 = tag_3;
    
    assign data_out_0 = data_0;
    assign data_out_1 = data_1;
    assign data_out_2 = data_2;
    assign data_out_3 = data_3;
    
    assign valid_0 = valid_0_reg;
    assign valid_1 = valid_1_reg;
    assign valid_2 = valid_2_reg;
    assign valid_3 = valid_3_reg;
    
    assign dirty_0 = dirty_0_reg;
    assign dirty_1 = dirty_1_reg;
    assign dirty_2 = dirty_2_reg;
    assign dirty_3 = dirty_3_reg;

endmodule