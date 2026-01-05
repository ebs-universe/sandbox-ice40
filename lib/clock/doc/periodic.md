## A Reusable Timebase Consumer for Periodic Events on iCE40

`periodic_tick` is a small, reusable RTL module that converts a **shared coarse timebase** into a **precise periodic pulse** (`tick`) suitable for driving counters, state machines, and low-rate control logic.

It is intended to be instantiated by *timebase consumers*, not to generate or distribute clocks.

---

## 1. What `periodic_tick` Does

At a high level:

* Consumes:

  * a free-running system clock (`clk`)
  * a multi-tap coarse timebase (`taps[]`)
* Selects the most appropriate tap **at elaboration time**
* Runs a **local divider**
* Emits a **single-cycle `tick` pulse** at the requested period

Key properties:

* Fully synchronous to `clk`
* No gated or derived clocks
* No runtime configuration
* Constant divider width
* Safe to instantiate multiple times

`tick` is a **data pulse**, not a clock.

---

## 2. Intended Usage Model

`periodic_tick` exists to decouple:

> **timebase generation**
> from
> **timebase consumption**

A typical design looks like:

```
coarse timebase
       ↓
 periodic_tick
       ↓
  consumer logic
```

Each consumer:

* Chooses its own period
* Gets its own local divider
* Decides how `tick` is used

---

## 3. Example: Basic Instantiation

```verilog
wire tick;

periodic_tick #(
    .CLK_HZ(CLK_HZ),
    .WIDTH(WIDTH),
    .NTAPS(NTAPS),
    .PERIOD_MS(1000),
    .MAX_DIV(MAX_DIV)
) u_timer (
    .clk(clk),
    .taps(taps),
    .tick(tick)
);
```

At this point, **no clock promotion has occurred**.
What happens next depends entirely on **how the consumer uses `tick`**.

---

## 4. How Clock / CEN Promotion Happens (and Who Controls It)

On iCE40:

* Every flip-flop has a built-in **clock enable**
* Yosys infers enables aggressively
* nextpnr may promote high-fanout enables to **global CEN routing**

Important:

> **Promotion is triggered by consumer logic, not by `periodic_tick`.**

Specifically, promotion occurs when `tick` is used *directly* as a register enable.

---

## 5. Recommended Consumer Pattern (Discourage Promotion)

This is the **chosen default policy**.

### Pattern

* Register `tick`
* Use it as **data**, not a control signal

### Example: `stepped_counter`

```verilog
reg tick_d;

always @(posedge clk)
    tick_d <= tick;

always @(posedge clk)
    ctr <= tick_d ? sum : ctr;
```

### Why this works

* No inferred clock enable in the consumer
* `tick` is clearly data
* No global CEN promotion in user logic
* Deterministic timing and behavior

This pattern should be used for:

* Low-rate control logic
* Non-critical counters
* State updates
* UI / LED / housekeeping logic

---

## 6. Alternative Consumer Pattern (Allow Promotion)

In some cases, you *may* want the tool to infer a clock enable.

### Pattern

* Use `tick` directly in an `if`

```verilog
always @(posedge clk) begin
    if (tick)
        ctr <= sum;
end
```

### What this implies

* `tick` becomes an inferred enable
* With sufficient fanout, nextpnr may:

  * promote it to a global CEN
* This can reduce LUT usage and skew

This pattern may be appropriate for:

* Widely shared enables
* Performance-sensitive control paths
* Designs where global resources are plentiful

---

## 7. About Promotion Inside `periodic_tick`

`periodic_tick` itself contains:

* A local divider counter
* Internal enable-like behavior

On iCE40:

* These internal enables **may or may not** be promoted
* This depends on fanout and packing decisions
* This behavior is:

  * architecture-driven
  * harmless
  * not user-visible

Users **do not need to manage** promotion inside `periodic_tick`.

---

## 8. iCE40 Global Clock / CEN Resources (Quick Note)

* iCE40 devices have:

  * A small number of global clock networks
  * A limited number of global clock-enable routes
* These resources are:

  * Cheap when used intentionally
  * Easy to waste accidentally

Best practice:

* **Avoid derived clocks**
* **Avoid unintentional enables**
* Let promotion happen only when you explicitly allow it

The recommended consumer pattern achieves exactly this.

---

## 9. Summary: How to Use `periodic_tick` Safely

### Do this by default

* Treat `tick` as data
* Register it in the consumer
* Use mux-style updates

### Only do this intentionally

* Use `tick` directly as an enable
* Allow the tool to promote

### Never do this

* Gate `clk`
* Use `tick` as a clock
* Assume low frequency prevents promotion

---

## 10. Final Takeaway

`periodic_tick` is a **clean, modular extraction** that:

* Centralizes timebase logic
* Keeps consumers simple
* Makes clocking intent explicit
* Scales as the design grows

By choosing **how consumers use `tick`**, you retain full control over:

* clock-enable inference
* global resource usage
* timing behavior

This is the intended and supported usage model going forward.
