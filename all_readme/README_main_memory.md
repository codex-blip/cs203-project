# main_memory.v — File README

## What this file does
Simple backing memory model. Serves read/write requests from the cache and asserts `ready` when complete.

## Key ports & signals
- **Inputs:** `clk`, `reset`, `read_request`, `write_request`, `address[ADDR_WIDTH-1:0]`, `write_data[DATA_WIDTH-1:0]`
- **Outputs:** `read_data[DATA_WIDTH-1:0]`, `ready`, `error`

## How it works (in brief)
On read, returns `memory_array[address]`. On write, stores `write_data` at the given address. If `address >= MEM_SIZE`, sets `error=1`.

## How to read its outputs
- During simulation, watch `ready` to align memory completions with the FSM’s EVICT/REFILL phases.
- Optional: preload `memory_array` to deterministic contents for reproducible tests.

---

**Testing tip:** Exercise resets first, then a read hit, a write hit, and finally a miss+refill to see all code paths.
