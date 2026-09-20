# Verification Plan

The UVM master independently randomizes AW and W launch delays, byte strobes, BREADY/RREADY backpressure, address validity, read/write direction, and payload. Parallel monitor threads reconstruct independent read and write channels. A byte-aware memory scoreboard predicts partial writes and responses. SVA enforces the five AXI stable-VALID rules. Coverage records AW-before-W, simultaneous, W-before-AW, strobes, responses, operations, and backpressure.
