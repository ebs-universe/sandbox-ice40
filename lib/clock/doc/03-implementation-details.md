# Implementation Details

## Scope

This document explains **how the clocking library realizes the architectural model in RTL**.

It focuses on:

* Structural decisions
* Pipeline boundaries
* Determinism and synthesis behavior
* Timing and resource considerations

This is the section to read when reviewing or modifying the RTL.

---

## `timebase`: Monotonic Time and Taps

### Monotonic Counter Structure

The `timebase` implements a **27-bit monotonic counter**, split into two parts:

* `lo` (12 bits)
* `hi` (15 bits)

These are incremented using a **registered carry pipeline**, rather than a single wide adder.

    clk
    │
    ▼
    ┌──────────┐   carry   ┌──────────┐
    │  lo[11:0]│──────────▶│ hi[14:0] │
    └──────────┘  (reg)    └──────────┘
        │                     │
        └───────────┬─────────┘
                    ▼
                ticks[26:0]


#### Why the split exists

* A single 27-bit incrementer can become a critical path at higher frequencies
* This registered carry is a **physical pipeline boundary**, not a logical one
* This improves fmax without changing semantics

#### Increment sequence

1. `lo` increments every cycle
2. Carry-out from `lo` is detected
3. The carry is registered (`lo_carry_d`)
4. `hi` increments on the following cycle if the carry was asserted
5. `ticks` is published as `{hi, lo}`

This guarantees:

* One increment per cycle
* No combinational carry path across the full width
* Deterministic behavior

---

### Ticks vs Internal State

The internal registers (`lo`, `hi`) are **not directly exposed**.

Instead:

* `ticks` is published as a registered output
* Consumers see a stable, monotonic counter

This avoids:

* Partial updates
* Combinational observation of internal state
* Tool-dependent retiming surprises

---

### Tap Bit Placement

Tap positions are computed **at elaboration time** using:

```
tap_bit(i) = (i * 26) / (NTAPS - 1)
```

Properties of this approach:

* Taps are spread evenly across the counter width
* Lowest tap is always bit 0
* Highest tap is always bit 26
* Intermediate taps are deterministically placed
* No runtime logic exists for tap selection

This ensures:

* Predictable frequencies
* Stable synthesis results
* No dependency on runtime parameters

---

### Tap Generation as Levels

Each tap is implemented as:

* A registered assignment
* Driven from the corresponding `ticks` bit
* Updated once per cycle

Important consequences:

* Taps are **levels**, not pulses
* Each tap has ~50% duty cycle
* Tap edges are aligned to clock edges
* Tap phase is reset-dependent

This design makes taps cheap and stable, but unsuitable for event-driven logic.

---

## `periodic_tick`: Event Generation from Levels

### Architectural Role in RTL

`periodic_tick` is where **time levels are converted into events**.

This happens in three distinct steps:

1. **Tap selection**
2. **Edge detection**
3. **Division and pulse generation**

Each step is explicit and structurally visible in the RTL.

---

### Elaboration-Time Tap and Divider Selection

The most important design decision in `periodic_tick` is that **all timing selection occurs at elaboration time**.

#### Selection algorithm

At elaboration time, the module:

1. Iterates over all taps
2. Computes the tap period in nanoseconds
3. Computes the ideal divider for the requested period
4. Quantizes the divider within `[1, MAX_DIV]`
5. Computes the resulting actual period
6. Selects the tap with minimum absolute error

This is implemented entirely using constant functions.

#### Consequences

* No runtime arithmetic
* No counters wider than necessary
* No adaptive behavior
* Fully deterministic synthesis

The selected `TAP` and `DIV` become localparams.

---

### Quantization Effects

Quantization arises from two sources:

1. **Tap granularity**
   Taps divide time by powers of two

2. **Divider limits**
   Divider is constrained by `MAX_DIV`

As frequency increases:

* Tap resolution becomes coarser
* Divider error becomes more significant

As period increases:

* Divider may saturate
* Error may increase

These effects are predictable and repeatable.

---

### Edge Detection

Taps are levels, so edge detection is required.

Implementation:

* The selected tap is registered (`tap_d`)
* A rising edge is detected using:

  ```
  tap_rise = taps[TAP] && !tap_d
  ```

Why rising edges:

* Exactly one per tap period
* Deterministic phase
* Avoids ambiguity around falling edges

This produces a **clean, single-cycle pulse** per tap period.

---

### Divider Logic

The divider:

* Counts rising edges of the selected tap
* Is only clocked on tap edges
* Resets synchronously

Key properties:

* Divider width is minimal (`$clog2(DIV)`)
* Divider increments only when needed
* Divider has no dependency on full-rate clock toggling

This keeps the logic inexpensive and localized.

---

### Tick Generation

The final `tick` is asserted when:

* A tap rising edge occurs
* The divider reaches its terminal count

The result is:

* Exactly one cycle wide
* Aligned to the system clock
* Deterministic in phase and period

---

### Why `tick` Is Not Internally Registered

The current implementation exposes `tick` as a combinational expression of registered signals.

This choice:

* Minimizes latency
* Avoids unnecessary registers
* Leaves consumption semantics explicit

However, it implies:

* Consumers must understand their timing needs
* Registration may be required downstream

A future library revision may optionally register `tick` internally if this becomes the dominant use case.

---

## `reset`: Clock-Aware Reset Qualification

### Asynchronous Assert, Synchronous Deassert

The reset system implements:

* Asynchronous assertion (for safety)
* Synchronous deassertion (for timing correctness)

This is achieved using:

* A two-flop synchronizer for `ext_reset_n`
* A separate synchronizer for `pll_lock`

---

### Reset Qualification Counter

Reset deassertion is gated by a counter that ensures:

* Reset is held active for a minimum number of cycles
* Clock and PLL stability are established
* Spurious short reset pulses are filtered

This counter is synchronous and deterministic.

---

### Reset Dominance

Reset dominates:

* Timebase initialization
* Event generation
* Application logic startup

However, reset does **not** imply:

* Clock alignment across domains
* Event phase alignment across domains

---

## `prescaler`: Derived Clock Generation

### Implementation Simplicity

`prescaler` is intentionally minimal:

* A synchronous binary counter
* MSB used as output clock

This simplicity is deliberate:

* No gating
* No enable logic
* No dynamic behavior

---

### Consequences of Simplicity

Because of this design:

* `clk_out` is a free-running clock
* Routing is not guaranteed to use global buffers
* Skew and insertion delay apply

This is acceptable only in narrow, intentional use cases.

---

## Resource and Timing Summary

### Resource Characteristics

* `timebase`:

  * Small number of registers
  * No wide combinational logic
* `periodic_tick`:

  * One edge detector
  * One small counter
* `reset`:

  * Few flops
  * One small counter
* `prescaler`:

  * One counter

All modules are inexpensive by design.

---
 
### Timing Characteristics

* Critical paths are intentionally short
* Pipeline breaks are explicit
* No combinational feedback
* All logic is synchronous

Meeting timing is primarily a function of:

* Chosen system clock frequency
* Overall application complexity

---

## Summary

The implementation of the clocking library:

* Mirrors the architectural intent directly
* Avoids hidden complexity
* Prefers structural clarity over cleverness

All timing behavior is:

* Deterministic
* Synchronous
* Inspectable in RTL

The next section quantifies what this implementation means in practice: **frequency accuracy and error**.
