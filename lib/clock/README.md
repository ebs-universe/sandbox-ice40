# Clock Library

## Overview

This library provides a **deterministic, event-driven clocking and timing framework** for FPGA designs.

It is designed to help you answer, explicitly and safely:

* *How do I represent time?*
* *How do I trigger actions periodically?*
* *How do I avoid clock misuse and accidental CDC?*

The library is opinionated by design. It prioritizes:

* Predictability over flexibility
* Explicit structure over convenience
* Deterministic synthesis over dynamic behavior

---

## Core Idea

The central idea of this library is a strict separation between:

* **Clocks** – drive sequential logic
* **Time** – represented as data (monotonic counters, levels)
* **Events** – single-cycle pulses that trigger behavior

        ┌─────────┐
        │  clock  │
        └────┬────┘
             │
             ▼
        ┌─────────┐
        │  time   │  (ticks, taps)
        └────┬────┘
             │
             ▼
        ┌─────────┐
        │ events  │  (tick)
        └────┬────┘
             │
             ▼
        ┌─────────┐
        │  logic  │
        └─────────┘


Most application logic should be **event-driven**, not clock-driven.

---

## What This Library Provides

At a high level, the library offers:

* A **monotonic timebase** per clock domain
* A small number of **coarse timing taps** (50% duty-cycle levels)
* A mechanism to convert time into **precise, single-cycle events**
* A **clock-aware reset system** with qualification and synchronization
* An optional **prescaler** for generating derived clock domains (advanced use)

These primitives compose cleanly while keeping timing intent explicit.

---

## What This Library Is *Not*

This library does **not** attempt to be:

* A general clock-management framework
* A CDC abstraction layer
* A dynamic or runtime-reconfigurable timing system
* A replacement for PLLs or vendor clock primitives

If your design depends heavily on:

* Arbitrary clock muxing
* High-speed CDC fabrics
* Phase-critical DSP timing

…then this library is likely the wrong abstraction.

---

## Intended Usage Model

Typical usage assumes:

* A primary synchronous clock domain
* One `timebase` per clock domain
* One or more `periodic_tick` instances per domain
* Application logic driven by **events**, not divided clocks

Multiple clock domains are supported, but:

* Timing remains domain-local
* Cross-domain interaction is explicit and disciplined

---

## Repository Structure

```
lib/clock
├── README.md        ← This file
├── doc/             ← Detailed documentation
│   ├── 00-overview.md
│   ├── 01-architecture.md
│   ├── 02-components.md
│   ├── 03-implementation-details.md
│   ├── 04-tap-frequencies-and-accuracy.md
│   ├── 05-usage-examples.md
│   ├── 06-counterindications-and-antipatterns.md
│   ├── 07-cdc-and-multiclock-notes.md
│   ├── 08-timing-semantics-and-design-rules.md
│   ├── 09-reset-and-clock-interaction.md
│   ├── 10-derived-clocks-and-prescalers.md
│   └── 99-faq-and-gotchas.md
└── rtl/
    ├── timebase.v
    ├── periodic.v
    ├── reset.v
    └── prescaler.v
```

---

## How to Read the Documentation

* **New users**:
  Start with `doc/00-overview.md` and `doc/01-architecture.md`

* **Application designers**:
  Focus on `doc/05-usage-examples.md` and `doc/08-timing-semantics-and-design-rules.md`

* **RTL reviewers / maintainers**:
  Read `doc/03-implementation-details.md`

* **Multiclock systems**:
  Read `doc/07-cdc-and-multiclock-notes.md` *before writing logic*

---

## Design Philosophy (Short Version)

* Do not generate clocks unless you must
* Do not use levels when you need events
* Do not hide timing intent inside local counters
* Do not cross clock domains accidentally

If timing behavior is explicit, bugs become rare.

---

## Status and Evolution

This library is designed to evolve conservatively.

Future changes may include:

* Optional registered tick outputs
* Additional helper variants
* Tooling or analysis support

Backwards-incompatible changes are avoided unless strictly necessary.

---

## Final Note

This library exists because clocking mistakes are:

* Easy to make
* Hard to debug
* Expensive to fix late

If you follow the model it enforces, timing becomes boring —
and boring timing is good timing.
