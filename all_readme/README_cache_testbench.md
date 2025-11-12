# cache_testbench.v — File README

## What this file does
Self‑contained testbench that toggles `clk`, asserts `reset`, then performs a sequence of reads and writes. Instantiates `fully_associative_cache` as DUT and observes `hit`, `miss`, `ready`, and `data_out`.

## Key ports & signals
- **Generates:** `clk`, `reset`, `addr`, `data_in`, `read`, `write`
- **Monitors:** `data_out`, `hit`, `miss`, `ready`
- **Parameters:** small defaults so sims finish quickly

## How it works (in brief)
Typical flow: after reset, issue a read to a fresh address (miss+refill), then repeat the read (hit), then write to the same address (dirty), then access enough unique addresses to force an eviction (and observe write‑back for dirty victims).

## How to read its outputs
- Console prints (if present) and waveforms show when `ready` is asserted and whether the access hit or missed.
- Extend by adding `$display` messages or VCD dumps to capture a readable log of events.

---

**Testing tip:** Exercise resets first, then a read hit, a write hit, and finally a miss+refill to see all code paths.
