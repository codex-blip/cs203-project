# cache_memory_array.v — File README

## What this file does
Implements the cache’s physical storage: per-line tag, data byte, valid bit, and dirty bit. Provides read/write ports steered by `line_select` and control bits.

## Key ports & signals
- **Inputs:** `clk`, `reset`, `line_select[CACHE_SIZE-1:0]`, `write_enable`, `tag_in`, `data_in`, `set_valid`, `set_dirty_bit`, `clear_dirty_bit`
- **Outputs:** `data_out`, `tag_out_0..3`, `valid_0..3`, `dirty_0..3`

## How it works (in brief)
On a read, drives `data_out` from the selected line. On a write, updates the selected line’s data and potentially valid/dirty/tag fields. Reset clears valid/dirty for all lines.

## How to read its outputs
- `data_out` is meaningful when a line is selected and the op is a read.
- `valid_*`/`dirty_*` can be plotted in waveforms to confirm fills and write-backs.
- `tag_out_*` are fed to the comparator to determine hits.

---

**Testing tip:** Exercise resets first, then a read hit, a write hit, and finally a miss+refill to see all code paths.
