# FAQ and Gotchas

## Scope

This document collects **common questions, misconceptions, and pitfalls** encountered when using the clocking library.

It exists to:

* Capture institutional knowledge
* Prevent repeated mistakes
* Keep the main documentation focused

---

## FAQ

### “Why not just use a counter in my module?”

You can — but you probably shouldn’t.

Local counters:

* Duplicate logic
* Hide timing intent
* Encourage inconsistent semantics

Using `timebase` and `periodic_tick`:

* Centralizes timing behavior
* Makes intent explicit
* Simplifies review and maintenance

---

### “Why are taps 50% duty cycle? Wouldn’t pulses be better?”

No.

* 50% duty cycle taps are cheap
* They are stable and deterministic
* They are useful as time *levels*

Pulses are events, not time. Conflating the two leads to bugs.

---

### “Why not generate all ticks centrally and share them?”

Because:

* It introduces unnecessary coupling
* It makes phase relationships implicit
* It complicates reuse and refactoring

Centralized ticks are appropriate **only** when phase coupling is required.

---

### “Why isn’t `tick` registered inside `periodic_tick`?”

Because:

* Not all consumers require it
* Registration adds latency
* Registration semantics vary by use case

The library leaves this decision explicit.
A future option may add an internally registered variant.

---

### “Why does my LED blink slightly faster or slower than expected?”

Likely causes:

* Divider quantization
* Tap granularity
* Clock frequency tolerance

This is expected behavior and is deterministic.

Check:

* `CLK_HZ`
* Requested period
* Selected tap/divider

---

### “Can I assume two identical `periodic_tick` instances are phase-aligned?”

No.

Even with identical parameters:

* Reset timing may differ
* Phase is not guaranteed

If phase matters, share the tick intentionally.

---

### “Why can’t I use taps as clocks? It works in simulation.”

Simulation:

* Ignores clock routing
* Ignores skew
* Ignores silicon realities

Hardware does not.

Using taps as clocks is undefined behavior.

---

### “Why is CDC treated so strictly?”

Because:

* CDC bugs are intermittent
* They are hard to reproduce
* They often escape simulation

Strict rules make CDC visible and auditable.

---

### “Can reset be used to synchronize things?”

Reset establishes a starting state, not a timing contract.

It does not:

* Align clocks
* Synchronize events
* Guarantee ordering across domains

---

### “Is this library suitable for high-precision timing?”

Define “high precision”.

This library is suitable for:

* Human-scale timing
* Control loops
* Scheduling and pacing

It is not suitable for:

* Sub-cycle precision
* High-speed serial timing
* Phase-critical DSP

---

### “Why does the library avoid dynamic reconfiguration?”

Dynamic timing:

* Increases complexity
* Obscures intent
* Complicates verification

This library prefers determinism.

---

## Gotchas

### Gotcha: Pulse Loss in CDC

Transferring a single-cycle pulse across domains without stretching will lose events.

Always stretch or toggle.

---

### Gotcha: Divider Saturation

Very short or very long requested periods may saturate the divider.

The result is still deterministic, but error may increase.

---

### Gotcha: Overusing Derived Clocks

Derived clocks:

* Increase CDC complexity
* Complicate timing closure

If you need many of them, reconsider the design.

---

### Gotcha: Assuming Reset Phase Equals Time Phase

Reset establishes state, not phase alignment.

Do not build phase assumptions on reset.

---

### Gotcha: Forgetting That Taps Are Levels

If logic behaves “too fast” or “too slow”, check whether a level is being treated as an event.

---

## Final Advice

When something feels confusing, ask:

1. Is this a clock, time, or event?
2. Is it a level or an edge?
3. Which domain does it belong to?

If the answer is unclear, the design likely needs refactoring.

---

## Closing Note

This FAQ exists because these mistakes happen in real designs.

Refer back to it when:

* Reviewing code
* Debugging timing issues
* Teaching others the system

It will save time.

