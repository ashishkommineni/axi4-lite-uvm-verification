`timescale 1ns / 1ps
interface axi_if #(
    parameter int ADDR_WIDTH = 10,
    DATA_WIDTH = 32
) (
    input logic ACLK
);
  localparam int STRB_WIDTH = DATA_WIDTH / 8;
  logic ARESETn;
  logic [ADDR_WIDTH-1:0] AWADDR, ARADDR;
  logic AWVALID, AWREADY;
  logic [DATA_WIDTH-1:0] WDATA, RDATA;
  logic [STRB_WIDTH-1:0] WSTRB;
  logic WVALID, WREADY;
  logic [1:0] BRESP, RRESP;
  logic BVALID, BREADY, ARVALID, ARREADY, RVALID, RREADY;
  clocking drv_cb @(negedge ACLK);
    output AWADDR, AWVALID, WDATA, WSTRB, WVALID, BREADY, ARADDR, ARVALID, RREADY;
    input AWREADY, WREADY, BRESP, BVALID, ARREADY, RDATA, RRESP, RVALID;
  endclocking
endinterface
