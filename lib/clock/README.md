# Clocking Library (`lib/clock`)

This directory contains the **system clocking and timebase infrastructure** for the design.

The goal of this library is to provide:

- A **single, clean clock domain**
- A **monotonic system time reference**
- A scalable way to generate **periodic events** without derived clocks
- Excellent timing behavior on **iCE40 (yosys + nextpnr)**

This library is deliberately conservative in structure and avoids techniques
that are known to degrade timing or introduce CDC hazards.

---

## High-level architecture

At the top level, the clocking system is organized around **one global clock**
and **one global timebase**.

```
           ┌──────────────┐
clk ─────► │  timebase    │
           │              │
           │  ticks[ ]    │──► time measurements, timestamps
           │  taps[ ]     │──► periodic enables
           └──────────────┘
                  │
                  ▼
          ┌─────────────────┐
          │ Local modules   │
          │ (counters,      │
          │  event gens,    │
          │  state machines)│
          └─────────────────┘

```

### Design principles

- **One clock** only (no derived clocks)
- **All logic synchronous** to that clock
- **Time is data**, not a clock
- **Periodic behavior is enable-based**, not clock-based

---

## Core components

### `rtl/timebase.v`

The **heart of the system**.

Provides:

- `ticks` — a monotonic, fixed-latency system time counter
- `taps`  — log-spaced, single-cycle enable pulses derived from `ticks`

Key properties:

- Exact semantics: `ticks(n+1) = ticks(n) + 1`
- Fixed, deterministic latency
- Structurally pipelined to avoid long carry chains
- Proven to be **non-critical for timing** in a real design

Full details:  
📄 `doc/timebase.md`

---

### Tap-based event generation

`taps` are **not clocks**.  
They are **clock enables** derived from edge detection on `ticks`.

Typical usage pattern:

```verilog
always @(posedge clk) begin
    if (taps[TAP]) begin
        // do something periodically
    end
end
````

This pattern:

* Preserves a single clock domain
* Avoids CDC issues
* Synthesizes efficiently on iCE40
* Scales cleanly with frequency

Tap selection, divider strategy, and tradeoffs are documented in:

📄 `doc/taps.md`

---

## Intended usage model

### What this library is for

✔ Generating periodic events (ms, 10s of ms, seconds, etc.)
✔ Driving counters, state machines, schedulers
✔ Time-stamping events
✔ Rate-limiting operations
✔ Low-power, low-toggle designs
✔ Designs that must close timing comfortably on iCE40

---

### What this library is *not* for

❌ Generating new clocks
❌ Clock division via toggling signals
❌ Phase-accurate timing
❌ Asynchronous timing control
❌ Multi-clock CDC management

If you think you need a new clock, you almost certainly want a **tap + enable** instead.

---

## Why this approach

This library exists because several **earlier approaches failed**:

* Wide monolithic counters
* Derived clocks
* Multi-stage event generators
* “Clever” parameterized abstractions

Those approaches are preserved in `archive/` for reference, but they are
**not used** because they:

* Introduced long carry chains
* Degraded Fmax significantly

The current design is intentionally:

* Boring
* Explicit
* Structurally constrained

And therefore **fast, predictable, and maintainable**.

---

## How new modules should integrate

When adding a new module that needs timing:

1. **Use `clk` directly**
2. Consume `taps[k]` as a clock enable
3. Use `ticks` for measurement or timestamps
4. Do not generate new clocks
5. Keep all logic synchronous

If you need a new periodic rate:

* Select an appropriate tap
* Add a small local divider if needed

See `doc/taps.md` for more information. A checklist and worked example are available in `doc/example.md`.
---

## Design contract (summary)

* `ticks` is a **timestamp**, not a clock
* `taps` are **enables**, not clocks
* All logic stays in one clock domain
* Latency is fixed and deterministic
* Timing closure is a first-class goal

---

## Status

* ✔ Architecture finalized
* ✔ Timing validated
* ✔ Documentation split and complete
* ✔ Ready for reuse across designs

Further abstraction (e.g. reusable utility packages) has been deliberately
deferred due to toolchain fragility and will be revisited only if and when
tool support improves.

---

## Where to go next

* Start using `timebase` as the **single source of time**
* Build higher-level behavior using **taps + local logic**
* Refer to archived designs only for historical context

This clocking system is intended to be **stable, boring, and reliable** —
which is exactly what a clocking system should be.

```