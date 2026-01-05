# Clocking & Timebase Library (`lib/clock`)

> WARNING : This library itself was written in collaboration with ChatGPT, 
> and the documentation was written in large part by ChatGPT. While
> an attempt was made to guide it, clean it up, and make sure it is
> factual and correct, a number of inaccuracies are likely to have 
> crept in. Use with care.

This directory contains the **system clocking and timebase infrastructure** used by the design.

The purpose of this library is to provide a **simple, robust, timing-friendly model of time** that works well with:

- iCE40 devices
- yosys + nextpnr
- Single-clock designs
- Enable-based timing (not derived clocks)

The design prioritizes **timing closure, determinism, and clarity** over abstraction or cleverness.

---

## Design philosophy (TL;DR)

- **One real clock** (`clk`)
- **Time is data**, not a clock
- **Periodic behavior uses enables**, not derived clocks
- **All logic is synchronous**
- **Timing closure is a first-class goal**

If you think you need a new non-critical clock, you almost certainly want a **tap + local divider** instead.

---

## High-level architecture

At the center of the system is a single `timebase` module.

```
             ┌──────────────┐
clk ───────► │  timebase    │
             │              │
             │  ticks       │──► timestamps, elapsed time
             │  taps        │──► periodic enables
             └──────────────┘
                    │
                    ▼
             ┌────────────────────┐
             │ Timed modules      │
             │ (counters, FSMs,   │
             │  schedulers, etc.) │
             └────────────────────┘

```

All downstream modules:
- Use **the same `clk`**
- Consume **`taps[]` as clock enables**
- Use **`ticks` only for measurement**

No additional clock domains are created.

---

## Core components

### `rtl/timebase.v`

The **core timekeeping primitive**.

Provides:
- `ticks` — a monotonic system time counter
- `taps`  — log-spaced, single-cycle enable pulses derived from `ticks`

Key properties:
- `ticks(n+1) = ticks(n) + 1` (exact semantics)
- Fixed, deterministic latency
- Structurally pipelined to avoid long carry chains
- Proven to be **non-critical for timing** in a real design


📄 Detailed design and guarantees: 
➡️ [`doc/timebase.md`](doc/timebase.md)

📄 Timing Analysis and Constraints: 
➡️ [`doc/timing.md`](doc/timing.md)

---

### Tap-based timing

`taps[]` are **not clocks**.

Each tap is:
- A **1-cycle pulse**
- Log-spaced in frequency
- Derived from edge detection on `ticks`

They are intended to be used as **clock enables**:

```verilog
always @(posedge clk) begin
    if (taps[TAP]) begin
        // periodic behavior
    end
end
```

📄 Tap selection, dividers, and usage patterns:
➡️ [`doc/taps.md`](doc/taps.md)

📄 Reference table of tap periods vs clock frequency:
➡️ [`doc/frequencies.md`](doc/frequencies.md)

---

## Intended usage

This library is designed for:

- ✔ Periodic tasks (ms → seconds)
- ✔ Counters and schedulers
- ✔ Rate-limited state machines
- ✔ Time-stamping events
- ✔ Low-power, low-toggle designs
- ✔ Designs that must comfortably meet timing on iCE40

---

## Explicit non-goals

This library is **not** intended for:

- ❌ Generating new clocks
- ❌ Clock division via toggling signals
- ❌ Phase-accurate or sub-cycle timing
- ❌ CDC management
- ❌ Protocol-level bit timing

For **cycle-accurate or phase-critical logic**, bypass `timebase` entirely and operate directly from `clk`.

---

### About `archive/`

The files in `archive/` represent **earlier experimental approaches** to timing and event generation. They are preserved for reference only.

They are **not used** because they:

* Introduced long carry chains
* Degraded placement and routing
* Significantly reduced Fmax

The current architecture replaces them entirely.

---

## How to add a timed module

All new timed modules should follow the same pattern:

1. Use `clk` directly
2. Consume `taps[k]` as **clock enables**
3. Use `ticks` for measurement or timestamps
4. Add a **local divider** if exact periods are required
5. Keep all logic synchronous

A **one-page checklist** and a **fully worked, compile-ready example module**
are provided here:

📄 How to Add a Timed Module:
➡️ [`doc/example.md`](doc/example.md)

---

## Design contract (summary)

* `ticks` is a **timestamp**, not a clock
* `taps` are **enables**, not clocks
* There is **one clock domain**
* Latency is fixed and deterministic
* Timing closure is intentional and validated

---

## Status

* ✔ Architecture finalized
* ✔ Timing validated (timebase removed from critical path)
* ✔ Documentation split and complete
* ✔ Ready for reuse across designs

Further abstraction (e.g. reusable utility packages) has been deliberately
deferred due to toolchain fragility and will be revisited only if and when
tool support improves.

---

## Next steps

* Treat `timebase` as the **single source of time**
* Build behavior using **taps + local logic**
* Refer to `frequencies.md` when choosing taps
* Follow the checklist when adding new timed modules

This clocking system is intended to be **boring, predictable, and reliable** — which is exactly what a clocking system should be.
