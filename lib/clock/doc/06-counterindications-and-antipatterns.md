# Counterindications and Anti-Patterns

## Scope

This document describes **incorrect or discouraged usage patterns** for the clocking library.

These are not stylistic preferences — they are patterns that:

* Break architectural guarantees
* Introduce ambiguity
* Cause timing bugs that are difficult to diagnose

If you find yourself wanting to do something described here, stop and reassess the design.

---

## Anti-Pattern 1: Using Taps as Enables

### Description

Using a tap directly as an enable:

```verilog
if (taps[3])
    counter <= counter + 1;
```

### Why This Is Wrong

* Taps are **levels**, not events
* A tap is high for many cycles
* The counter increments multiple times per intended period

This creates:

* Multi-cycle activation
* Accidental repeated actions
* Design behavior that depends on tap duty cycle

---

### Correct Pattern

Convert taps into events using `periodic_tick`.

---

## Anti-Pattern 2: Using Taps as Clocks

### Description

Using a tap as a clock:

```verilog
always @(posedge taps[4]) begin
    ...
end
```

### Why This Is Wrong

* Taps are not routed as clocks
* Clock skew and insertion delay are uncontrolled
* Static timing analysis cannot reason about this reliably

This often “works” in simulation and fails in hardware.

---

### Correct Pattern

Keep all logic synchronous to the primary clock and use event pulses.

---

## Anti-Pattern 3: Treating Levels as Events

### Description

Using a level-sensitive condition where a pulse is intended:

```verilog
if (slow_signal)
    state <= NEXT;
```

### Why This Is Wrong

* Level duration depends on unrelated timing
* Multiple transitions may occur
* Behavior changes when frequency changes

---

### Correct Pattern

Use a one-cycle `tick`.

---

## Anti-Pattern 4: Sharing Ticks Without Intent

### Description

Using a single `periodic_tick` instance for unrelated logic:

```verilog
wire tick;

assign module_a_en = tick;
assign module_b_en = tick;
```

### Why This Is Often Wrong

* Implicit coupling between modules
* Phase relationships become accidental dependencies
* Refactoring one consumer affects the other

---

### When This *Is* Acceptable

* When consumers require a fixed phase relationship
* When sharing is intentional and documented

Otherwise, duplication is preferred.

---

## Anti-Pattern 5: Crossing Clock Domains with Taps or Ticks

### Description

Using timing signals across domains:

```verilog
assign other_domain_en = tick;
```

### Why This Is Wrong

* Ticks and taps are domain-local
* No CDC protection exists
* Metastability and event loss are likely

---

### Correct Pattern

Treat cross-domain communication as data transfer:

* Synchronize levels
* Stretch pulses
* Use handshakes

---

## Anti-Pattern 6: Building Ad-Hoc Counters in Application Logic

### Description

Implementing periodic behavior using local counters:

```verilog
if (cnt == 9999)
    cnt <= 0;
else
    cnt <= cnt + 1;
```

### Why This Is Discouraged

* Duplicates functionality already provided
* Increases maintenance burden
* Encourages inconsistent timing semantics

---

### Correct Pattern

Centralize timing intent using `timebase` and `periodic_tick`.

---

## Anti-Pattern 7: Assuming Phase Alignment Across Instances

### Description

Assuming two identical `periodic_tick` instances are phase-aligned.

### Why This Is Wrong

* Reset timing may differ
* Elaboration choices may differ
* Phase is not guaranteed unless explicitly shared

---

### Correct Pattern

* Centralize tick generation if phase matters
* Or explicitly add phase alignment logic

---

## Anti-Pattern 8: Using Reset to Enforce Timing Semantics

### Description

Using reset to “line up” events across domains or modules.

### Why This Is Wrong

* Reset is not a timing mechanism
* Reset does not imply synchronized clocks
* Reset behavior varies per domain

---

### Correct Pattern

Use explicit synchronization or handshake logic.

---

## Anti-Pattern 9: Over-Optimizing for Resource Sharing

### Description

Avoiding multiple `periodic_tick` instances to “save logic”.

### Why This Is Usually Wrong

* `periodic_tick` is intentionally inexpensive
* Sharing introduces coupling and constraints
* Savings are negligible compared to risk

---

### Correct Pattern

Prefer duplication unless phase coupling is required.

---

## Anti-Pattern 10: Treating This as a General Clocking Framework

### Description

Attempting to use this library for:

* Arbitrary clock muxing
* Dynamic frequency changes
* High-speed CDC fabrics

### Why This Is Wrong

* The architecture is intentionally constrained
* These use cases require different primitives

---

## Summary

The anti-patterns documented here all share a common theme:

> **They blur the distinction between clocks, time, and events.**

The clocking library exists to keep those concepts separate and explicit.

If a design requires breaking these rules, it should do so:

* Explicitly
* Locally
* With full awareness of the tradeoffs

The next section explains **how to cross clock domains safely** when such boundaries are unavoidable.

