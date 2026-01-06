# Clocking Library — Overview

## Purpose

This library provides a **deterministic, synthesis-friendly clocking and timing framework** for FPGA designs that operate primarily within a **single synchronous clock domain**, while still allowing controlled use of multiple clock domains when required.

Its core goal is to **separate the notion of time from the notion of clocks**, and to make the transition from “time” to “events” explicit, auditable, and safe.

---

## Design Motivation

FPGA designs frequently suffer from timing- and clock-related issues that arise not from tool limitations, but from **unclear semantics**:

* Level signals used where events are intended
* Divided clocks treated as enables
* Ad-hoc counters duplicated across modules
* Accidental clock-domain crossings (CDC)

This library addresses these problems by construction.

---

## Core Design Principles

### 1. Single-Clock–First Architecture

The default and preferred operating model is:

* One **primary system clock**
* All application logic synchronous to that clock
* No implicit clock generation inside application modules

Multiple clock domains are **supported**, but only:

* Explicitly
* Deliberately
* At clearly documented boundaries

---

### 2. Time Is Not a Clock

A central principle of this library is:

> **Time is represented as data, not as a clock.**

* Free-running clocks are expensive, hard to analyze, and easy to misuse.
* Most logic does not need a new clock — it needs **periodic events**.

Accordingly:

* Clocks are generated sparingly
* Time is tracked using counters
* Events are generated explicitly and consumed synchronously

---

### 3. Explicit Conversion: Levels → Events

The system enforces a clear separation between:

* **Level-based timing signals**
  (monotonic counters, divided taps, 50% duty-cycle signals)

and

* **Event-based timing signals**
  (single-cycle pulses suitable for FSMs, counters, and strobes)

The conversion from level → event is **centralized** and intentional.

> There is exactly one conceptual place where “time becomes an event”.

---

### 4. Determinism Over Flexibility

All timing decisions that can be made at elaboration time **are made at elaboration time**:

* Tap selection
* Divider selection
* Bit positions
* Counter widths

This ensures:

* Fully deterministic synthesis results
* No runtime variability
* No hidden feedback paths

---

## What This Library Provides

At a high level, the library offers:

* A **monotonic timebase** driven by a system clock
* A small set of **evenly spaced timing taps**
* A mechanism to generate **precise, single-cycle periodic events**
* A reset system that is **synchronous, qualified, and clock-aware**
* Optional support for **derived clock domains**, when truly required

These primitives are designed to compose cleanly and predictably.

---

## What This Library Does *Not* Try to Do

This library deliberately does **not** attempt to:

* Abstract away clock domains
* Automatically handle arbitrary CDC
* Replace PLLs, clock managers, or vendor primitives
* Provide dynamically reconfigurable clocks
* Support “clock-as-data” designs

If your application requires:

* Aggressive clock gating
* Arbitrary clock muxing
* High-speed CDC fabrics
* Asynchronous logic design

…then this library is likely **not the right abstraction**.

---

## Intended Operating Context

Typical assumptions for designs using this library:

* External reference clock: **~12 MHz**
* Internal system clock (`sys_clk`): **≤ 48 MHz** recommended
* Practical critical-path ceiling: **~75 MHz**
* Internal PLL used for:

  * Clock cleanup
  * Multiplication to a stable system clock

All internal logic is expected to meet synchronous timing at the chosen system frequency.

---

## Clock Domains and Scope

The library supports multiple clock domains by **replication, not sharing**:

* Each clock domain maintains its own timebase
* Timing signals do **not** cross domains implicitly
* Cross-domain interaction is treated as a **data transfer problem**

Clock-domain crossing is not forbidden — but it is **never accidental**.

---

## Document Structure

The remainder of the documentation is split as follows:

* **Architecture**: mental model and invariants
* **Components**: module contracts and guarantees
* **Implementation details**: how the RTL works
* **Accuracy and error**: what timing precision to expect
* **Usage examples**: correct patterns
* **Anti-patterns**: what not to do, and why
* **CDC notes**: where care is required
* **Reset interaction**: reset as a clock-adjacent system
* **Derived clocks**: when and how to step outside the model

Each section is intentionally focused and self-contained.

---

## Reading Guidance

* If you are **using** the library:
  Start with *Architecture* and *Usage Examples*.

* If you are **reviewing or modifying** the RTL:
  Read *Implementation Details* and *Timing Semantics*.

* If you are integrating **multiple clock domains**:
  Read *CDC and Multiclock Notes* before writing any logic.

---

## Summary

This library is opinionated by design.

It trades:

* Flexibility for predictability
* Convenience for correctness
* Implicit behavior for explicit structure

In return, it provides a clocking and timing foundation that is:

* Easy to reason about
* Easy to review
* Hard to misuse accidentally

The following sections make those opinions precise.
