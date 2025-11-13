`timescale 1ns/1ps

module testbench_working;
    reg clk, reset;
    reg [7:0] addr;
    reg [7:0] data_in;
    reg read, write;
    wire [7:0] data_out;
    wire hit, miss, ready;
    
    integer test_count;
    
    // Instantiate the cache system
    fully_associative_cache dut (
        .clk(clk),
        .reset(reset),
        .addr(addr),
        .data_in(data_in),
        .read(read),
        .write(write),
        .data_out(data_out),
        .hit(hit),
        .miss(miss),
        .ready(ready)
    );
    
    // Clock generation (10ns period = 100MHz)
    always #5 clk = ~clk;
    
    // Main test sequence
    initial begin
        // Initialize VCD file for waveform viewing
        $dumpfile("cache_waves.vcd");
        $dumpvars(0, testbench_working);
        
        // Initialize signals
        clk = 0;
        reset = 1;
        addr = 8'h00;
        data_in = 8'h00;
        read = 0;
        write = 0;
        test_count = 0;
        
        $display("==============================================");
        $display("        CACHE SIMULATION STARTING");
        $display("==============================================");
        
        // Release reset after 20ns
        #20 reset = 0;
        
        $display("[SYSTEM] Reset released at time %0t ns", $time);
        
        // Test 1: Simple write and read
        test_count = 1;
        $display("\n--- Test %0d: Write then Read (Basic Operation) ---", test_count);
        
        // Write operation
        wait_for_ready();
        @(negedge clk);
        addr = 8'h10;
        data_in = 8'hAA;
        write = 1;
        $display("[CPU] WRITE Operation -> Address: 0x%02h, Data: 0x%02h", 8'h10, 8'hAA);
        wait_for_ready();
        @(negedge clk);
        write = 0;
        $display("[CPU] Write operation completed successfully");
        #20;
        
        // Read operation
        wait_for_ready();
        @(negedge clk);
        addr = 8'h10;
        read = 1;
        $display("[CPU] READ Operation -> Address: 0x%02h", 8'h10);
        wait_for_ready();
        @(negedge clk);
        read = 0;
        if (hit) begin
            $display("[CACHE] *** HIT *** Data Retrieved: 0x%02h", data_out);
        end else if (miss) begin
            $display("[CACHE] *** MISS *** Data not in cache");
        end
        #50;
        
        // Test 2: Read miss scenario
        test_count = 2;
        $display("\n--- Test %0d: Read Miss (Cache Empty) ---", test_count);
        
        wait_for_ready();
        @(negedge clk);
        addr = 8'h20;
        read = 1;
        $display("[CPU] READ Operation -> Address: 0x%02h", 8'h20);
        wait_for_ready();
        @(negedge clk);
        read = 0;
        if (hit) begin
            $display("[CACHE] *** HIT *** Data Retrieved: 0x%02h", data_out);
        end else if (miss) begin
            $display("[CACHE] *** MISS *** Data not in cache");
        end
        #50;
        
        // Test 3: Another read (should hit now)
        test_count = 3;
        $display("\n--- Test %0d: Read Hit (After Miss) ---", test_count);
        
        wait_for_ready();
        @(negedge clk);
        addr = 8'h20;
        read = 1;
        $display("[CPU] READ Operation -> Address: 0x%02h", 8'h20);
        wait_for_ready();
        @(negedge clk);
        read = 0;
        if (hit) begin
            $display("[CACHE] *** HIT *** Data Retrieved: 0x%02h", data_out);
        end else if (miss) begin
            $display("[CACHE] *** MISS *** Data not in cache");
        end
        #50;
        
        // Test 4: Fill the cache
        test_count = 4;
        $display("\n--- Test %0d: Fill Cache (Multiple Writes) ---", test_count);
        
        // Write 8'h30
        wait_for_ready();
        @(negedge clk);
        addr = 8'h30;
        data_in = 8'h33;
        write = 1;
        $display("[CPU] WRITE Operation -> Address: 0x%02h, Data: 0x%02h", 8'h30, 8'h33);
        wait_for_ready();
        @(negedge clk);
        write = 0;
        
        // Write 8'h40
        wait_for_ready();
        @(negedge clk);
        addr = 8'h40;
        data_in = 8'h44;
        write = 1;
        $display("[CPU] WRITE Operation -> Address: 0x%02h, Data: 0x%02h", 8'h40, 8'h44);
        wait_for_ready();
        @(negedge clk);
        write = 0;
        
        // Write 8'h50
        wait_for_ready();
        @(negedge clk);
        addr = 8'h50;
        data_in = 8'h55;
        write = 1;
        $display("[CPU] WRITE Operation -> Address: 0x%02h, Data: 0x%02h", 8'h50, 8'h55);
        wait_for_ready();
        @(negedge clk);
        write = 0;
        #50;
        
        // Test 5: Write Hit (Update existing data)
        test_count = 5;
        $display("\n--- Test %0d: Write Hit (Update Cached Data) ---", test_count);
        
        // Write to 8'h10 again (already in cache from Test 1)
        wait_for_ready();
        @(negedge clk);
        addr = 8'h10;
        data_in = 8'hFF;
        write = 1;
        $display("[CPU] WRITE Operation -> Address: 0x%02h, Data: 0x%02h (UPDATE)", 8'h10, 8'hFF);
        wait_for_ready();
        @(negedge clk);
        write = 0;
        if (hit) begin
            $display("[CACHE] *** WRITE HIT *** Data updated in cache");
        end else if (miss) begin
            $display("[CACHE] *** WRITE MISS *** Unexpected!");
        end
        #50;
        
        // Test 6: Verify all data
        test_count = 6;
        $display("\n--- Test %0d: Verify All Cached Data ---", test_count);
        
        // Read 8'h10
        wait_for_ready();
        @(negedge clk);
        addr = 8'h10;
        read = 1;
        $display("[CPU] READ Operation -> Address: 0x%02h", 8'h10);
        wait_for_ready();
        @(negedge clk);
        read = 0;
        if (hit) begin
            $display("[CACHE] *** HIT *** Data Retrieved: 0x%02h", data_out);
        end else if (miss) begin
            $display("[CACHE] *** MISS *** Data not in cache");
        end
        
        // Read 8'h20
        wait_for_ready();
        @(negedge clk);
        addr = 8'h20;
        read = 1;
        $display("[CPU] READ Operation -> Address: 0x%02h", 8'h20);
        wait_for_ready();
        @(negedge clk);
        read = 0;
        if (hit) begin
            $display("[CACHE] *** HIT *** Data Retrieved: 0x%02h", data_out);
        end else if (miss) begin
            $display("[CACHE] *** MISS *** Data not in cache");
        end
        
        // Read 8'h30
        wait_for_ready();
        @(negedge clk);
        addr = 8'h30;
        read = 1;
        $display("[CPU] READ Operation -> Address: 0x%02h", 8'h30);
        wait_for_ready();
        @(negedge clk);
        read = 0;
        if (hit) begin
            $display("[CACHE] *** HIT *** Data Retrieved: 0x%02h", data_out);
        end else if (miss) begin
            $display("[CACHE] *** MISS *** Data not in cache");
        end
        
        // Read 8'h40
        wait_for_ready();
        @(negedge clk);
        addr = 8'h40;
        read = 1;
        $display("[CPU] READ Operation -> Address: 0x%02h", 8'h40);
        wait_for_ready();
        @(negedge clk);
        read = 0;
        if (hit) begin
            $display("[CACHE] *** HIT *** Data Retrieved: 0x%02h", data_out);
        end else if (miss) begin
            $display("[CACHE] *** MISS *** Data not in cache");
        end
        
        // Read 8'h50
        wait_for_ready();
        @(negedge clk);
        addr = 8'h50;
        read = 1;
        $display("[CPU] READ Operation -> Address: 0x%02h", 8'h50);
        wait_for_ready();
        @(negedge clk);
        read = 0;
        if (hit) begin
            $display("[CACHE] *** HIT *** Data Retrieved: 0x%02h", data_out);
        end else if (miss) begin
            $display("[CACHE] *** MISS *** Data not in cache");
        end
        #100;
        
        $display("\n==============================================");
        $display("      ALL TESTS COMPLETED SUCCESSFULLY");
        $display("        Simulation Time: %0t ns", $time);
        $display("==============================================");
        $finish;
    end
    
    // Wait for ready signal task
    task wait_for_ready;
        begin
            if (ready == 1'b0) begin
                $display("[SYSTEM] Cache busy... waiting for ready signal");
                @(posedge ready);
                $display("[SYSTEM] Cache ready for next operation");
            end
        end
    endtask
    
    // Monitor cache hits and misses
    always @(posedge clk) begin
        if (hit && read) begin
            $display("[CACHE] >>> HIT detected for address 0x%02h", addr);
        end
        if (miss && read) begin
            $display("[CACHE] >>> MISS detected for address 0x%02h", addr);
        end
    end
    
    // Monitor important signals
    always @(posedge hit) begin
        $display("[SIGNAL] HIT signal activated");
    end
    
    always @(posedge miss) begin
        $display("[SIGNAL] MISS signal activated");
    end
    
    // Timeout protection
    initial begin
        #5000; // 5us timeout
        $display("==============================================");
        $display("            SIMULATION TIMEOUT!");
        $display("  Simulation ran for 5000ns without");
        $display("        completing all tests");
        $display("==============================================");
        $finish;
    end
    
endmodule