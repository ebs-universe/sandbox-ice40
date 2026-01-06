# Usage Examples

## Scope

This document presents **correct, idiomatic usage patterns** for the clocking library.

The examples focus on:

* Event-driven design
* Safe timing semantics
* Common application needs

Anti-patterns are intentionally excluded here and covered in a separate section.

---

## Common Setup Pattern

Most examples assume:

* A single system clock (`clk`)
* A domain-local `timebase`
* One or more `periodic_tick` instances

```verilog
wire [26:0] ticks;
wire [5:0]  taps;

timebase #(
    .NTAPS(6)
) u_timebase (
    .clk     (clk),
    .reset_n (reset_n),
    .ticks   (ticks),
    .taps    (taps)
);
```

---

## Example 1: LED Blink (Human-Scale Timing)

### Goal

Toggle an LED approximately once per second.

### Implementation

```verilog
wire tick_1s;

periodic_tick #(
    .CLK_HZ     (48_000_000),
    .PERIOD_US  (1_000_000),
    .NTAPS      (6),
    .WIDTH      (27),
    .MAX_DIV    (255)
) u_tick_1s (
    .clk     (clk),
    .reset_n (reset_n),
    .taps    (taps),
    .tick    (tick_1s)
);

always @(posedge clk) begin
    if (!reset_n)
        led <= 1'b0;
    else if (tick_1s)
        led <= ~led;
end
```

### Notes

* The LED toggles only on an event
* No divided clocks are used
* Timing intent is explicit

---

## Example 2: Periodic Sampling Enable

### Goal

Sample a sensor at 10 ms intervals.

### Implementation

```verilog
wire sample_tick;

periodic_tick #(
    .CLK_HZ     (48_000_000),
    .PERIOD_US  (10_000),
    .NTAPS      (6),
    .WIDTH      (27),
    .MAX_DIV    (255)
) u_sample_tick (
    .clk     (clk),
    .reset_n (reset_n),
    .taps    (taps),
    .tick    (sample_tick)
);

always @(posedge clk) begin
    if (!reset_n)
        sample_valid <= 1'b0;
    else
        sample_valid <= sample_tick;
end
```

### Notes

* `sample_tick` acts as a strobe
* Registration is optional depending on downstream logic
* No level-sensitive timing exists

---

## Example 3: FSM Stepping

### Goal

Advance a finite-state machine at a fixed rate.

### Implementation

```verilog
wire fsm_tick;

periodic_tick #(
    .CLK_HZ     (48_000_000),
    .PERIOD_US  (5_000),
    .NTAPS      (6),
    .WIDTH      (27),
    .MAX_DIV    (255)
) u_fsm_tick (
    .clk     (clk),
    .reset_n (reset_n),
    .taps    (taps),
    .tick    (fsm_tick)
);

always @(posedge clk) begin
    if (!reset_n)
        state <= IDLE;
    else if (fsm_tick)
        state <= next_state;
end
```

### Notes

* The FSM advances deterministically
* No accidental multi-step behavior
* Tick registration is implicit in the FSM

---

## Example 4: Multiple Independent Periodic Actions

### Goal

Two modules need the same nominal frequency, but no phase relationship.

### Implementation

```verilog
wire tick_a, tick_b;

periodic_tick #(
    .CLK_HZ     (48_000_000),
    .PERIOD_US  (1_000),
    .NTAPS      (6),
    .WIDTH      (27),
    .MAX_DIV    (255)
) u_tick_a ( ... );

periodic_tick #(
    .CLK_HZ     (48_000_000),
    .PERIOD_US  (1_000),
    .NTAPS      (6),
    .WIDTH      (27),
    .MAX_DIV    (255)
) u_tick_b ( ... );
```

### Notes

* Duplication is intentional
* Resource cost is low
* No coupling between consumers

---

## Example 5: Centralized Tick for Phase-Coupled Logic

### Goal

Two modules must act in lockstep.

### Implementation

```verilog
wire shared_tick;

periodic_tick #(
    .CLK_HZ     (48_000_000),
    .PERIOD_US  (20_000),
    .NTAPS      (6),
    .WIDTH      (27),
    .MAX_DIV    (255)
) u_shared_tick (
    .clk     (clk),
    .reset_n (reset_n),
    .taps    (taps),
    .tick    (shared_tick)
);
```

Both consumers use `shared_tick`.

### Notes

* Centralization is justified here
* Phase relationship is guaranteed
* Consumers remain simple

---

## Example 6: Slow Control Loop

### Goal

Run a control loop at 100 Hz.

### Implementation

```verilog
wire control_tick;

periodic_tick #(
    .CLK_HZ     (48_000_000),
    .PERIOD_US  (10_000),
    .NTAPS      (6),
    .WIDTH      (27),
    .MAX_DIV    (255)
) u_control_tick (
    .clk     (clk),
    .reset_n (reset_n),
    .taps    (taps),
    .tick    (control_tick)
);
```

Use `control_tick` as the loop trigger.

---

## Example 7: Debug / Instrumentation Timing

### Goal

Timestamp an event.

### Implementation

```verilog
always @(posedge clk) begin
    if (event)
        event_time <= ticks;
end
```

### Notes

* `ticks` provides a long-running time reference
* No event generation required
* Useful for logging and debug

---

## Summary

These examples illustrate:

* Event-driven timing
* Explicit intent
* Safe, synchronous design

Common characteristics:

* No divided clocks in application logic
* No level-sensitive timing
* No implicit CDC

The next section documents **what not to do**, and why those patterns fail.

