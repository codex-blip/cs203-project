module main_memory #(
    parameter ADDR_WIDTH = 16,
    parameter DATA_WIDTH = 8,
    parameter MEM_SIZE = 65536  // 64KB memory
)(
    input wire clk,
    input wire reset,
    
    // Cache interface
    input wire read_request,
    input wire write_request,
    input wire [ADDR_WIDTH-1:0] address,
    input wire [DATA_WIDTH-1:0] write_data,
    
    output reg [DATA_WIDTH-1:0] read_data,
    output reg ready,
    output reg error
);

    // Memory array
    reg [DATA_WIDTH-1:0] memory_array [0:MEM_SIZE-1];
    
    // Internal control
    reg [2:0] delay_counter;
    reg operation_pending;
    
    integer i;

    // Memory initialization
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < MEM_SIZE; i = i + 1) begin
                memory_array[i] <= {DATA_WIDTH{1'b0}};
            end
            read_data <= {DATA_WIDTH{1'b0}};
            ready <= 1'b1;
            error <= 1'b0;
            delay_counter <= 3'b0;
            operation_pending <= 1'b0;
        end else begin
            if (operation_pending) begin
                if (delay_counter > 0) begin
                    delay_counter <= delay_counter - 1;
                end else begin
                    // Complete memory operation
                    ready <= 1'b1;
                    operation_pending <= 1'b0;
                end
            end else if (read_request || write_request) begin
                // Start new memory operation
                ready <= 1'b0;
                operation_pending <= 1'b1;
                delay_counter <= 3'b100;  // Simulate memory latency
                
                // Check address bounds
                if (address < MEM_SIZE) begin
                    error <= 1'b0;
                    if (write_request) begin
                        memory_array[address] <= write_data;
                    end else begin
                        read_data <= memory_array[address];
                    end
                end else begin
                    error <= 1'b1;
                end
            end
        end
    end

endmodule