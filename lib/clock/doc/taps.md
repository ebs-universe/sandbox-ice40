## Tap Selection and Local Dividers

This appendix explains **how to choose and consume taps correctly**, based on the actual tap-generation logic used in this design and in downstream consumers.

Unless otherwise stated, examples assume:

- `NTAPS = 6`
- `ticks` width = 27 bits
- Taps are **log-spaced across the counter**
- Taps are used as **clock enables**, never as clocks

---

## How taps are positioned

Tap positions are computed at **elaboration time** using:

```verilog
function integer tap_bit;
    input integer i;
    begin
        tap_bit = (i * (WIDTH-1)) / (NTAPS-1);
    end
endfunction
````

For the current implementation (`WIDTH = 27`, `NTAPS = 6`), this yields:

| Tap index | Bit index (`tap_bit(i)`) | Toggle rate |
| --------: | -----------------------: | ----------- |
|         0 |                        0 | clk / 2¹    |
|         1 |                        5 | clk / 2⁶    |
|         2 |                       10 | clk / 2¹¹   |
|         3 |                       16 | clk / 2¹⁷   |
|         4 |                       21 | clk / 2²²   |
|         5 |                       26 | clk / 2²⁷   |

Each tap produces a **1-cycle pulse** whenever its corresponding bit toggles.

Key observations:

* Lower-index taps fire **frequently**
* Higher-index taps fire **very infrequently**
* Spacing is logarithmic, not linear
* This is intentional and optimal for wide timing coverage

---

## Why taps are edge-based (not level-based)

A tap pulse is generated as:

```verilog
edge[k] <= ticks[tap_bit(k)] ^ prev[k];
```

This means:

* A pulse occurs **only when the bit changes**
* Pulse width = **exactly 1 clock**
* No glitches
* No multi-cycle assertion

This makes taps ideal for:

* Clock enables
* Event pacing
* Low-power periodic activity

And unsuitable for:

* Clock generation
* Level-sensitive gating
* Asynchronous control

---

## Selecting a tap for a desired period

Downstream modules typically want a **periodic event**, e.g.:

> “Do something every ~1000 ms”

Because taps are logarithmic, **no single tap directly matches an arbitrary period**.
Instead, the design uses a **two-stage approach**:

1. Use a **tap** to reduce the effective clock rate
2. Use a **small local divider** to hit the exact period

This is what the helper functions implement.

---

## Compile-time tap selection helper

The following helper selects the **slowest possible tap** that allows a reasonable divider size:

```verilog
function integer select_tap;
    input integer period_ms;
    integer i, hz, div;
    begin
        select_tap = 0;
        for (i = NTAPS-1; i >= 0; i = i - 1) begin
            hz  = CLK_HZ >> (tap_bit(i) + 1);
            div = (hz * period_ms) / 1000;
            if (div > 0 && div <= MAX_DIV)
                select_tap = i;
        end
    end
endfunction
```

### What this does

For each tap (from slowest to fastest):

1. Estimate the **effective clock rate** of that tap
2. Compute how large a divider would be needed
3. Pick the **slowest tap** that keeps the divider within bounds

This ensures:

* Minimal switching activity
* Minimal divider width
* Minimal routing and logic cost

---

## Derived parameters

Once the tap is chosen:

```verilog
localparam integer TAP = select_tap(PERIOD_MS);

localparam integer DIV =
    ((CLK_HZ >> (tap_bit(TAP)+1)) * PERIOD_MS) / 1000;
```

* `TAP` is a **compile-time constant**
* `DIV` is also compile-time
* The divider width is minimized via `$clog2(DIV)`

This keeps all timing-critical decisions **static**, predictable, and optimizable.

---

## Local divider implementation (recommended pattern)

```verilog
reg [$clog2(DIV)-1:0] div_cnt = 0;
wire tick = (div_cnt == DIV-1);

always @(posedge clk) begin
    if (taps[TAP]) begin
        if (tick)
            div_cnt <= 0;
        else
            div_cnt <= div_cnt + 1;
    end
end
```

### Why this structure is correct

* `taps[TAP]` acts as a **clock enable**
* Divider only runs when the tap fires
* No derived clocks
* No combinational feedback
* Clean synthesis to `CEN` logic on iCE40

This pattern was validated in timing analysis and is known to scale well.

---

## Timing implications of tap choice

Choosing a **higher-index (slower) tap**:

* Reduces toggle rate
* Reduces dynamic power
* Reduces divider width
* Slightly increases wake-up latency

Choosing a **lower-index (faster) tap**:

* Increases activity
* Increases divider width
* Gives finer phase granularity

**Rule of thumb**:

> Always choose the **slowest tap** that allows a reasonable divider.

The helper does exactly this.

---

## Why this approach is better than a single big divider

Compared to dividing the system clock directly:

| Approach            | Result                         |
| ------------------- | ------------------------------ |
| Single wide divider | Long carry chains, poor timing |
| Tap + small divider | Short paths, excellent timing  |
| Derived clocks      | CDC hazards                    |
| Tap enables         | Single-clock design            |

This is why the timebase + tap model scales cleanly.

---

## Common mistakes to avoid

❌ Using `taps[TAP]` as a clock
❌ Assuming tap frequency is exact
❌ Using absolute phase alignment
❌ Recomputing tap selection at runtime

✔ Use taps as enables
✔ Measure time using `ticks`
✔ Accept small phase jitter
✔ Keep selection compile-time

---

## Summary

* Taps are **log-spaced, edge-based enables**
* They are designed to be combined with **small local dividers**
* The provided helpers choose optimal taps automatically
* This structure minimizes timing pressure and power
* It is proven to work well on iCE40 with yosys + nextpnr

In short:

> **Use taps to reduce rate, dividers to refine period, and ticks to measure time.**

---
