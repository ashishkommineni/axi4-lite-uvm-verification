`timescale 1ns / 1ps
module axi_sva #(
    parameter int ADDR_WIDTH = 10,
    DATA_WIDTH = 32
) (
    input logic ACLK,
    ARESETn,
    input logic [ADDR_WIDTH-1:0] AWADDR,
    ARADDR,
    input logic AWVALID,
    AWREADY,
    input logic [DATA_WIDTH-1:0] WDATA,
    RDATA,
    input logic [DATA_WIDTH/8-1:0] WSTRB,
    input logic WVALID,
    WREADY,
    input logic [1:0] BRESP,
    RRESP,
    input logic BVALID,
    BREADY,
    ARVALID,
    ARREADY,
    RVALID,
    RREADY
);
  default clocking cb @(posedge ACLK);
  endclocking
  default disable iff (!ARESETn); ap_aw_stable :
  assert property (AWVALID && !AWREADY |=> $stable(AWADDR) && AWVALID);
  ap_w_stable :
  assert property (WVALID && !WREADY |=> $stable({WDATA, WSTRB}) && WVALID);
  ap_b_stable :
  assert property (BVALID && !BREADY |=> $stable(BRESP) && BVALID);
  ap_ar_stable :
  assert property (ARVALID && !ARREADY |=> $stable(ARADDR) && ARVALID);
  ap_r_stable :
  assert property (RVALID && !RREADY |=> $stable({RDATA, RRESP}) && RVALID);
  cp_write_backpressure :
  cover property (BVALID && !BREADY ##[1:8] BREADY);
  cp_read_backpressure :
  cover property (RVALID && !RREADY ##[1:8] RREADY);
endmodule
