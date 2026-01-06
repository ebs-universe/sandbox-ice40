# CDC and Multiclock Notes

## Scope

This document describes how to **safely interact across clock domains** in systems using this clocking library.

It explains:

* Where clock-domain crossings (CDC) occur
* What may and may not cross domains
* Approved synchronization patterns
* Common failure modes

This is not a generic CDC tutorial; it is specific to the architecture of this library.

---

## Architectural Position on CDC

The clocking library is designed to **avoid CDC by default**.

This is achieved by:

* Keeping timing local to each clock domain
* Replicating timebases instead of sharing them
* Treating inter-domain interaction as data transfer

CDC is supported — but it is **never implicit**.

---

## Clock Domains in a Typical System

A typical system may include:

* A primary system clock domain (`sys`)
* One or more internal oscillator domains (`hfint`, `lfint`)
* Optional derived-clock domains (via `prescaler`)

Each domain:

* Owns its clock
* Owns its reset
* Owns its `timebase`

No timing signals cross these boundaries directly.

---

## What Must Never Cross Clock Domains

The following signals are **strictly domain-local**:

* `ticks`
* `taps`
* `tick` outputs from `periodic_tick`
* Derived clocks used as internal enables

Crossing any of these without proper handling is a design error.

---

## CDC Is a Data Problem

The central principle for CDC in this system is:

> **Clock-domain crossings are treated as data transfer problems, not timing problems.**

    Domain A (clk_a)          Domain B (clk_b)

    event/tick               synchronized data
        │                         │
        ▼                         ▼
    ┌──────────┐             ┌──────────┐
    │  source  │───CDC──────▶│ consumer │
    └──────────┘             └──────────┘

This means:

* No assumptions about phase or frequency
* No reliance on coincidental alignment
* Explicit synchronization logic at boundaries
* Timing signals terminate at the domain boundary. Only data crosses.

---

## Approved CDC Patterns

### 1. Single-Bit Level Synchronization

Use for:

* Configuration flags
* Mode selects
* Status signals

#### Pattern

```verilog
reg [1:0] sync;

always @(posedge clk_dst) begin
    sync <= {sync[0], signal_src};
end

wire signal_dst = sync[1];
```

#### Notes

* Two flip-flops minimum
* Destination-clocked
* No guarantees about transfer latency

---

### 2. Single-Cycle Event Transfer (Pulse Sync)

Use for:

* Occasional events
* Notifications
* Interrupt-like signals

#### Pattern

**Source domain: stretch pulse**

```verilog
reg event_latched;

always @(posedge clk_src) begin
    if (event)
        event_latched <= 1'b1;
    else if (ack)
        event_latched <= 1'b0;
end
```

**Destination domain: synchronize and edge-detect**

```verilog
reg [1:0] sync;

always @(posedge clk_dst) begin
    sync <= {sync[0], event_latched};
end

wire event_dst = sync[1] && !sync[0];
```

#### Notes

* Pulse must be stretched
* Event latency is unbounded
* Event rate must be low enough to avoid overlap

---

### 3. Toggle-Based Event Transfer

Use for:

* Periodic or frequent events
* Low-overhead signaling

#### Pattern

**Source domain**

```verilog
reg event_toggle;

always @(posedge clk_src) begin
    if (event)
        event_toggle <= ~event_toggle;
end
```

**Destination domain**

```verilog
reg [2:0] sync;

always @(posedge clk_dst) begin
    sync <= {sync[1:0], event_toggle};
end

wire event_dst = sync[2] ^ sync[1];
```

#### Notes

* Robust against pulse loss
* One event per toggle
* Requires event spacing

---

### 4. Multi-Bit Control Transfer (Handshake)

Use for:

* Configuration words
* Commands
* State transfer

#### Pattern

* Request / acknowledge handshake
* Data held stable during transfer
* Explicit ownership

#### Notes

* More logic
* Strong guarantees
* Recommended for anything wider than 1 bit

---

## Reset and CDC

Reset is **not** a CDC mechanism.

Important points:

* Reset deassertion is synchronized per domain
* Reset does not align clocks
* Reset cannot be used to “safely” pass timing signals

Reset may cross domains only:

* As an asynchronous assertion
* With local synchronization

---

## Using `periodic_tick` Across Domains

`periodic_tick` outputs must never be crossed directly.

If an event generated in one domain is needed in another:

* Treat it as a pulse or toggle
* Apply one of the patterns above
* Consider regenerating the event locally instead

In many cases:

> Regenerating a periodic event locally is simpler and safer than transferring it.

---

## Derived Clock Domains (`prescaler`)

When using `prescaler`:

* The output clock is a new domain
* CDC rules apply in both directions
* Reset must be domain-local

Derived clocks are inherently more fragile and should be used sparingly.

---

## Common CDC Failure Modes

* Synchronizing pulses without stretching
* Synchronizing multi-bit buses without handshake
* Treating reset as synchronization
* Assuming identical frequencies imply safety
* Sharing timing signals for convenience

These failures are subtle and often intermittent.

---

## Summary

The clocking library enforces a disciplined approach:

* Time is local
* Events are local
* CDC is explicit

When CDC is unavoidable:

* Use standard, well-understood patterns
* Keep boundaries narrow
* Avoid transferring timing signals

The next section consolidates these ideas into **timing semantics and design rules**.
