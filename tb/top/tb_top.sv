`timescale 1ns / 1ps
module tb_top;
  import uvm_pkg::*;
  import axi_uvm_pkg::*;
  logic ACLK = 0;
  always #5ns ACLK = ~ACLK;
  axi_if #(ADDR_WIDTH, DATA_WIDTH) vif (ACLK);
  axi4_lite_memory_slave #(
      .ADDR_WIDTH(ADDR_WIDTH),
      .DATA_WIDTH(DATA_WIDTH),
      .DEPTH(DEPTH)
  ) dut (
      .ACLK,
      .ARESETn(vif.ARESETn),
      .S_AXI_AWADDR(vif.AWADDR),
      .S_AXI_AWVALID(vif.AWVALID),
      .S_AXI_AWREADY(vif.AWREADY),
      .S_AXI_WDATA(vif.WDATA),
      .S_AXI_WSTRB(vif.WSTRB),
      .S_AXI_WVALID(vif.WVALID),
      .S_AXI_WREADY(vif.WREADY),
      .S_AXI_BRESP(vif.BRESP),
      .S_AXI_BVALID(vif.BVALID),
      .S_AXI_BREADY(vif.BREADY),
      .S_AXI_ARADDR(vif.ARADDR),
      .S_AXI_ARVALID(vif.ARVALID),
      .S_AXI_ARREADY(vif.ARREADY),
      .S_AXI_RDATA(vif.RDATA),
      .S_AXI_RRESP(vif.RRESP),
      .S_AXI_RVALID(vif.RVALID),
      .S_AXI_RREADY(vif.RREADY)
  );
  axi_sva #(
      .ADDR_WIDTH(ADDR_WIDTH),
      .DATA_WIDTH(DATA_WIDTH)
  ) sva (
      .ACLK,
      .ARESETn(vif.ARESETn),
      .AWADDR (vif.AWADDR),
      .ARADDR (vif.ARADDR),
      .AWVALID(vif.AWVALID),
      .AWREADY(vif.AWREADY),
      .WDATA  (vif.WDATA),
      .RDATA  (vif.RDATA),
      .WSTRB  (vif.WSTRB),
      .WVALID (vif.WVALID),
      .WREADY (vif.WREADY),
      .BRESP  (vif.BRESP),
      .RRESP  (vif.RRESP),
      .BVALID (vif.BVALID),
      .BREADY (vif.BREADY),
      .ARVALID(vif.ARVALID),
      .ARREADY(vif.ARREADY),
      .RVALID (vif.RVALID),
      .RREADY (vif.RREADY)
  );
  initial begin
    vif.ARESETn = 0;
    vif.AWVALID = 0;
    vif.WVALID  = 0;
    vif.BREADY  = 0;
    vif.ARVALID = 0;
    vif.RREADY  = 0;
    vif.AWADDR  = 0;
    vif.WDATA   = 0;
    vif.WSTRB   = 0;
    vif.ARADDR  = 0;
    repeat (5) @(posedge ACLK);
    vif.ARESETn = 1;
  end
  initial begin
    uvm_config_db#(virtual axi_if #(ADDR_WIDTH, DATA_WIDTH))::set(null, "uvm_test_top.env.agent.*",
                                                                  "vif", vif);
    run_test("axi_test");
  end
endmodule
