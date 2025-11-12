module fully_associative_cache #(
    parameter CACHE_SIZE = 4,
    parameter BLOCK_SIZE = 1,
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 8
)(
    input wire clk,
    input wire reset,
    
    // CPU interface
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] data_in,
    input wire read,
    input wire write,
    
    output wire [DATA_WIDTH-1:0] data_out,
    output wire hit,
    output wire miss,
    output wire ready
);

    // Internal wiring - FIXED PORT NAMES
    wire [CACHE_SIZE-1:0] line_select;
    wire cache_write_enable;
    wire set_valid_bit;
    wire set_dirty_bit;
    wire clear_dirty_bit;
    
    // Individual cache line outputs
    wire [ADDR_WIDTH-1:0] tag_out_0, tag_out_1, tag_out_2, tag_out_3;
    wire [DATA_WIDTH-1:0] data_out_0, data_out_1, data_out_2, data_out_3;
    wire valid_0, valid_1, valid_2, valid_3;
    wire dirty_0, dirty_1, dirty_2, dirty_3;
    
    wire [CACHE_SIZE-1:0] hit_lines;
    wire [1:0] hit_index;
    wire [1:0] replace_index;
    
    // Control signals
    wire hit_signal, miss_signal, ready_signal;
    wire [DATA_WIDTH-1:0] read_data_signal;

    // Instantiate cache memory array - FIXED CONNECTIONS
    cache_memory_array cache_array (
        .clk(clk),
        .reset(reset),
        .line_select(line_select),
        .write_enable(cache_write_enable),
        .tag_in(addr),  // Using full address as tag (simple)
        .data_in(data_in),
        .set_valid(set_valid_bit),
        .set_dirty(set_dirty_bit),
        .clear_dirty(clear_dirty_bit),
        .tag_out_0(tag_out_0),
        .tag_out_1(tag_out_1), 
        .tag_out_2(tag_out_2),
        .tag_out_3(tag_out_3),
        .data_out_0(data_out_0),
        .data_out_1(data_out_1),
        .data_out_2(data_out_2),
        .data_out_3(data_out_3),
        .valid_0(valid_0),
        .valid_1(valid_1),
        .valid_2(valid_2),
        .valid_3(valid_3),
        .dirty_0(dirty_0),
        .dirty_1(dirty_1),
        .dirty_2(dirty_2),
        .dirty_3(dirty_3)
    );

    // Instantiate comparator logic - FIXED CONNECTIONS
    comparator_logic comparators (
        .address(addr),
        .tag_out_0(tag_out_0),
        .tag_out_1(tag_out_1),
        .tag_out_2(tag_out_2),
        .tag_out_3(tag_out_3),
        .valid_0(valid_0),
        .valid_1(valid_1),
        .valid_2(valid_2),
        .valid_3(valid_3),
        .hit(hit),
        .hit_lines(hit_lines),
        .hit_index(hit_index)
    );

    // Instantiate replacement policy
    replacement_policy repl_policy (
        .clk(clk),
        .reset(reset),
        .access_lines(hit_lines),
        .update_policy(hit),  // Update on hits
        .replace_index(replace_index),
        .replacement_ready()
    );

    // Instantiate control FSM - FIXED CONNECTIONS
    cache_control_fsm controller (
        .clk(clk),
        .reset(reset),
        .read_request(read),
        .write_request(write),
        .address(addr),
        .write_data(data_in),
        .cache_hit(hit),
        .hit_lines(hit_lines),
        .hit_index(hit_index),
        .replace_index(replace_index),
        .line_select(line_select),
        .cache_write_enable(cache_write_enable),
        .set_valid_bit(set_valid_bit),
        .set_dirty_bit(set_dirty_bit),
        .clear_dirty_bit(clear_dirty_bit),
        .read_data(read_data_signal),
        .hit_signal(hit_signal),
        .miss_signal(miss_signal),
        .ready(ready_signal)
    );

    // Connect outputs
    assign data_out = read_data_signal;
    assign hit = hit_signal;
    assign miss = miss_signal;
    assign ready = ready_signal;

endmodule