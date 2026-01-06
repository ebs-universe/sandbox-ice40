# Timing Semantics and Design Rules

## Scope

This document consolidates the architectural and implementation details into a set of **explicit timing semantics** and **design rules**.

It answers:

* What signals *mean* in time
* How they are expected to be consumed
* What rules must be followed to preserve correctness

This is the closest thing to a “specification” in the library.

---

## Timing Semantics

### Clocks

A clock is:

* A periodic signal
* Routed through dedicated clock infrastructure
* Used only to clock sequential logic

In this library:

* Clocks are created only at the top level or via explicit primitives
* Application logic must not create or derive clocks implicitly

---

### Time (`ticks`)

`ticks` represents:

* A **monotonic measure of time**
* Expressed as data
* Incremented once per clock cycle

Semantics:

* Synchronous to the domain clock
* Stable for the full cycle
* Safe to sample anywhere in the domain

`ticks` answers:

* “How much time has elapsed?”

It does **not** answer:

* “Should something happen now?”

---

### Taps

`taps` represent:

* **Coarse time levels**
* Derived from bits of `ticks`
* 50% duty-cycle signals

Semantics:

* Levels, not pulses
* High for many cycles
* Phase determined by reset

`taps` answer:

* “Are we in this half of the interval?”

They do **not** answer:

* “Has the interval just elapsed?”

---

### Events (`tick`)

`tick` represents:

* A **single-cycle event**
* Generated intentionally from time levels

Semantics:

* Asserted for exactly one cycle
* Aligned to the domain clock
* Safe to use as a trigger

`tick` answers:

* “Something should happen now.”

---

## Registered vs Combinational Signals

### Registered Signals

Registered signals:

* Are sampled on clock edges
* Have well-defined setup/hold relationships
* Are preferred for timing-critical logic

In this library:

* `ticks`
* `taps`
* Internal state of `periodic_tick`

are all registered.

---

### Combinational Expressions

Some outputs (e.g. `tick`) are combinational expressions of registered signals.

Implications:

* They are still synchronous
* But may require registration depending on usage
* Consumers must understand their own timing depth

This is an explicit design choice, not an oversight.

---

## Level vs Edge Semantics

### Level Semantics

Level-sensitive logic reacts to:

* Signal being high
* Duration of assertion

Used appropriately for:

* Mode selection
* State qualification

Dangerous for:

* Timing
* Sequencing
* Event control

---

### Edge Semantics

Edge-sensitive logic reacts to:

* Transitions
* Singular moments in time

Used for:

* FSM stepping
* Counters
* One-shot actions

**All time-based behavior in this library is edge-based.**

---

## Reset Semantics

Reset semantics in this system are:

* Asynchronous assert
* Synchronous deassert
* Domain-local

Reset guarantees:

* Known starting state
* Known timing phase within a domain

Reset does **not** guarantee:

* Alignment across domains
* Event synchronization
* Safe data transfer

Reset is not a timing signal.

---

## Registration Guidance for `tick`

### When Registration Is Required

Register `tick` when:

* Driving FSM transitions
* Feeding deep or pipelined logic
* Crossing clock domains
* Multiple conditions depend on it

---

### When Registration Is Optional

Registration may be omitted when:

* Used as a simple enable
* Consumed by shallow logic
* Latency is critical and well-understood

The decision is a **design choice**, not a library default.

---

## Clock Domain Boundaries

Clock domain boundaries are **semantic boundaries**.

Rules:

* Timing signals never cross domains directly
* Events are regenerated locally when possible
* CDC is treated as data transfer

Any logic spanning domains must:

* Be explicit
* Be documented
* Use standard CDC patterns

---

## Design Rules (Normative)

### MUST

* All application logic MUST be synchronous to a declared clock
* `ticks`, `taps`, and `tick` MUST remain within their clock domain
* Time-based behavior MUST be event-driven
* CDC MUST be explicit and localized
* Reset deassertion MUST be synchronous

---

### MUST NOT

* Taps MUST NOT be used as enables
* Taps MUST NOT be used as clocks
* `tick` MUST NOT be treated as a clock
* Timing signals MUST NOT cross domains directly
* Reset MUST NOT be used as a timing mechanism

---

### SHOULD

* Prefer duplicating `periodic_tick` over sharing
* Centralize ticks only when phase matters
* Register `tick` when in doubt
* Keep CDC boundaries narrow
* Document timing intent

---

### MAY

* Use derived clocks (`prescaler`) when event timing is insufficient
* Centralize tick generation for phase-coupled logic
* Regenerate timing locally instead of transferring events

---

## Reasoning About Timing

When reviewing a design, ask:

1. Where does time come from?
2. Where does time become an event?
3. What reacts to that event?
4. Does anything cross a clock boundary?
5. Is that crossing explicit and safe?

If any answer is unclear, the design likely violates these rules.

---

## Summary

This library enforces a disciplined timing model:

* Clocks create time
* Time creates events
* Events drive behavior

By respecting these semantics and rules:

* Timing behavior becomes predictable
* CDC bugs become rare
* Designs scale cleanly

The next sections cover **reset interaction**, **derived clocks**, and finally a **FAQ and common pitfalls**.

