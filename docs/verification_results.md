# Verification Results

Revalidated: 2026-09-21

## Executed checks

| Check | Result | Evidence |
|---|---|---|
| RTL lint | PASS | `make lint`; zero RTL warnings in the revalidation log |
| Executable RTL + SVA smoke | PASS | `AXI4_LITE_SMOKE_PASS checks=6` |
| Parameter elaboration | PASS | 64-bit data / 32-word memory variant passed strict lint |
| UVM source compile/elaboration | PASS | Complete file list compiled against Accellera UVM core commit `78c0654`; zero errors or unexpected warnings |

```text
AXI4_LITE_SMOKE_PASS checks=6
```

The executable test covers AW-before-W, W-before-AW, delayed BREADY/RREADY, full and byte-strobed writes, readback, misalignment, and out-of-range decode. The instantiated SVA runs in the same binary, so a VALID/payload stability failure terminates `make smoke`.

## Second-pass findings corrected

- The write monitor now records actual AW/W handshake order; skew coverage no longer samples default zeros.
- Strobe and skew coverpoints are write-only, and their cross measures meaningful write shapes.
- Directed UVM items guarantee partial-write, misalignment, and decode-error cases.
- Shell `pipefail` prevents `tee` from hiding a simulator failure.

## Xcelium boundary

Xcelium is not installed in this workspace, so no commercial-simulator runtime or functional-coverage percentage is claimed. Verilator accepted the complete UVM/SVA source hierarchy but does not execute these covergroups here. On a licensed host, run `make uvm` or `make regress`; acceptance is zero `UVM_ERROR`, zero `UVM_FATAL`, passing SVA, and planned coverage closure.
