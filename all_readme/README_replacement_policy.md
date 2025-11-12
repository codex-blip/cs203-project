# replacement_policy.v — File README

## What this file does
Round‑robin victim selector. Advances a pointer whenever `update_policy` is pulsed.

## Key ports & signals
- **Inputs:** `clk`, `reset`, `access_lines[CACHE_SIZE-1:0]` (currently informational), `update_policy`
- **Outputs:** `replace_index[1:0]`, `replacement_ready`

## How it works (in brief)
A small `rr_pointer` register rotates over 0..3. On reset it starts at 0. When the FSM signals `update_policy`, it increments so the next miss chooses the next line.

## How to read its outputs
- Plot `replace_index` alongside misses to see which line will be filled next.
- `replacement_ready` is high after reset and stable during steady-state.

---

**Testing tip:** Exercise resets first, then a read hit, a write hit, and finally a miss+refill to see all code paths.
