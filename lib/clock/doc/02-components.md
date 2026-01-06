# Components

## Scope

This document describes the **public-facing components** of the clocking library and the contracts they establish with the rest of the system.

The focus here is on:

* Interfaces
* Guarantees
* Non-guarantees
* Intended usage

Implementation details are intentionally deferred to later sections.

---

## Component Overview

The clocking library is composed of the following core modules:

| Module          | Role                                                |
| --------------- | --------------------------------------------------- |
| `timebase`      | Monotonic time representation and timing taps       |
| `periodic_tick` | Conversion of time levels into periodic events      |
| `reset`         | Clock-aware reset qualification and synchronization |
| `prescaler`     | Optional derived-clock generator (advanced use)     |

Each module has a **single responsibility** and is designed to compose predictably with the others.

---

## `timebase`

### Role

`timebase` is the **authoritative source of time** within a clock domain.

It converts a free-running clock into:

* A monotonic time counter
* A small set of evenly distributed timing taps

It does **not** generate events.

---

### Interface

**Inputs**

* `clk`
  Clock for the domain
* `reset_n`
  Active-low synchronous reset for the domain

**Outputs**

* `ticks [26:0]`
  Monotonic time counter
* `taps [NTAPS-1:0]`
  Evenly spaced timing levels

---

### Guarantees

* `ticks` increments by exactly one per `clk` cycle
* `ticks` is monotonic between resets
* Each tap:

  * Is synchronous to `clk`
  * Has ~50% duty cycle
  * Divides the clock by a power of two
* Tap positions are deterministic and fixed at elaboration time
* All outputs are registered

---

### Non-Guarantees

* No guarantees about absolute time accuracy
* No guarantees about tap phase alignment across resets
* No guarantees across clock domains
* No event semantics

---

### Intended Usage

* Long-running time reference
* Source of coarse timing levels
* Input to `periodic_tick`
* Debug and instrumentation timing

---

### Explicit Non-Usage

`timebase` must **not** be used to:

* Generate clock enables directly
* Drive FSM transitions directly
* Act as a clock source
* Cross clock domains

---

## `periodic_tick`

### Role

`periodic_tick` converts **time levels into events**.

It produces a **single-cycle pulse** (`tick`) at a requested periodic interval, derived from `timebase` taps.

---

### Interface

**Inputs**

* `clk`
  Clock of the domain
* `reset_n`
  Active-low synchronous reset
* `taps [NTAPS-1:0]`
  Timing taps from the local `timebase`

**Outputs**

* `tick`
  One-cycle event pulse

---

### Guarantees

* `tick` is asserted for exactly one clock cycle
* `tick` is synchronous to `clk`
* Tick period is deterministic given:

  * `CLK_HZ`
  * `PERIOD_US`
  * `NTAPS`
  * `MAX_DIV`
* Tap and divider selection is performed at elaboration time
* No runtime arithmetic or adaptive behavior exists

---

### Tap Selection Semantics

At elaboration time, `periodic_tick`:

1. Evaluates all available taps
2. Computes the ideal divider for each tap
3. Quantizes the divider within allowed limits
4. Selects the tap/divider pair that minimizes absolute timing error

This process is:

* Deterministic
* Fully synthesizable
* Independent of runtime behavior

---

### Quantization and Limits

* Very short periods may saturate the divider minimum
* Very long periods may saturate the divider maximum
* High frequencies increase quantization error due to tap granularity

In these cases:

* The selected configuration is still deterministic
* But may not meet application requirements

---

### Manual Tap / Divider Selection (Future Option)

Some applications may require:

* Known phase relationships
* Fixed divisors
* CDC-friendly boundaries
* Explicit control over tap choice

While the current implementation does **not** expose manual selection, this is a plausible future extension.

Until then, applications requiring such control should:

* Implement custom logic
* Or generate ticks externally

---

### Tick Registration Guidance

The `tick` output is a **combinationally derived registered signal**.

Consumers must decide whether to register it further:

**Registration is recommended when:**

* Driving FSM state transitions
* Crossing clock domains
* Feeding multi-cycle logic
* The consumer logic is deeply pipelined

**Registration is usually unnecessary when:**

* Driving simple counters
* Acting as a strobe for single-cycle actions
* Used purely as an enable

A future version of the library may optionally register `tick` internally if usage patterns show this is universally required.

**Summary**

| Use case | Register `tick`? |
|--------|------------------|
| FSM transitions | Yes |
| CDC boundary | Yes |
| Counter enable | Optional |
| Single-cycle strobe | Optional |


---

### Explicit Non-Usage

`periodic_tick` must **not** be used to:

* Generate clocks
* Drive asynchronous logic
* Cross clock domains without CDC handling
* Replace a proper clock divider

---

## `reset`

### Role

`reset` is a **clock-adjacent system management module**.

It provides:

* Safe synchronization of external reset
* PLL lock qualification
* Minimum reset assertion time

It does **not** generate clocks or timing events.

---

### Interface

**Inputs**

* `clk`
  Clock of the domain
* `pll_lock`
  Indicates stable clock generation
* `ext_reset_n`
  Asynchronous external reset

**Outputs**

* `reset_n`
  Active-low synchronous reset

---

### Guarantees

* Asynchronous assertion, synchronous deassertion
* Reset remains asserted until:

  * External reset is released
  * PLL is locked
  * Minimum assertion time is met
* Reset is synchronous to `clk` on deassertion

---

### Architectural Role

* Establishes a known temporal starting point
* Dominates timebase initialization
* Prevents early logic activation before clock stability

Reset behavior is **clock-domain–local** and does not imply temporal alignment across domains.

---

## `prescaler`

### Role

`prescaler` generates a **derived clock** by dividing an input clock.

This module exists as an **escape hatch** for applications that cannot be expressed using event-based timing alone.

---

### Interface

**Inputs**

* `clk_in`
  Source clock

**Outputs**

* `clk_out`
  Divided clock (new domain)

---

### Guarantees

* `clk_out` is a free-running divided clock
* ~50% duty cycle
* Deterministic frequency division

---

### Limitations and Warnings

* `clk_out` is:

  * A separate clock domain
  * Not routed through a global clock buffer
* Clock skew and routing delays apply
* CDC handling is required when interacting with other domains

---

### Intended Usage

Appropriate use cases include:

* Extremely slow always-on logic
* External interfaces requiring a clock pin
* Legacy blocks that cannot consume event pulses

---

### Explicit Non-Usage

`prescaler` should **not** be used:

* As a general replacement for `periodic_tick`
* For intra-domain timing
* Without careful CDC design

---

## Summary

Each component in the clocking library:

* Has a narrow, well-defined responsibility
* Makes strong guarantees within its scope
* Avoids hidden behavior or implicit coupling

Used together, these components form a clocking system that is:

* Predictable
* Deterministic
* Difficult to misuse accidentally
