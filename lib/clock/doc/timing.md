# Timing Analysis and Constraints  

**Target Device: iCE40UP5K**  
**Toolchain: yosys + nextpnr-ice40**

This document describes the **timing model, constraints, and observed limits** of the clocking and timebase system when implemented on an **iCE40UP5K** device.

It is intended to answer the following questions:

- What limits the maximum clock frequency?
- Where are the critical paths?
- Why does the design meet timing comfortably?
- What classes of logic should *not* use the timebase?
- How should timing be re-evaluated as the design evolves?

This document complements:
- [`timebase.md`](timebase.md)
- [`taps.md`](taps.md)
- [`frequencies.md`](frequencies.md)

---

## 1. Timing model overview

### 1.1 Single-clock design

The entire system operates in a **single synchronous clock domain**:

- One physical clock input
- Optional PLL frequency scaling
- No derived clocks
- No gated clocks

All timing analysis therefore reduces to:

```

posedge clk → combinational logic → posedge clk

```

There are no clock-domain crossings within the clocking subsystem itself.

---

### 1.2 Timing intent

The design explicitly prioritizes:

- Short combinational paths
- Structurally enforced pipelining
- Avoidance of wide carry chains
- Enable-based periodic behavior

This is particularly important on iCE40, where:

- Routing delay often dominates logic delay
- Wide adders and comparators scale poorly
- Clock enable paths (`CEN`) are not free

---

## 2. Device-specific considerations (iCE40UP5K)

### 2.1 Relevant architectural limits

The iCE40UP5K fabric has the following practical characteristics:

- 4-input LUTs
- No dedicated carry chains
- Limited register packing
- Global clock network with fixed latency
- Relatively high interconnect delay vs LUT delay

As a result:

- Ripple adders scale poorly beyond ~12–14 bits
- Control-heavy paths (enable/reset muxing) often dominate timing
- Placement and routing can outweigh pure logic depth

---

### 2.2 Implications for this design

These constraints directly informed the final architecture:

| Design choice | Timing motivation |
|--------------|------------------|
Split counters | Limit ripple depth |
Registered carry | Prevent yosys adder collapse |
Tap-based enables | Avoid derived clocks |
Local dividers | Minimize global arithmetic |
Compile-time selection | Remove runtime math |

---

## 3. Timebase timing analysis

### 3.1 Counter structure

The `timebase` counter is implemented as:

- `lo`: 12-bit counter (timing-critical)
- `hi`: 15-bit counter (non-critical)
- Registered carry between `lo` and `hi`

This guarantees:

- Maximum carry propagation depth = **12 bits**
- No combinational path from `lo` → `hi` in the same cycle
- Stable timing regardless of `ticks` width

---

### 3.2 Tap generation paths

Tap pulses are generated via:

- Bit sampling
- Registered previous state
- XOR edge detection
- Registered output

There are **no combinational feedback paths** and no wide fanout from `ticks`.

---

### 3.3 Observed behavior

From multiple synthesis and place-and-route runs:

- `timebase` **does not appear on the critical path**
- The longest paths consistently originate in:
  - Local dividers
  - Counter enable/reset logic
  - Output fanout to IO

This confirms the timebase is **successfully timing-isolated**.

---

## 4. Observed critical paths (real builds)

Based on actual `nextpnr` timing reports:

### 4.1 Typical critical path class

```

register → LUT logic → routing → CEN or D input → register

```

Most commonly:
- Divider counters
- Enable-gated state updates
- Reset / compare logic

Notably:
- Wide arithmetic is no longer dominant
- Routing delay exceeds logic delay in most paths

---

### 4.2 Example breakdown (representative)

| Component | Approx contribution |
|---------|---------------------|
Logic delay | ~4–6 ns |
Routing delay | ~8–12 ns |
Total path | ~14–18 ns |

This aligns with the iCE40 fabric characteristics.

---

## 5. Maximum clock frequency

### 5.1 Observed Fmax

Across multiple builds (25 MHz target clock):

- **Reported Fmax**: ~70–71 MHz
- **Timing margin at 25 MHz**: ~2.8×
- **Timebase contribution**: negligible

This margin is intentional and provides headroom for:
- Additional logic
- Fanout growth
- Feature expansion

---

### 5.2 Practical recommendations

| Use case | Recommendation |
|--------|----------------|
≤ 25 MHz system | Very safe |
25–40 MHz | Comfortable |
40–60 MHz | Possible, review dividers |
\> 60 MHz | Requires careful auditing |

---

## 6. Timing constraints and limitations

### 6.1 What is constrained

Implicit constraints:
- Single clock domain
- All sequential logic synchronous
- No false paths within clocking subsystem

Explicit constraints:
- None required beyond clock period
- No SDC required for taps or ticks

---

### 6.2 What is *not* constrained

- Asynchronous IO paths
- External device timing
- CDC (not present in this subsystem)

These must be handled by consuming modules as appropriate.

---

## 7. When NOT to use the timebase

The timebase should **not** be used for:

- Bit-level protocol timing
- Phase-accurate interfaces
- Sub-cycle control
- Clock generation
- Tight jitter requirements

In such cases:
> Operate directly from `clk` with dedicated logic.

This is explicitly documented to avoid misuse.

---

## 8. How to re-evaluate timing

When the design changes materially:

1. Run `nextpnr-ice40 --timing-allow-fail`
2. Inspect:
   - Top 5 critical paths
   - Logic vs routing split
3. Confirm:
   - `timebase` is not in the critical path
   - Carry chains remain bounded
4. Re-check divider widths in timed modules

If `timebase` reappears in the critical path in any non-trivial design, that likely indicates a regression.

---

## 9. Summary

- The clocking system is **architecturally timing-safe**
- The timebase is **demonstrably non-critical**
- Maximum frequency is limited by **local control logic**, not global timing
- The design aligns with **iCE40UP5K physical realities**
- Timing margins are intentional, not accidental

This document should be updated only if:
- The device changes
- The toolchain changes
- The architectural assumptions change

Otherwise, it serves as a stable reference.

---

## Appendix A — Before / After Comparison with Previous Designs

This appendix contrasts the **current clocking architecture** with **earlier experimental designs**. Those earlier designs were valuable exploration steps, but they exhibited systematic timing failures on iCE40UP5K and are therefore not part of the active library.

### A.1 Summary table

| Aspect | Previous designs  | Current design (`timebase`) |
|------|-------------------------------|-----------------------------|
Clocking model | Multiple derived clocks and/or phase-driven logic | Single physical clock |
Time representation | Clock-like signals | Time as data (`ticks`) |
Periodic behavior | Toggled clocks / phased events | Enable pulses (`taps`) |
Counter structure | Wide monolithic counters | Split counter with registered carry |
Carry depth | 26–32 bits | 12 bits (bounded) |
Adder collapse risk | High | Structurally prevented |
Enable/reset logic | Distributed and implicit | Local and explicit |
Critical path | Global counters / clock logic | Local dividers / control |
Routing pressure | Very high | Controlled and localized |
Observed Fmax | ~40-55 MHz | ~70 MHz observed |
Scalability | Poor | Predictable |

---

## A.2 Previous design classes and failure modes

### A.2.1 Wide monolithic tick counters (`ticks.v`)

**Structure**
- Single wide counter (≥26 bits)
- Increment every cycle
- Multiple consumers sampling bits directly

**Observed problems**
- yosys collapses logic into a wide ripple adder
- Carry propagation spans most of the counter width
- Critical path dominated by carry + routing
- Timing degrades rapidly as width increases

**Typical symptom**
- `ticks[...]` appears directly in critical path reports
- Fmax falls well below system target

**Resolution in current design**
- Counter split into `lo` and `hi`
- Carry is explicitly registered
- Carry depth physically limited
- yosys cannot re-merge the adder

---

### A.2.2 Derived or toggled clocks (`event_gen.v`)

**Structure**
- Output clocks generated by toggling signals
- Downstream logic clocked from these signals

**Observed problems**
- Derived clocks are always routed on global clock networks, using up high value SB_GB resources for non-critical use cases. 

**Resolution in current design**
- No derived clocks
- All periodic behavior uses enables
- All logic remains synchronous to `clk`

---

## A.3 Quantitative before/after behavior

While exact numbers varied per build, the qualitative shift was consistent:

### Before (experimental designs)

- Critical paths frequently:
  - Originated in global counters
  - Traversed multiple modules
  - Included wide arithmetic
- Routing delay dominated and was hard to control
- Small RTL changes caused large timing regressions

### After (current design)

- Critical paths:
  - Originate in **local logic**
  - Typically involve enable/reset control
  - Are narrow and predictable
- Timebase is absent from the critical path
- Fmax stabilized around ~70 MHz
- Timing margins are intentional and repeatable

---

## A.4 Why the current design succeeds

The key improvement is **structural, not incremental**.

The current architecture enforces timing properties at the RTL level:

- Carry chains are **physically bounded**
- Clocking intent is **unambiguous**
- yosys is prevented from “helpfully” collapsing logic
- nextpnr is given freedom to place and route locally

---

## A.5 Regression rule

A simple rule for future changes:

> If `timebase` (or any global timing logic) reappears in the critical path,
> the design has regressed architecturally.

Such regressions should be treated as **design issues**, not P&R tuning problems.

---
