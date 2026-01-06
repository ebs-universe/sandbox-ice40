# Tap Frequencies and Accuracy

## Scope

This document explains:

* How tap frequencies are derived
* What accuracy can and cannot be expected
* Where quantization error comes from
* How that error propagates into `periodic_tick`

The goal is to make timing behavior **predictable**, not “precise by accident”.

---

## Fundamental Assumption

All timing in this library is ultimately derived from a **single input clock**.

If the input clock frequency is inaccurate, unstable, or drifting, **all derived timing inherits those properties**.

This library does **not** correct clock inaccuracy — it preserves it deterministically.

---

## Tap Frequency Derivation

### Source of Taps

Each tap corresponds to a **single bit of the monotonic counter**:

* Bit `n` toggles every `2ⁿ` cycles
* Produces a ~50% duty-cycle square wave

For a clock frequency `Fclk`:

```
Tap(n) frequency = Fclk / 2⁽ⁿ⁺¹⁾
```

---

### Example (12 MHz clock)

| Counter bit | Frequency | Period   |
| ----------- | --------- | -------- |
| bit 0       | 6.000 MHz | 166.7 ns |
| bit 5       | 187.5 kHz | 5.33 µs  |
| bit 10      | 5.86 kHz  | 170.7 µs |
| bit 15      | 183 Hz    | 5.46 ms  |
| bit 20      | 5.72 Hz   | 174.6 ms |
| bit 26      | 0.089 Hz  | 11.2 s   |

These values are exact given an exact input clock.

---

## Tap Placement Strategy

Taps are **evenly distributed across the counter width**, not clustered at the LSBs.

    ticks[26:0]
    │
    │  bit positions
    │  0        6        13       19       26
    │  │        │        │        │        │
    ▼  ▼        ▼        ▼        ▼        ▼
    taps[0]   taps[1]  taps[2]  taps[3]  taps[NTAPS-1]

Exact positions depend on `NTAPS`, but spacing is deterministic and fixed at elaboration time.

This ensures:

* Coverage across several orders of magnitude
* Reasonable granularity for both short and long periods
* Predictable tap availability regardless of `NTAPS`

However:

* Taps are still restricted to powers of two
* Arbitrary frequencies are not directly representable

This is a deliberate tradeoff.

---

## Accuracy of Taps

### Ideal Case

If the input clock is exact:

* Tap frequencies are **exact**
* Duty cycle is exactly 50%
* No accumulated drift exists

There is **zero mathematical error** at the tap level.

---

### Practical Sources of Error

In practice, accuracy is limited by:

1. External clock tolerance (ppm)
2. PLL multiplication/division error
3. Temperature and voltage drift
4. Internal oscillator accuracy (if used)

These errors are **external to the library**.

The library neither amplifies nor mitigates them.

---

## Periodic Tick Accuracy

`periodic_tick` introduces **quantization error** intentionally and predictably.

This error arises from:

1. Tap granularity
2. Divider quantization

---

### Quantization Mechanism

For a given tap:

```
Actual period = Tap period × Divider
```

The divider must be an integer, bounded by `MAX_DIV`.

Therefore:

* Exact matches are not always possible
* The closest representable period is selected

---

### Error Metric

The selection algorithm minimizes:

```
| actual_period − requested_period |
```

This is:

* Absolute error
* Measured in microseconds
* Deterministic at elaboration time

---

## Typical Error Magnitudes

### Rule of Thumb

* **Lower frequencies** → lower relative error
* **Higher frequencies** → higher relative error
* Error increases when:

  * Divider saturates
  * Tap spacing becomes coarse

---

### Example: 12 MHz clock

| Requested period | Typical error |
| ---------------- | ------------- |
| 1 s              | < 0.01%       |
| 100 ms           | < 0.05%       |
| 10 ms            | < 0.2%        |
| 1 ms             | < 1%          |
| 100 µs           | several %     |

These are representative, not worst-case bounds.

---

### Upper Practical Limit

While mathematically valid up to several hundred kHz:

* Frequencies above ~100 kHz are **not recommended**
* Error becomes dominated by tap granularity
* Jitter becomes noticeable relative to period

This is consistent with the intended use of the library.

---

## Phase Characteristics

### Tap Phase

* Tap phase is reset-dependent
* No guarantee of absolute phase across resets
* Phase is consistent within a single run

---

### Tick Phase

* Tick phase is deterministic relative to:

  * Reset
  * Tap selection
  * Divider
* Two `periodic_tick` instances with identical parameters:

  * May or may not be phase-aligned
  * Should not be assumed to be aligned unless explicitly designed so

If fixed phase alignment matters:

* Centralized tick generation is preferred
* Or explicit phase logic must be added

---

## Error Is Not Drift

A critical distinction:

> **Quantization error is constant, not cumulative.**

* The period is slightly off
* But it is off by the same amount every time
* There is no accumulated drift over time

This makes behavior:

* Measurable
* Repeatable
* Easy to reason about

---

## Choosing Parameters Intentionally

To minimize error:

* Prefer longer periods
* Allow larger `MAX_DIV`
* Avoid operating near divider limits
* Prefer centralized ticks when phase matters
* Avoid internal oscillators for precision timing

If precision beyond these limits is required:

* A different timing strategy is needed

---

## Summary

* Tap frequencies are exact powers of two of the input clock
* Taps themselves introduce no mathematical error
* `periodic_tick` introduces bounded, deterministic quantization error
* Error does not accumulate or drift
* Accuracy is sufficient for:

  * Human-scale timing
  * Control loops
  * Scheduling and pacing

This section defines **what accuracy to expect**, so that later usage decisions are informed and deliberate.

