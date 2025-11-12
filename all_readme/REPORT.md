# Fully‑Associative Cache — Detailed Explanation Report

This report explains the architecture, interfaces, control flow, timing, and test methodology for the included fully‑associative cache design.

---

## 1. Architecture Overview

**Goal:** implement a tiny, fully‑associative, write‑back cache suitable for teaching. The design emphasizes readability over peak performance.

**Blocks:**  
- **Top wrapper:** `fully_associative_cache.v` (wires the submodules)  
- **Control:** `cache_control_fsm.v` (finite‑state machine)  
- **Storage:** `cache_memory_array.v` (tags, data, valid, dirty per line)  
- **Hit detect:** `comparator_logic.v` (parallel compares + encode)  
- **Victim select:** `replacement_policy.v` (round‑robin)  
- **Backing store:** `main_memory.v` (simple single‑port RAM)  
- **Verification:** `cache_testbench.v` (stimulus + checks)

**Data/Tag simplification:** `BLOCK_SIZE=1` → the tag equals the full byte address, so no separate index/offset fields are used. This makes the associativity and FSM sequencing easy to observe in waveforms.

---

## 2. External Interface (top level)

`fully_associative_cache` ports (subset shown; see code):  
- Inputs: `clk, reset, addr[ADDR_WIDTH-1:0], data_in[DATA_WIDTH-1:0], read, write`  
- Outputs: `data_out[DATA_WIDTH-1:0], hit, miss, ready`

**Handshaking rule:** The bench asserts **either** `read` or `write` with a stable `addr` (and `data_in` for writes). The cache raises `ready` when done. On `ready=1`, `data_out` is valid for reads and `hit/miss` summarize the result.

---

## 3. Control Flow (FSM)

`cache_control_fsm.v` sequences the transaction. The typical states are:

- **IDLE**: wait for `read_request | write_request`.  
- **LOOKUP**: enable `comparator_logic` and sample `hit`, `hit_lines`, `hit_index`.  
- **HIT_RD**: for reads; select the winning line, read `data_out`, assert `ready`.  
- **HIT_WR**: for writes; select the winning line, write `data_in`, set `dirty`, assert `ready`.  
- **MISS_SELECT**: ask `replacement_policy` for `replace_index`.  
- **EVICT**: if the chosen line is `dirty`, drive `main_memory` write (`write_request=1`) with the victim’s tag/data; wait for memory `ready`.  
- **REFILL**: request a read from `main_memory` for the demanded address; wait for `ready`; then update the line’s `tag`, write `data`, set `valid=1`, clear `dirty`.  
- **COMPLETE**: finish the original CPU op (e.g., perform the pending write on a write‑miss or return the fetched byte on a read‑miss) and assert `ready`, then return to **IDLE**.

**Replacement handshake:** `replacement_policy` exposes `replace_index` and a `replacement_ready` flag. The FSM drives `update_policy` after it consumes a victim so RR advances to the next line for future misses.

---

## 4. Storage Array (`cache_memory_array.v`)

For **CACHE_SIZE = 4** lines the module stores, per line:
- `tag` (an `ADDR_WIDTH`‑bit copy of the last filled address)
- `data` (one byte in this teaching design)
- `valid` (set on fill)
- `dirty` (set on write hit or write‑allocate)

**Ports (representative):**
- Inputs: `line_select[3:0]`, `write_enable`, `tag_in`, `data_in`, `set_valid`, `set_dirty_bit`, `clear_dirty_bit`, `reset`  
- Outputs (typical): `data_out`, individual `tag_out_[0..3]`, `valid_[0..3]`, `dirty_[0..3]` for hit logic and eviction.

**Behavior:**
- On **read hit**: `line_select` picks the line; `write_enable=0`; `data_out` drives the byte.
- On **write hit**: update data; set `dirty=1` for that line.
- On **miss refill**: write the fetched byte and tag; set `valid=1`, `dirty=0`.
- On **reset**: clear `valid`/`dirty`; tags/data undefined or zeroed (implementation choice).

---

## 5. Tag Compare (`comparator_logic.v`)

Parallel compare of `address` against tag_out_0..3 gated by each line’s `valid`.  
Outputs:
- `hit` — true if any **match** and that line is valid.
- `hit_lines[3:0]` — one‑hot matches.
- `hit_index[1:0]` — encoded index of the last true in priority order (0..3).

This module is combinational and settles in the same cycle as `LOOKUP` in the FSM.

---

## 6. Replacement (`replacement_policy.v`)

Implements **round‑robin** victim selection:
- Internal `rr_pointer` advances on `update_policy`.
- `replace_index` equals current pointer; during update it returns the *next* value to avoid off‑by‑one reuse.
- On reset, `rr_pointer=0`, `replacement_ready=1`.

This policy is simple, fair, and deterministic—good for grading and waveforms.

---

## 7. Main Memory (`main_memory.v`)

A pedagogical single‑port memory with a **ready** flag:
- On `read_request`: after the designed latency (often 0–1 cycles here), provides `read_data` and asserts `ready`.
- On `write_request`: writes `write_data` and asserts `ready`.
- Bounds checked: sets `error` if `address >= MEM_SIZE` (65,536).

In this design, the cache issues **write‑backs** on dirty evictions and **refills** on misses.

---

## 8. Top‑level Wiring (`fully_associative_cache.v`)

The wrapper instantiates:
- `cache_memory_array` (data/tags/valid/dirty)
- `comparator_logic` (hit detect)
- `replacement_policy` (victim select)
- `main_memory` (backing store)
- `cache_control_fsm` (glue/sequence)

It routes status flags back out as: `hit`, `miss`, and `ready`, and forwards `read_data_signal` to `data_out`.

---

## 9. Verification (`cache_testbench.v`)

The testbench drives `clk/reset`, then a sequence of **reads** and **writes** on `addr`/`data_in` with `read`/`write`. It observes:
- `hit/miss` after LOOKUP
- `ready` for transaction completion
- `data_out` for reads

**What to log/expect (typical):**
1. **Cold read A** → miss, refill line 0, `ready=1`, `data_out=mem[A]`.
2. **Read A again** → hit, immediate `ready=1` and `hit=1`.
3. **Write A** → hit, updates line 0, sets `dirty=1`.
4. **Read B,C,D,E ...** → on the 5th distinct address RR evicts line 0; if dirty, you should see a write‑back, then a refill.

You can extend the bench with directed cases for **dirty eviction**, **write‑miss (write‑allocate)**, and **error** addresses to see the FSM paths.

---

## 10. Timing Notes

- **Combinational**: tag compare (`comparator_logic`).  
- **Registered**: array writes, valid/dirty updates, memory handshakes.  
- **Handshake**: `ready` is asserted only when the current transaction (and any eviction/refill sub‑transactions) has completed.

For waveforms, capture: `state`, `hit`, `hit_index`, `line_select`, `valid_*`, `dirty_*`, `replace_index`, `read_request`, `write_request`, `ready`, `data_out`.

---

## 11. Extensibility

- Increase `BLOCK_SIZE` to model multi‑byte blocks and introduce **byte/word offset** and **burst fills**.
- Replace RR with **LRU/PLRU** inside `replacement_policy`.
- Make `main_memory` multi‑cycle to illustrate **stalls**.
- Add **write‑through** mode to compare policies.

---

*Prepared to accompany the included source files. Parameter defaults in your copy are the authoritative spec; this report mirrors the code at time of writing.*
