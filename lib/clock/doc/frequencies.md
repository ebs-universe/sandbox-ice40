## Tap Period Reference Table (NTAPS = 6)

This is based on **NTAPS = 6** and the **current timebase implementation** (27-bit ticks, log-spaced taps).

Tap bit positions are computed as:

```
tap_bit(i) = (i * (WIDTH-1)) / (NTAPS-1)
WIDTH = 27
```

Resulting tap bits:

```
[0, 5, 10, 16, 21, 26]
```

Each tap fires on **bit toggle**, so the effective period is:

```
Period = 2^(tap_bit + 1) / clk
```

---

### 📊 Tap Periods vs Clock Frequency

| TAP index | Bit | Divider (2^(bit+1)) |   12 MHz |    25 MHz |    50 MHz |
| --------: | --: | ------------------: | -------: | --------: | --------: |
|         0 |   0 |                   2 | 0.167 µs |  0.080 µs |  0.040 µs |
|         1 |   5 |                  64 |  5.33 µs |   2.56 µs |   1.28 µs |
|         2 |  10 |                2048 | 0.171 ms | 0.0819 ms | 0.0409 ms |
|         3 |  16 |              131072 | 10.92 ms |   5.24 ms |   2.62 ms |
|         4 |  21 |             4194304 | 349.5 ms |  167.8 ms |   83.9 ms |
|         5 |  26 |           134217728 |  11.18 s |    5.37 s |    2.68 s |

---

### 🧭 How to use this table

* **Pick the slowest tap** whose period is **shorter than your target**
* Use a **local divider** to refine to the exact period
* Avoid using lower taps unless you need fine resolution

#### Example (25 MHz clock, 1000 ms target):

* TAP 4 ≈ 168 ms → divider ≈ 6
* TAP 5 ≈ 5.37 s → too slow
* **Best choice: TAP 4 + local divider**

---

### 📐 Note on Frequency Accuracy and Timing Granularity

The tap periods shown above are **exact powers of two** derived from the system clock and therefore provide **deterministic but coarse timing resolution**.

The helper functions used in the examples (`select_tap`, local dividers, etc.) intentionally choose the **slowest possible tap** that keeps divider sizes reasonable. This approach minimizes logic, switching activity, and timing pressure, and is appropriate for most periodic control tasks.

However, this also means:

* The final period is typically an **approximation** of the requested value
* The approximation error depends on the tap chosen and the divider granularity

For applications that require **tighter frequency accuracy**, it is often better to:

* Manually select a **faster tap** (lower index)
* Use a **larger local divider** to achieve finer period resolution

This trades slightly higher logic activity for improved timing granularity.

Finally, for **highly timing-critical logic** (e.g. cycle-accurate protocols, bit-level timing, or interfaces with strict phase requirements):

> **Do not use `timebase` at all.**
> Such logic should operate **directly from `clk`** using dedicated, purpose-built counters or state machines.

The `timebase` is designed to provide **robust, scalable, and timing-friendly system-level timing**, not sub-cycle or phase-critical control.