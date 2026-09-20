`timescale 1ns / 1ps

module axi4_lite_memory_slave #(
    parameter  int unsigned ADDR_WIDTH = 10,
    parameter  int unsigned DATA_WIDTH = 32,
    parameter  int unsigned DEPTH      = 64,
    localparam int unsigned STRB_WIDTH = DATA_WIDTH / 8,
    localparam int unsigned INDEX_W    = $clog2(DEPTH)
) (
    input logic ACLK,
    input logic ARESETn,

    input  logic [ADDR_WIDTH-1:0] S_AXI_AWADDR,
    input  logic                  S_AXI_AWVALID,
    output logic                  S_AXI_AWREADY,
    input  logic [DATA_WIDTH-1:0] S_AXI_WDATA,
    input  logic [STRB_WIDTH-1:0] S_AXI_WSTRB,
    input  logic                  S_AXI_WVALID,
    output logic                  S_AXI_WREADY,
    output logic [           1:0] S_AXI_BRESP,
    output logic                  S_AXI_BVALID,
    input  logic                  S_AXI_BREADY,

    input  logic [ADDR_WIDTH-1:0] S_AXI_ARADDR,
    input  logic                  S_AXI_ARVALID,
    output logic                  S_AXI_ARREADY,
    output logic [DATA_WIDTH-1:0] S_AXI_RDATA,
    output logic [           1:0] S_AXI_RRESP,
    output logic                  S_AXI_RVALID,
    input  logic                  S_AXI_RREADY
);
  localparam int WORD_BYTES = DATA_WIDTH / 8;
  localparam int WORD_LSB = $clog2(WORD_BYTES);
  localparam int MEM_BYTES = DEPTH * WORD_BYTES;
  localparam logic [1:0] OKAY = 2'b00, DECERR = 2'b11;

  logic [DATA_WIDTH-1:0] mem[0:DEPTH-1];
  logic aw_hold_q, w_hold_q;
  logic [ADDR_WIDTH-1:0] awaddr_q;
  logic [DATA_WIDTH-1:0] wdata_q;
  logic [STRB_WIDTH-1:0] wstrb_q;
  logic write_addr_valid;
  logic read_addr_valid;

  assign S_AXI_AWREADY = !aw_hold_q && !S_AXI_BVALID;
  assign S_AXI_WREADY = !w_hold_q && !S_AXI_BVALID;
  assign S_AXI_ARREADY = !S_AXI_RVALID;

  assign write_addr_valid = (awaddr_q[WORD_LSB-1:0] == '0) && (awaddr_q < ADDR_WIDTH'(MEM_BYTES));
  assign read_addr_valid  = (S_AXI_ARADDR[WORD_LSB-1:0]=='0) && (S_AXI_ARADDR < ADDR_WIDTH'(MEM_BYTES));

  always_ff @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
      aw_hold_q <= 0;
      w_hold_q <= 0;
      awaddr_q <= '0;
      wdata_q <= '0;
      wstrb_q <= '0;
      S_AXI_BVALID <= 0;
      S_AXI_BRESP <= OKAY;
      for (int i = 0; i < DEPTH; i++) mem[i] <= '0;
    end else begin
      if (S_AXI_AWVALID && S_AXI_AWREADY) begin
        aw_hold_q <= 1;
        awaddr_q  <= S_AXI_AWADDR;
      end
      if (S_AXI_WVALID && S_AXI_WREADY) begin
        w_hold_q <= 1;
        wdata_q  <= S_AXI_WDATA;
        wstrb_q  <= S_AXI_WSTRB;
      end

      if (aw_hold_q && w_hold_q && !S_AXI_BVALID) begin
        S_AXI_BVALID <= 1;
        S_AXI_BRESP  <= write_addr_valid ? OKAY : DECERR;
        if (write_addr_valid) begin
          for (int byte_idx = 0; byte_idx < STRB_WIDTH; byte_idx++)
          if (wstrb_q[byte_idx])
            mem[awaddr_q[WORD_LSB+:INDEX_W]][byte_idx*8+:8] <= wdata_q[byte_idx*8+:8];
        end
        aw_hold_q <= 0;
        w_hold_q  <= 0;
      end
      if (S_AXI_BVALID && S_AXI_BREADY) S_AXI_BVALID <= 0;
    end
  end

  always_ff @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
      S_AXI_RVALID <= 0;
      S_AXI_RDATA  <= '0;
      S_AXI_RRESP  <= OKAY;
    end else begin
      if (S_AXI_ARVALID && S_AXI_ARREADY) begin
        S_AXI_RVALID <= 1;
        S_AXI_RRESP  <= read_addr_valid ? OKAY : DECERR;
        S_AXI_RDATA  <= read_addr_valid ? mem[S_AXI_ARADDR[WORD_LSB+:INDEX_W]] : '0;
      end else if (S_AXI_RVALID && S_AXI_RREADY) S_AXI_RVALID <= 0;
    end
  end
endmodule
