# AXI4-Lite Memory Slave Specification

The DUT provides one outstanding AXI4-Lite read and one outstanding write. Write address and data channels are accepted independently in either order. Byte write strobes update selected lanes. Valid aligned addresses return `OKAY`; misaligned or out-of-range addresses return `DECERR`. `BVALID` and `RVALID` plus their payloads remain asserted and stable until the master raises READY.
