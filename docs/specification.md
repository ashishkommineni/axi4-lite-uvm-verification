# AXI4-Lite Memory Slave Specification

## Scope

The DUT is a single-clock AXI4-Lite slave backed by `DEPTH` words of `DATA_WIDTH` bits. The reference configuration is 32-bit data, 10-bit byte addresses, and 64 words. It permits one write response and one read response to be outstanding. Bursts, IDs, exclusive accesses, and multiple outstanding transactions are outside this AXI4-Lite scope.

## Channel contract

| Channel | Acceptance rule | Stored information |
|---|---|---|
| AW | `AWVALID && AWREADY` | Byte address |
| W | `WVALID && WREADY` | Write data and byte strobes |
| B | `BVALID && BREADY` | `OKAY` or `DECERR` completion |
| AR | `ARVALID && ARREADY` | Read address |
| R | `RVALID && RREADY` | Read data and response |

AW and W are independent. Either may arrive first, and the write is committed only after both handshakes have occurred. While `BVALID` or `RVALID` is stalled by a low READY, VALID and the associated payload remain stable.

## Addressing and responses

A legal address is word aligned and less than `DEPTH * DATA_WIDTH/8`. Legal accesses return `2'b00` (`OKAY`). Misaligned and out-of-range accesses return `2'b11` (`DECERR`); an invalid write does not change memory and invalid read data is zero.

Each asserted `WSTRB` bit updates its corresponding eight-bit lane. Deasserted lanes preserve their previous value. Memory is cleared on active-low asynchronous reset.

## Deliberate boundaries

The implementation does not model AXI4 burst fields, protection attributes, QoS, IDs, or interleaving. Same-cycle read/write access to one word follows the simulator or inferred-memory read-during-write behavior and is not used as a portable architectural guarantee.
