# Fully-Associative Cache – Project README

This repository implements a **tiny, fully‑associative write‑back cache** in synthesizable Verilog and a self‑checking testbench. It’s designed for learning and for lab reports: small parameters, clean interfaces, and readable control logic.

## Modules
- `fully_associative_cache.v` — Top-level cache wrapper that wires all submodules together.
- `cache_control_fsm.v` — The controller/arbiter (finite‑state machine) that sequences read/write hits and misses, and coordinates main‑memory traffic & replacement.
- `cache_memory_array.v` — The data/tag/metadata (valid/dirty) storage for each cache line.
- `comparator_logic.v` — Parallel tag/valid compare across all lines, produces `hit`, `hit_lines`, and `hit_index`.
- `replacement_policy.v` — Simple round‑robin (RR) line selector used on miss or when a dirty victim must be chosen.
- `main_memory.v` — A simple single‑port byte‑addressed memory model with a ready/latency handshake.
- `cache_testbench.v` — Generates stimulus, checks results, and prints a concise log so you can understand the cache’s behavior.

> **Key parameters (kept small for teaching/testing):**
>
> - `CACHE_SIZE = 4` lines, fully‑associative  
> - `BLOCK_SIZE = 1` byte per line (no burst)  
> - `ADDR_WIDTH = 8` (cache) / `16` (main memory)  
> - `DATA_WIDTH = 8` (byte‑wide)  

## How the cache works (high level)
1. **CPU read/write request** arrives at `fully_associative_cache` via `addr`, `data_in`, `read`, `write`.
2. `comparator_logic` compares the request **address** (used as the tag in this minimal design) with the **stored tags** for all lines where `valid=1`.
3. - If **hit**: `cache_control_fsm` enables the selected line in `cache_memory_array`.
   - **Read** returns `data_out` in a cycle.
   - **Write** updates data and sets `dirty`.
4. - If **miss**: `cache_control_fsm` asks `replacement_policy` for a **victim** line.
   - If victim is **dirty**, it is written back to `main_memory` first.
   - Then the new block is **fetched** from `main_memory`, the line’s **tag/valid** are updated, and the pending CPU op completes.
5. `ready` goes high when the transaction is complete. The top module also reports `hit`/`miss` for clarity.

## Building & running the simulation

You can use any Verilog simulator. Below are example commands for **Icarus Verilog** (iverilog/vvp):

```bash
# From the project root:
iverilog -g2012 -o cache_tb.vvp   fully_associative_cache.v   cache_control_fsm.v   cache_memory_array.v   comparator_logic.v   replacement_policy.v   main_memory.v   cache_testbench.v

vvp cache_tb.vvp
```

Optional: dump a VCD waveform by adding `$dumpfile/$dumpvars` in the testbench (many sims support `+dumpvars`). Open the VCD with **GTKWave** to inspect timing.

## Understanding the testbench output
`cache_testbench.v` drives sequences of reads/writes. Watch these signals:
- `hit` / `miss` — one‑cycle flags describing the access result.
- `ready` — marks the moment an access (incl. a refill/write‑back) is finished.
- `data_out` — valid on `read` when `ready=1`.
- Console messages in the testbench summarize **hit/miss**, **victim index**, and **write‑backs** (if the bench prints them in your version).

## Typical scenarios you’ll see
- **Cold miss → fill**: first access to an address; RR chooses line 0, fetches from main memory, sets `valid=1` and `tag=addr`.
- **Hit read**: subsequent read to the same address returns immediately.
- **Hit write (write‑back)**: updates the line and sets `dirty=1`, deferring memory write until eviction.
- **Conflict miss + dirty eviction**: RR selects a line that’s dirty; FSM writes it back before filling the new block.

## File‑by‑file READMEs
This repo includes a **separate README** for each source file to make grading/writing reports easy:

- `README_fully_associative_cache.md`
- `README_cache_control_fsm.md`
- `README_cache_memory_array.md`
- `README_comparator_logic.md`
- `README_replacement_policy.md`
- `README_main_memory.md`
- `README_cache_testbench.md`

See also: `REPORT.md` — a deeper, narrative explanation with state diagrams and timing notes.

---

**Tip:** Because `BLOCK_SIZE=1`, the “tag” equals the whole request address in this didactic design. This keeps the focus on associativity and control sequencing rather than indexing/offset math.
