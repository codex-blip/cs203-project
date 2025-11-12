# fully_associative_cache.v — File README

## What this file does
Top-level wrapper that instantiates and connects the cache storage, comparator, replacement policy, main memory model, and the control FSM. It exposes a simple CPU-like interface and forwards internal status flags (`hit`, `miss`, `ready`).

## Key ports & signals
- **Inputs:** `clk`, `reset`, `addr[ADDR_WIDTH-1:0]`, `data_in[DATA_WIDTH-1:0]`, `read`, `write`
- **Outputs:** `data_out[DATA_WIDTH-1:0]`, `hit`, `miss`, `ready`
- **Parameters:** `CACHE_SIZE`, `BLOCK_SIZE`, `ADDR_WIDTH`, `DATA_WIDTH`

## How it works (in brief)
Connects submodules, wires comparator outputs (`hit`, `hit_lines`, `hit_index`) to the FSM, and consumes replacement policy outputs (`replace_index`). Routes memory requests/responses between FSM and `main_memory`.

## How to read its outputs
- `hit`/`miss`: one-cycle summary flags for the current access.
- `ready`: goes high when the current operation (and any eviction/refill) is complete.
- `data_out`: valid when performing a read and `ready=1`.


---

**Testing tip:** Exercise resets first, then a read hit, a write hit, and finally a miss+refill to see all code paths.
