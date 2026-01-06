# Reset and Clock Interaction

## Scope

This document describes how reset interacts with clocks and timing in this library.

It covers:

* Reset semantics
* Reset synchronization
* Reset qualification
* Reset interaction with timebases and events
* Common reset-related pitfalls

Reset is treated as **clock-adjacent system management**, not as part of the timing model itself.

---

## Role of Reset in This System

Reset exists to:

* Establish a known initial state
* Prevent logic from operating before clocks are stable
* Provide deterministic startup behavior

Reset does **not** exist to:

* Align clocks
* Synchronize time across domains
* Act as a timing signal

This distinction is fundamental.

---

## Reset Is Domain-Local

Each clock domain must have:

* Its own reset logic
* Reset synchronized to that domain’s clock

Even if a single external reset source exists, it is **replicated and synchronized** per domain.

This prevents:

* Metastability on reset deassertion
* Ambiguous startup timing
* Accidental CDC through reset

---

## Reset Assertion and Deassertion Semantics

### Asynchronous Assertion

Reset assertion is asynchronous:

* External reset may be asserted at any time
* Logic must immediately enter a safe state

This ensures:

* Safe recovery from fault conditions
* No reliance on clock availability during assertion

---

### Synchronous Deassertion

Reset deassertion is synchronous:

* Deassertion is aligned to the domain clock
* All logic observes reset release on a clock edge

This ensures:

* Deterministic state transitions
* Clean timing analysis
* No half-cycle ambiguity

        ext_reset_n  ──────┐     ┌────────────
                           └─────┘
        clk            ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐
        reset_n      ───────┐        ┌────────
                            └────────┘

---

## Reset Qualification

### Why Qualification Exists

Reset may be released too early if:

* The PLL is not locked
* The clock is unstable
* External reset pulses are too short

Qualification ensures reset is only released when the system is ready.

---

### Qualification Mechanism

The reset logic:

* Synchronizes external reset
* Synchronizes PLL lock
* Requires reset to be held for a minimum number of cycles

Only when all conditions are met is reset deasserted.

This produces:

* Clean startup
* Predictable timing
* Stable timebase initialization

---

## Interaction with `timebase`

Reset dominates the `timebase`:

* All counters are reset
* All taps return to a known state
* Time always starts from a defined point

However:

* Reset does **not** define absolute time
* Reset does **not** align time across domains
* Timebase phase is domain-local

This ensures internal consistency without creating false guarantees.

---

## Interaction with `periodic_tick`

Reset affects `periodic_tick` by:

* Clearing internal edge detectors
* Clearing divider counters
* Forcing `tick` low

After reset release:

* The first event occurs deterministically
* Phase depends on reset timing and tap selection

Reset does not guarantee:

* Phase alignment across different `periodic_tick` instances
* Simultaneous first tick across domains

---

## Reset and CDC

Reset is **not a CDC solution**.

Important rules:

* Reset deassertion must be synchronized per domain
* Reset must not be used to pass data
* Reset must not be used to align timing

Reset may cross domains only as:

* An asynchronously asserted signal
* With local synchronization and qualification

---

## Multiple Clock Domains and Reset

In systems with multiple clock domains:

* Reset logic is instantiated per domain
* Each domain qualifies reset independently
* Domains may exit reset at different times

This is intentional and correct.

Any logic that depends on inter-domain coordination must:

* Handle this explicitly
* Not rely on reset timing coincidences

---

## Common Reset Anti-Patterns

### Using Reset as a Timing Signal

```verilog
if (!reset_n)
    state <= IDLE;
else if (reset_n && first_cycle)
    do_something();
```

Reset is not a clock or an event.

---

### Assuming Reset Aligns Domains

Releasing reset at the same time does **not** imply:

* Synchronized clocks
* Aligned counters
* Safe data transfer

---

### Using Reset to Force Phase Alignment

Reset establishes a starting point, not a phase contract.

If phase matters:

* Use centralized tick generation
* Or explicit synchronization logic

---

## Design Guidance

* Reset logic should be simple, explicit, and local
* Reset should dominate all timing state
* Reset semantics should be consistent across the design
* Reset behavior should be documented for each domain

When in doubt:

> Treat reset as infrastructure, not behavior.

---

## Summary

Reset in this library:

* Is tightly coupled to clocks
* Establishes safe and deterministic startup
* Does not participate in timing semantics

By keeping reset **separate from time and events**, the design avoids a large class of subtle and dangerous bugs.
