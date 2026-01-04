## How to Add a Timed Module (Checklist + Worked Example)

This appendix explains **how new modules should consume `timebase`** in a way
that is timing-safe, scalable, and consistent with the design philosophy of
this library.

If you follow this pattern, you will:
- Stay in a single clock domain
- Avoid CDC and derived clocks
- Preserve timing closure
- Make behavior easy to reason about

---

## One-page checklist: adding a timed module

When writing a module that needs periodic or time-based behavior:

### 1️⃣ Clocking
- ☐ Use **only the system clock** (`clk`)
- ☐ Do **not** generate or derive clocks
- ☐ Do **not** use `posedge taps[x]`

### 2️⃣ Inputs from `timebase`
- ☐ Consume `taps[k]` as **clock enables**
- ☐ Use `ticks` only for **measurement or timestamps**
- ☐ Treat `ticks` as data, not as a phase reference

### 3️⃣ Rate control
- ☐ Pick the **slowest reasonable tap**
- ☐ Add a **small local divider** if exact periods are required
- ☐ Keep dividers local to the module

### 4️⃣ Sequential structure
- ☐ All state updates in `always @(posedge clk)`
- ☐ Gate updates with `if (taps[TAP])`
- ☐ No combinational feedback from taps or ticks

### 5️⃣ Synthesis hygiene
- ☐ Keep tap selection **compile-time**
- ☐ Avoid wide arithmetic in fast paths
- ☐ Avoid clever parameterized abstractions

If you feel tempted to break one of these rules, stop and reconsider —
there is almost always a cleaner tap-based solution.

---

## Worked example: periodic event generator

### Goal

Create a module that:
- Toggles an output every **500 ms**
- Uses the system `clk`
- Uses `timebase` taps correctly
- Is timing-safe on iCE40

---

### Interface

```verilog
module heartbeat #(
    parameter integer CLK_HZ    = 25_000_000,
    parameter integer PERIOD_MS = 500,
    parameter integer NTAPS     = 6
)(
    input  wire clk,
    input  wire [NTAPS-1:0] taps,
    output reg  beat
);
```

---

### Compile-time helpers (local, explicit, safe)

```verilog
    // ------------------------------------------------------------
    // Compute which counter bit a given tap corresponds to
    // ------------------------------------------------------------
    function integer tap_bit;
        input integer i;
        begin
            tap_bit = (i * 26) / (NTAPS - 1); // WIDTH = 27
        end
    endfunction

    // ------------------------------------------------------------
    // Select the slowest tap that keeps the divider reasonable
    // ------------------------------------------------------------
    function integer select_tap;
        input integer period_ms;
        integer i, hz, div;
        begin
            select_tap = 0;
            for (i = NTAPS-1; i >= 0; i = i - 1) begin
                hz  = CLK_HZ >> (tap_bit(i) + 1);
                div = (hz * period_ms) / 1000;
                if (div > 0 && div <= 1024)
                    select_tap = i;
            end
        end
    endfunction
```

---

### Derived constants (compile-time)

```verilog
    localparam integer TAP = select_tap(PERIOD_MS);

    localparam integer DIV =
        ((CLK_HZ >> (tap_bit(TAP)+1)) * PERIOD_MS) / 1000;
```

At this point:

* `TAP` is fixed
* `DIV` is fixed
* Divider width is minimized
* No runtime math exists

---

### Local divider and output logic

```verilog
    // ------------------------------------------------------------
    // Local divider
    // ------------------------------------------------------------
    reg [$clog2(DIV)-1:0] div_cnt = 0;
    wire tick = (div_cnt == DIV-1);

    // ------------------------------------------------------------
    // Sequential logic
    // ------------------------------------------------------------
    always @(posedge clk) begin
        if (taps[TAP]) begin
            if (tick) begin
                div_cnt <= 0;
                beat    <= ~beat;   // toggle output
            end else begin
                div_cnt <= div_cnt + 1;
            end
        end
    end
```

---

### Why this module is correct

* ✔ Uses **one clock**
* ✔ Uses `taps[TAP]` as a **clock enable**
* ✔ Divider only runs when needed
* ✔ No derived clocks
* ✔ No wide arithmetic in fast paths
* ✔ Excellent timing behavior

This pattern has been validated in synthesis and place-and-route.

---

## Common variations

### One-shot timer

```verilog
if (taps[TAP] && tick)
    done <= 1'b1;
```

### Periodic pulse (1 cycle wide)

```verilog
pulse <= (taps[TAP] && tick);
```

### Rate-limited state machine

```verilog
if (taps[TAP]) begin
    state <= next_state;
end
```

---

## What *not* to do (anti-patterns)

```verilog
always @(posedge taps[TAP])   // ❌ derived clock
```

```verilog
always @(posedge clk)
    if (ticks[10]) ...         // ❌ level-sensitive misuse
```

```verilog
wire slow_clk = ticks[15];    // ❌ clock from data
```

These will eventually:

* Break timing
* Introduce CDC hazards
* Make behavior fragile

---

## Mental model to keep in mind

> **Time flows through `ticks`.
> Behavior is enabled by `taps`.
> State changes only on `clk`.**

---

## Summary

* Adding a timed module is a **local, mechanical task**
* The worked example is a template — copy it
* This approach scales cleanly across the design

When in doubt:

* Use a tap
* Add a small divider
* Keep everything synchronous

That is the design philosophy of this clocking system.

---
