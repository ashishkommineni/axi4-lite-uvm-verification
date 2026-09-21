# Verification Plan

## Strategy

The active UVM agent drives one AXI4-Lite transaction at a time while keeping AW and W timing independent. Separate monitor threads reconstruct read and write transactions from actual handshakes. A byte-aware reference memory predicts write-lane updates, read data, and `OKAY`/`DECERR` responses.

| Goal | Stimulus | Primary checker |
|---|---|---|
| AW/W independence | AW first, W first, and same-cycle handshakes | Monitor handshake timestamps and scoreboard |
| Byte enables | Single-byte, partial, and full `WSTRB` values | Per-lane reference-memory update |
| Response backpressure | Delayed `BREADY` and `RREADY` | Stable-VALID SVA |
| Legal read/write | Aligned in-range addresses | Scoreboard data and `OKAY` response |
| Decode handling | Misaligned and out-of-range addresses | `DECERR`, zero invalid read, no invalid write update |
| Reset | Initial active-low reset | Known idle outputs and empty model |

## Constraints and coverage

Address generation favors the memory range but also selects out-of-range and naturally misaligned addresses. AW, W, and response-ready delays are constrained to 0–5 clocks; zero write strobes are prohibited. Directed traffic guarantees a partial write and both decode-error classes before 120 randomized items.

Coverage records operation, response, write strobe class, and actual AW-versus-W handshake order. The skew × strobe cross proves that channel order and byte-lane behavior are exercised together; reads are excluded from write-only strobe/skew sampling.

## Assertions and closure

Five properties require AW, W, B, AR, and R VALID payloads to remain asserted and stable until READY. Cover properties target both read and write response backpressure. Closure requires zero UVM errors/fatals, all assertions passing, intended cover bins hit across the five seeds, and the portable smoke-test PASS token.
