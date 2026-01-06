# Architecture

## Scope and Intent

This document defines the **architectural model** of the clocking library:
what exists, what is allowed, and what invariants all users of the library must respect.

It does **not** describe implementation details or usage examples. Those are covered in later sections.

---

## Architectural Overview

At a high level, the clocking system is organized around three ideas:

1. **Clock domains are explicit**
2. **Time is represented as data**
3. **Events are generated deliberately**

The architecture enforces a unidirectional flow:

#### Clock domain (example)

┌──────────────────────────────────────────┐
│                clk                       │
│                                          │
│  ┌───────────┐      ┌───────────────┐    │
│  │ timebase  │─────▶│ periodic_tick │───▶ event
│  │           │ taps │               │    │
│  └───────────┘      └───────────────┘    │
│          │                               │
│          └──────────▶ ticks              │
│                                          │
│              application logic           │
└──────────────────────────────────────────┘

**Architectural invariant:**  
Time (`ticks`, `taps`) never drives behavior directly.  
Only events (`tick`) do.

Each stage has a clear owner and a clearly defined interface.

---

## Clock Domains

### Definition

A *clock domain* is defined as all logic driven by a single clock signal.

In this library:

* Each clock domain is treated as **independent**
* No assumptions are made about frequency, phase, or relationship to other domains
* Each domain owns its own timing infrastructure

---

### Primary System Clock Domain

Most designs will have a **primary system clock domain**, typically:

* Generated from an external reference clock
* Conditioned using a PLL
* Operating at ≤ 48 MHz (recommended)

This domain hosts:

* The canonical `timebase`
* Most application logic
* Most `periodic_tick` instances

---

### Secondary and Tertiary Clock Domains

Additional clock domains (e.g. internal oscillators) are supported by **replicating**, not sharing:

* Each domain has:

  * Its own clock
  * Its own reset
  * Its own `timebase`
  
* No timing signals cross domains implicitly

This replication is intentional: it prevents accidental CDC and preserves local determinism.

---

## Timebase: Representing Time as Data

### Monotonic Time

Within each clock domain, time is represented by a **monotonic counter**:

* Incremented once per clock cycle
* Never resets except under explicit reset
* Wide enough to serve as a long-running reference

This counter forms the canonical notion of “time” for that domain.

---

### Taps: Coarse Time Levels

From the monotonic counter, a small number of **taps** are derived:

* Each tap is a single bit of the time counter
* Taps are:

  * Evenly distributed across the counter width
  * 50% duty-cycle square waves
  * Fully synchronous to the domain clock

Taps are **levels**, not events.

They answer questions like:

* “Has enough time passed?”
* “Are we in the upper or lower half of this interval?”

They do **not** answer:

* “Should something happen *now*?”

---

### Architectural Invariant

> **Taps must never be treated as events.**

Any logic that requires a moment in time must not consume taps directly.

---

## Events: Making Time Actionable

### Event Definition

An *event* is a signal that:

* Is asserted for exactly one clock cycle
* Has unambiguous timing
* Can safely drive counters, FSMs, and strobes

Events are the only form of time that application logic should consume.

---

### Periodic Event Generation

The conversion from:

* time levels (taps)
  to
* events (ticks)

is performed explicitly. This may be done centrally or individually per consumer. Performing it centrally is usually better in terms of resource utilization when multiple resources require the same frequency tick, but may complicate application design. As such, centrally generated ticks are generally recommended only when consumers require a fixed phase relationship, and tick generation is kept intentionally inexpensive to allow duplication for most consumers. 

This conversion:

* Detects edges
* Applies division
* Produces a single-cycle pulse

This step is **architecturally significant** and must never be implicit.

---

### Architectural Invariant

> **There is exactly one conceptual boundary where time becomes an event.**

This boundary exists per clock domain.

---

## Separation of Concerns

The architecture deliberately separates responsibilities:

| Concern              | Owned by                      |
| -------------------- | ----------------------------- |
| Clock generation     | Top-level / vendor primitives |
| Time tracking        | `timebase`                    |
| Event generation     | `periodic_tick`               |
| Application behavior | User logic                    |

No module is allowed to span these concerns implicitly.

---

## Reset as a Clock-Adjacent System

Reset is treated as a **clock-adjacent system**, not as part of timing itself:

* Reset is synchronized per clock domain
* Reset dominates time generation
* Reset establishes a known temporal phase

Importantly:

* Reset is **not** used to align time across domains
* Reset does **not** remove the need for CDC discipline

The interaction between reset and clocks is covered in detail in a dedicated section.

---

## Multi-Domain Architecture and CDC

The architecture assumes:

* Multiple clock domains may exist
* Communication between them is sometimes necessary

However:

* Timebases are strictly domain-local
* Taps and ticks never cross domains
* Cross-domain interaction is always treated as **data transfer**

CDC is therefore:

* Explicit
* Localized
* Auditable

This is a direct consequence of the architectural separation between clocks, time, and events.

---

## What This Architecture Guarantees

If the architectural rules are followed, the system guarantees:

* Deterministic timing behavior
* No accidental CDC
* Clear timing intent
* Easy reasoning about “when” something happens

These guarantees are **structural**, not tool-dependent.

---

## What This Architecture Forbids

By design, the architecture forbids:

* Using divided clocks as enables
* Treating time levels as events
* Sharing timing signals across modules implicitly
* Generating clocks inside application logic
* Crossing clock domains without explicit CDC handling

Violations of these rules are considered **design errors**, not advanced usage.

---

## Summary

The clocking architecture is intentionally conservative:

* It centralizes complexity
* It limits expressiveness where ambiguity would arise
* It favors explicit structure over convenience

The result is a system where:

* Time is observable
* Events are intentional
* Clocking mistakes are hard to make accidentally

The next section defines the **public contracts** of the individual components that implement this architecture.
