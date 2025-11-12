Fully Associociative Cache System - Detailed README
Project Overview
This project implements a fully associative cache memory system in Verilog that simulates how modern processors use cache memory to speed up data access. The system includes a complete cache hierarchy with control logic, memory arrays, replacement policies, and a testbench for verification.

Key Features:
Fully Associative Mapping: Any memory block can be placed in any cache line

Write-Through Policy: Writes update both cache and main memory

Round-Robin Replacement: Simple but effective cache line replacement

Modular Design: Separated into specialized components

Comprehensive Testing: Detailed testbench with multiple scenarios

File Descriptions
1. fully_associative_cache.v - Top-Level Module
Purpose: Integrates all cache components into a complete system

Key Components:

Cache Memory Array: Stores actual data and tags

Comparator Logic: Determines cache hits/misses

Replacement Policy: Decides which cache line to replace

Control FSM: Orchestrates all cache operations

Interface:

Inputs: Clock, reset, address, data, read/write commands

Outputs: Data output, hit/miss signals, ready status

How it Works:
This module acts as the central hub, connecting all submodules and providing the main interface for the CPU. When the CPU requests data, this module coordinates between the comparator (to check if data is cached), the FSM (to manage the operation flow), and the memory array (to store/retrieve data).

2. cache_control_fsm.v - Finite State Machine Controller
Purpose: Implements the brain of the cache system that manages all operations

States:

IDLE: Waiting for CPU requests

TAG_COMPARE: Comparing address with cache tags

READ_HIT: Serving data from cache on hit

WRITE_HIT: Updating cache on write hit

READ_MISS: Handling cache miss for read

WRITE_MISS: Handling cache miss for write

UPDATE_CACHE: Loading new data into cache

Key Functions:

State Transitions: Moves between states based on hit/miss and read/write

Output Control: Generates control signals for other modules

Operation Sequencing: Ensures proper order of cache operations

Debug Output: Provides detailed state transition messages

How it Works:
The FSM starts in IDLE. When a request arrives, it moves to TAG_COMPARE to check if the data is cached. Based on the result (hit/miss) and operation type (read/write), it transitions to the appropriate state to handle the request, then returns to IDLE.

3. cache_memory_array.v - Cache Storage
Purpose: Implements the physical storage for cache data, tags, and status bits

Storage Elements:

Tag Storage: 4 cache lines × 8-bit tags

Data Storage: 4 cache lines × 8-bit data

Valid Bits: Indicates if cache line contains valid data

Dirty Bits: Indicates if cache data differs from main memory

Key Features:

Individual Line Control: Each cache line can be independently accessed

Parallel Output: All cache line data available simultaneously

Write Enable Control: Selective writing to cache lines

How it Works:
This module maintains four independent cache lines. Each line stores a memory address tag, the actual data, and status flags. The line_select input determines which line is active for read/write operations.

4. comparator_logic.v - Hit/Miss Detection
Purpose: Compares incoming addresses with cached addresses to detect hits

Functionality:

Parallel Comparison: Compares address with all 4 cache tags simultaneously

Valid Bit Checking: Only considers valid cache lines

Hit Index Generation: Identifies which cache line contains the data

Outputs:

hit: Signal indicating address found in cache

hit_lines: One-hot encoded vector showing which line(s) match

hit_index: 2-bit index of matching cache line

How it Works:
The comparator takes the CPU's address and compares it against all four cached tags in parallel. If any valid cache line's tag matches the address, it asserts the hit signal and indicates which line contains the data.

5. replacement_policy.v - Cache Line Management
Purpose: Decides which cache line to replace when a miss occurs

Algorithm:

Round-Robin: Cycles through cache lines sequentially

Simple Implementation: Uses a 2-bit counter

Update Trigger: Updates on cache accesses

How it Works:
Maintains a pointer that increments with each cache access. When a miss occurs and a line needs to be replaced, it selects the line indicated by the current pointer position, then advances the pointer for the next replacement.

6. main_memory.v - Main Memory Simulation
Purpose: Simulates the main system memory (backing store)

Characteristics:

Large Capacity: 64KB address space

Memory Latency: Simulates real memory access delays

Error Checking: Address boundary validation

Interface:

Standard read/write interface with ready signaling

Configurable access latency

How it Works:
When accessed, it introduces artificial delay to simulate real memory latency, then completes the read or write operation. This helps demonstrate the performance benefit of cache hits vs. misses.

7. cache_testbench.v - Verification Environment
Purpose: Comprehensive testing of the cache system

Test Scenarios:

Basic Write/Read: Verify fundamental cache operations

Read Miss: Test cache miss handling

Read Hit: Verify cache hit performance

Cache Filling: Test behavior when cache becomes full

Data Verification: Confirm cached data integrity

Features:

Automatic Testing: Sequential test execution

Status Monitoring: Tracks hit/miss signals

Timeout Protection: Prevents infinite loops

Waveform Generation: Creates VCD files for debugging

How it Works:
The testbench generates sequences of read and write operations with specific address patterns, monitors the cache responses, and reports success/failure for each test case.

Cache Operation Details
Read Hit:
CPU sends read request with address

Comparator checks cache tags

Hit detected - data retrieved from cache

Data returned to CPU in 1-2 cycles

Read Miss:
CPU sends read request with address

Comparator detects miss

FSM initiates memory read

Data loaded from main memory to cache

Data returned to CPU (takes longer due to memory latency)

Write Hit:
CPU sends write request with address and data

Comparator detects hit

Data written to cache line

Dirty bit set (for write-back policy)

Main memory updated (write-through policy)

Write Miss:
CPU sends write request

Comparator detects miss

Cache line allocated (may require replacement)

Data written to cache and main memory

Design Parameters
Cache Size: 4 lines

Block Size: 1 byte

Address Width: 8 bits

Data Width: 8 bits

Associativity: Fully associative

Replacement Policy: Round-robin

Write Policy: Write-through