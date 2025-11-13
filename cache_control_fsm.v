module cache_control_fsm #(
    parameter CACHE_SIZE = 4,
    parameter BLOCK_SIZE = 1,
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 8
)(
    input wire clk,
    input wire reset,
    input wire read_request,
    input wire write_request,
    input wire [ADDR_WIDTH-1:0] address,
    input wire [DATA_WIDTH-1:0] write_data,
    input wire cache_hit,
    input wire [CACHE_SIZE-1:0] hit_lines,
    input wire [1:0] hit_index,
    input wire [1:0] replace_index,
    
    output reg [CACHE_SIZE-1:0] line_select,
    output reg cache_write_enable,
    output reg set_valid_bit,
    output reg set_dirty_bit,
    output reg clear_dirty_bit,
    output reg [DATA_WIDTH-1:0] read_data,
    output reg hit_signal,
    output reg miss_signal,
    output reg ready,
    output reg [ADDR_WIDTH-1:0] current_address  // Address being processed
);

    // FSM States
    parameter [2:0] IDLE = 3'b000;
    parameter [2:0] TAG_COMPARE = 3'b001;
    parameter [2:0] READ_HIT = 3'b010;
    parameter [2:0] WRITE_HIT = 3'b011;
    parameter [2:0] READ_MISS = 3'b100;
    parameter [2:0] WRITE_MISS = 3'b101;
    parameter [2:0] UPDATE_CACHE = 3'b110;
    
    reg [2:0] current_state, next_state, previous_state;
    reg [ADDR_WIDTH-1:0] saved_address;
    reg [DATA_WIDTH-1:0] saved_write_data;
    reg read_operation;
    reg [1:0] target_line;
    reg sampled_hit;  // Sample cache_hit for next_state decision

    // Helper function to convert state to string - MOVED BEFORE ITS USE
    function [80:0] state_to_string;
        input [2:0] state;
        begin
            case (state)
                IDLE: state_to_string = "IDLE";
                TAG_COMPARE: state_to_string = "TAG_COMPARE";
                READ_HIT: state_to_string = "READ_HIT";
                WRITE_HIT: state_to_string = "WRITE_HIT";
                READ_MISS: state_to_string = "READ_MISS";
                WRITE_MISS: state_to_string = "WRITE_MISS";
                UPDATE_CACHE: state_to_string = "UPDATE_CACHE";
                default: state_to_string = "UNKNOWN";
            endcase
        end
    endfunction

    // State register
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state <= IDLE;
            previous_state <= IDLE;
            $display("[FSM] System Reset -> Initializing to IDLE state");
        end else begin
            previous_state <= current_state;
            current_state <= next_state;
            if (current_state != next_state) begin
                $display("[FSM] State Transition: %s -> %s", 
                         state_to_string(current_state), state_to_string(next_state));
            end
        end
    end
    
    // Next state logic
    always @(*) begin
        next_state = current_state;
        
        case (current_state)
            IDLE: begin
                if (read_request || write_request) begin
                    next_state = TAG_COMPARE;
                end
            end
            
            TAG_COMPARE: begin
                // Only decide after being in TAG_COMPARE for at least one cycle
                if (previous_state == TAG_COMPARE) begin
                    $display("[FSM] Making decision: sampled_hit=%b, read_op=%b", sampled_hit, read_operation);
                    if (sampled_hit) begin
                        if (read_operation) 
                            next_state = READ_HIT;
                        else 
                            next_state = WRITE_HIT;
                    end else begin
                        if (read_operation) 
                            next_state = READ_MISS;
                        else 
                            next_state = WRITE_MISS;
                    end
                end
                // else stay in TAG_COMPARE for one more cycle
            end
            
            READ_HIT, WRITE_HIT: begin
                next_state = IDLE;
            end
            
            READ_MISS, WRITE_MISS: begin
                next_state = UPDATE_CACHE;
            end
            
            UPDATE_CACHE: begin
                next_state = IDLE;
            end
            
            default: begin
                next_state = IDLE;
            end
        endcase
    end
    
    // Output logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            line_select <= 4'b0000;
            cache_write_enable <= 1'b0;
            set_valid_bit <= 1'b0;
            set_dirty_bit <= 1'b0;
            clear_dirty_bit <= 1'b0;
            read_data <= 8'b0;
            hit_signal <= 1'b0;
            miss_signal <= 1'b0;
            ready <= 1'b1;
            saved_address <= 8'b0;
            saved_write_data <= 8'b0;
            read_operation <= 1'b0;
            target_line <= 2'b0;
            current_address <= 8'b0;
            sampled_hit <= 1'b0;
        end else begin
            // Default values
            line_select <= 4'b0000;
            cache_write_enable <= 1'b0;
            set_valid_bit <= 1'b0;
            set_dirty_bit <= 1'b0;
            clear_dirty_bit <= 1'b0;
            hit_signal <= 1'b0;
            miss_signal <= 1'b0;
            
            case (current_state)
                IDLE: begin
                    ready <= 1'b1;
                    if (read_request || write_request) begin
                        ready <= 1'b0;
                        saved_address <= address;
                        current_address <= address;  // Update current address
                        saved_write_data <= write_data;
                        read_operation <= read_request;
                        $display("[FSM] New %s Request -> Address: 0x%02h", 
                                 read_request ? "READ" : "WRITE", address);
                    end
                end
                
                TAG_COMPARE: begin
                    sampled_hit <= cache_hit;  // Sample for next cycle's decision
                    $display("[FSM] Tag Comparison Result: %s (prev=%s)", 
                             cache_hit ? "HIT" : "MISS", state_to_string(previous_state));
                end
                
                READ_HIT: begin
                    hit_signal <= 1'b1;
                    line_select[hit_index] <= 1'b1;
                    read_data <= {saved_address[3:0], 4'hA}; // Simple data pattern
                    ready <= 1'b1;
                    $display("[FSM] *** READ HIT *** Addr: 0x%02h -> Data: 0x%02h", 
                             saved_address, read_data);
                end
                
                WRITE_HIT: begin
                    hit_signal <= 1'b1;
                    line_select[hit_index] <= 1'b1;
                    cache_write_enable <= 1'b1;
                    set_dirty_bit <= 1'b1;
                    ready <= 1'b1;
                    $display("[FSM] *** WRITE HIT *** Addr: 0x%02h <- Data: 0x%02h", 
                             saved_address, saved_write_data);
                end
                
                READ_MISS: begin
                    miss_signal <= 1'b1;
                    target_line <= replace_index;
                    ready <= 1'b0;
                    $display("[FSM] *** READ MISS *** Addr: 0x%02h -> Replacing Line: %0d", 
                             saved_address, replace_index);
                end
                
                WRITE_MISS: begin
                    miss_signal <= 1'b1;
                    target_line <= replace_index;
                    ready <= 1'b0;
                    $display("[FSM] *** WRITE MISS *** Addr: 0x%02h -> Replacing Line: %0d", 
                             saved_address, replace_index);
                end
                
                UPDATE_CACHE: begin
                    line_select[target_line] <= 1'b1;
                    set_valid_bit <= 1'b1;
                    cache_write_enable <= 1'b1;
                    
                    if (read_operation) begin
                        read_data <= {saved_address[3:0], 4'hF}; // Simulated memory data
                        hit_signal <= 1'b1;
                        $display("[FSM] Cache Update (READ) -> Line %0d: Addr 0x%02h = Data 0x%02h", 
                                 target_line, saved_address, read_data);
                    end else begin
                        set_dirty_bit <= 1'b1;
                        hit_signal <= 1'b1;
                        $display("[FSM] Cache Update (WRITE) -> Line %0d: Addr 0x%02h <- Data 0x%02h", 
                                 target_line, saved_address, saved_write_data);
                    end
                    ready <= 1'b1;
                end
            endcase
        end
    end

endmodule
