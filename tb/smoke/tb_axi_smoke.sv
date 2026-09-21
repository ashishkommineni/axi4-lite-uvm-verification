`timescale 1ns / 1ps
module tb_axi_smoke;
  localparam int ADDR_WIDTH = 10, DATA_WIDTH = 32, DEPTH = 16;
  logic ACLK, ARESETn;
  logic [9:0] S_AXI_AWADDR, S_AXI_ARADDR;
  logic S_AXI_AWVALID, S_AXI_AWREADY;
  logic [31:0] S_AXI_WDATA, S_AXI_RDATA;
  logic [3:0] S_AXI_WSTRB;
  logic S_AXI_WVALID, S_AXI_WREADY;
  logic [1:0] S_AXI_BRESP, S_AXI_RRESP;
  logic S_AXI_BVALID, S_AXI_BREADY, S_AXI_ARVALID, S_AXI_ARREADY, S_AXI_RVALID, S_AXI_RREADY;
  int checks = 0;
  initial ACLK = 0;
  always #5 ACLK = ~ACLK;
  axi4_lite_memory_slave #(
      .ADDR_WIDTH(ADDR_WIDTH),
      .DATA_WIDTH(DATA_WIDTH),
      .DEPTH(DEPTH)
  ) dut (
      .*
  );
  axi_sva #(
      .ADDR_WIDTH(ADDR_WIDTH),
      .DATA_WIDTH(DATA_WIDTH)
  ) sva (
      .ACLK,
      .ARESETn,
      .AWADDR (S_AXI_AWADDR),
      .ARADDR (S_AXI_ARADDR),
      .AWVALID(S_AXI_AWVALID),
      .AWREADY(S_AXI_AWREADY),
      .WDATA  (S_AXI_WDATA),
      .RDATA  (S_AXI_RDATA),
      .WSTRB  (S_AXI_WSTRB),
      .WVALID (S_AXI_WVALID),
      .WREADY (S_AXI_WREADY),
      .BRESP  (S_AXI_BRESP),
      .RRESP  (S_AXI_RRESP),
      .BVALID (S_AXI_BVALID),
      .BREADY (S_AXI_BREADY),
      .ARVALID(S_AXI_ARVALID),
      .ARREADY(S_AXI_ARREADY),
      .RVALID (S_AXI_RVALID),
      .RREADY (S_AXI_RREADY)
  );
  initial begin
    #20000;
    $fatal(1, "AXI smoke watchdog expired");
  end
  task automatic axi_write(input logic [9:0] addr, input logic [31:0] data, input logic [3:0] strb,
                           input int awd, input int wd, input int bd, output logic [1:0] resp);
    fork
      begin
        @(negedge ACLK);
        repeat (awd) @(negedge ACLK);
        S_AXI_AWADDR  = addr;
        S_AXI_AWVALID = 1;
        do @(posedge ACLK); while (!S_AXI_AWREADY);
        @(negedge ACLK);
        S_AXI_AWVALID = 0;
      end
      begin
        @(negedge ACLK);
        repeat (wd) @(negedge ACLK);
        S_AXI_WDATA  = data;
        S_AXI_WSTRB  = strb;
        S_AXI_WVALID = 1;
        do @(posedge ACLK); while (!S_AXI_WREADY);
        @(negedge ACLK);
        S_AXI_WVALID = 0;
      end
    join
    while (!S_AXI_BVALID) @(negedge ACLK);
    resp = S_AXI_BRESP;
    repeat (bd) @(negedge ACLK);
    S_AXI_BREADY = 1;
    @(negedge ACLK);
    S_AXI_BREADY = 0;
    checks++;
  endtask
  task automatic axi_read(input logic [9:0] addr, input int rd, input int backpressure,
                          output logic [31:0] data, output logic [1:0] resp);
    @(negedge ACLK);
    repeat (rd) @(negedge ACLK);
    S_AXI_ARADDR  = addr;
    S_AXI_ARVALID = 1;
    do @(posedge ACLK); while (!S_AXI_ARREADY);
    @(negedge ACLK);
    S_AXI_ARVALID = 0;
    while (!S_AXI_RVALID) @(negedge ACLK);
    data = S_AXI_RDATA;
    resp = S_AXI_RRESP;
    repeat (backpressure) @(negedge ACLK);
    S_AXI_RREADY = 1;
    @(negedge ACLK);
    S_AXI_RREADY = 0;
    checks++;
  endtask
  initial begin
    logic [31:0] r;
    logic [ 1:0] resp;
    ARESETn = 0;
    S_AXI_AWADDR = 0;
    S_AXI_AWVALID = 0;
    S_AXI_WDATA = 0;
    S_AXI_WSTRB = 0;
    S_AXI_WVALID = 0;
    S_AXI_BREADY = 0;
    S_AXI_ARADDR = 0;
    S_AXI_ARVALID = 0;
    S_AXI_RREADY = 0;
    repeat (5) @(posedge ACLK);
    ARESETn = 1;
    axi_write(0, 32'hDEADBEEF, 4'hf, 0, 3, 2, resp);
    if (resp != 0) $fatal(1, "full write failed");
    axi_read(0, 0, 3, r, resp);
    if (resp != 0 || r !== 32'hDEADBEEF) $fatal(1, "readback failed %08h", r);
    axi_write(0, 32'h12345678, 4'b0011, 4, 0, 0, resp);
    axi_read(0, 0, 0, r, resp);
    if (r !== 32'hDEAD5678) $fatal(1, "strobe merge failed %08h", r);
    axi_write(10'h080, 32'h1, 4'hf, 0, 0, 0, resp);
    if (resp != 2'b11) $fatal(1, "invalid write response %02b", resp);
    axi_read(10'h082, 0, 0, r, resp);
    if (resp != 2'b11) $fatal(1, "misaligned read response %02b", resp);
    $display("AXI4_LITE_SMOKE_PASS checks=%0d", checks);
    $finish;
  end
endmodule
