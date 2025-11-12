# comparator_logic.v — File README

## What this file does
Combinational tag comparator across all lines. Determines whether the address hits any valid line and encodes the winning index.

## Key ports & signals
- **Inputs:** `address`, `tag_out_0..3`, `valid_0..3`
- **Outputs:** `hit`, `hit_lines[3:0]`, `hit_index[1:0]`

## How it works (in brief)
Builds one-hot match lines using `(valid_i && tag_out_i == address)`. Reduces them to `hit` and encodes the last active bit into `hit_index`.

## How to read its outputs
- `hit=1` implies exactly one (or more) `hit_lines` bit is set; the FSM treats it as the selected index (`hit_index`).

---

**Testing tip:** Exercise resets first, then a read hit, a write hit, and finally a miss+refill to see all code paths.
