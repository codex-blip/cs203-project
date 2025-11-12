# cache_control_fsm.v — File README

## What this file does
Central state machine that sequences read/write hits and miss handling. It arbitrates access to the cache array, invokes the replacement policy, and performs write-backs/refills through main memory.

## Key ports & signals
- **Inputs:** `clk`, `reset`, `read_request`, `write_request`, `address`, `write_data`, `cache_hit`, `hit_lines[CACHE_SIZE-1:0]`, `hit_index[1:0]`, `replacement_ready`, `replace_index[1:0]`, `mem_ready`, `mem_read_data`
- **Outputs (representative):** `line_select[CACHE_SIZE-1:0]`, `cache_write_enable`, `set_valid`, `set_dirty_bit`, `clear_dirty_bit`, `tag_in`, `data_in`, `mem_read_request`, `mem_write_request`, `mem_address`, `mem_write_data`, `update_policy`, `read_data`, `hit`, `miss`, `ready`

## How it works (in brief)
Implements states like IDLE → LOOKUP → (HIT_RD|HIT_WR) or MISS_SELECT → (EVICT?) → REFILL → COMPLETE. On write hits it sets the dirty bit; on evictions it writes back dirty lines; on refills it sets valid and clears dirty. It pulses `update_policy` once a victim is consumed so RR advances.

## How to read its outputs
- Watch `ready` to know when an access is done.
- On hits, `line_select` matches `hit_index`; on misses, it matches `replace_index` after refill.
- Memory handshake is visible via `mem_*` signals and `mem_ready`.

---

**Testing tip:** Exercise resets first, then a read hit, a write hit, and finally a miss+refill to see all code paths.
