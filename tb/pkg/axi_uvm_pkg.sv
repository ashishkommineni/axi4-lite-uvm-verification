`timescale 1ns / 1ps
package axi_uvm_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  localparam int ADDR_WIDTH = 10, DATA_WIDTH = 32, DEPTH = 64;
  typedef enum bit {
    AXI_READ,
    AXI_WRITE
  } axi_op_e;
  class axi_item extends uvm_sequence_item;
    rand axi_op_e op;
    rand bit [ADDR_WIDTH-1:0] addr;
    rand bit [DATA_WIDTH-1:0] data;
    rand bit [DATA_WIDTH/8-1:0] strb;
    rand int unsigned aw_delay, w_delay, ready_delay;
    bit [DATA_WIDTH-1:0] rdata;
    bit [1:0] resp;
    constraint c_addr {
      addr dist {
        [0 : DEPTH * 4 - 1] := 8,
        [DEPTH * 4 : 2 ** ADDR_WIDTH - 1] := 2
      };
    }
    constraint c_delays {
      aw_delay inside {[0 : 5]};
      w_delay inside {[0 : 5]};
      ready_delay inside {[0 : 5]};
    }
    constraint c_strb {strb != 0;}
    `uvm_object_utils_begin(axi_item)
      `uvm_field_enum(axi_op_e, op, UVM_DEFAULT)
      `uvm_field_int(addr, UVM_HEX)
      `uvm_field_int(data, UVM_HEX)
      `uvm_field_int(strb, UVM_HEX)
      `uvm_field_int(aw_delay, UVM_DEC)
      `uvm_field_int(w_delay, UVM_DEC)
      `uvm_field_int(ready_delay, UVM_DEC)
      `uvm_field_int(rdata, UVM_HEX)
      `uvm_field_int(resp, UVM_BIN)
    `uvm_object_utils_end
    function new(string n = "axi_item");
      super.new(n);
    endfunction
  endclass
  class axi_sequencer extends uvm_sequencer #(axi_item);
    `uvm_component_utils(axi_sequencer)
    function new(string n, uvm_component p);
      super.new(n, p);
    endfunction
  endclass
  class axi_driver extends uvm_driver #(axi_item);
    `uvm_component_utils(axi_driver)
    virtual axi_if #(ADDR_WIDTH, DATA_WIDTH) vif;
    function new(string n, uvm_component p);
      super.new(n, p);
    endfunction
    function void build_phase(uvm_phase phase);
      if (!uvm_config_db#(virtual axi_if #(ADDR_WIDTH, DATA_WIDTH))::get(this, "", "vif", vif))
        `uvm_fatal("NOVIF", "axi_if missing")
    endfunction
    task drive_write(axi_item tr);
      fork
        begin
          repeat (tr.aw_delay) @(vif.drv_cb);
          vif.drv_cb.AWADDR  <= tr.addr;
          vif.drv_cb.AWVALID <= 1;
          do @(posedge vif.ACLK); while (!vif.AWREADY);
          @(vif.drv_cb);
          vif.drv_cb.AWVALID <= 0;
        end
        begin
          repeat (tr.w_delay) @(vif.drv_cb);
          vif.drv_cb.WDATA  <= tr.data;
          vif.drv_cb.WSTRB  <= tr.strb;
          vif.drv_cb.WVALID <= 1;
          do @(posedge vif.ACLK); while (!vif.WREADY);
          @(vif.drv_cb);
          vif.drv_cb.WVALID <= 0;
        end
      join
      while (!vif.BVALID) @(vif.drv_cb);
      repeat (tr.ready_delay) @(vif.drv_cb);
      vif.drv_cb.BREADY <= 1;
      @(vif.drv_cb);
      vif.drv_cb.BREADY <= 0;
    endtask
    task drive_read(axi_item tr);
      repeat (tr.aw_delay) @(vif.drv_cb);
      vif.drv_cb.ARADDR  <= tr.addr;
      vif.drv_cb.ARVALID <= 1;
      do @(posedge vif.ACLK); while (!vif.ARREADY);
      @(vif.drv_cb);
      vif.drv_cb.ARVALID <= 0;
      while (!vif.RVALID) @(vif.drv_cb);
      repeat (tr.ready_delay) @(vif.drv_cb);
      vif.drv_cb.RREADY <= 1;
      @(vif.drv_cb);
      vif.drv_cb.RREADY <= 0;
    endtask
    task run_phase(uvm_phase phase);
      vif.drv_cb.AWVALID <= 0;
      vif.drv_cb.WVALID  <= 0;
      vif.drv_cb.BREADY  <= 0;
      vif.drv_cb.ARVALID <= 0;
      vif.drv_cb.RREADY  <= 0;
      vif.drv_cb.AWADDR  <= '0;
      vif.drv_cb.WDATA   <= '0;
      vif.drv_cb.WSTRB   <= '0;
      vif.drv_cb.ARADDR  <= '0;
      wait (vif.ARESETn === 1);
      forever begin
        seq_item_port.get_next_item(req);
        if (req.op == AXI_WRITE) drive_write(req);
        else drive_read(req);
        seq_item_port.item_done();
      end
    endtask
  endclass
  class axi_monitor extends uvm_monitor;
    `uvm_component_utils(axi_monitor)
    virtual axi_if #(ADDR_WIDTH, DATA_WIDTH) vif;
    uvm_analysis_port #(axi_item) ap;
    function new(string n, uvm_component p);
      super.new(n, p);
      ap = new("ap", this);
    endfunction
    function void build_phase(uvm_phase phase);
      if (!uvm_config_db#(virtual axi_if #(ADDR_WIDTH, DATA_WIDTH))::get(this, "", "vif", vif))
        `uvm_fatal("NOVIF", "axi_if missing")
    endfunction
    task monitor_writes();
      axi_item tr;
      forever begin
        tr = axi_item::type_id::create("wr_tr");
        tr.op = AXI_WRITE;
        fork
          begin
            @(posedge vif.ACLK iff (vif.AWVALID && vif.AWREADY));
            tr.addr = vif.AWADDR;
          end
          begin
            @(posedge vif.ACLK iff (vif.WVALID && vif.WREADY));
            tr.data = vif.WDATA;
            tr.strb = vif.WSTRB;
          end
        join
        @(posedge vif.ACLK iff (vif.BVALID && vif.BREADY));
        tr.resp = vif.BRESP;
        ap.write(tr);
      end
    endtask
    task monitor_reads();
      axi_item tr;
      forever begin
        tr = axi_item::type_id::create("rd_tr");
        tr.op = AXI_READ;
        @(posedge vif.ACLK iff (vif.ARVALID && vif.ARREADY));
        tr.addr = vif.ARADDR;
        @(posedge vif.ACLK iff (vif.RVALID && vif.RREADY));
        tr.rdata = vif.RDATA;
        tr.resp  = vif.RRESP;
        ap.write(tr);
      end
    endtask
    task run_phase(uvm_phase phase);
      wait (vif.ARESETn === 1);
      fork
        monitor_writes();
        monitor_reads();
      join
    endtask
  endclass
  class axi_agent extends uvm_agent;
    `uvm_component_utils(axi_agent)
    axi_sequencer sqr;
    axi_driver drv;
    axi_monitor mon;
    function new(string n, uvm_component p);
      super.new(n, p);
    endfunction
    function void build_phase(uvm_phase phase);
      sqr = axi_sequencer::type_id::create("sqr", this);
      drv = axi_driver::type_id::create("drv", this);
      mon = axi_monitor::type_id::create("mon", this);
    endfunction
    function void connect_phase(uvm_phase phase);
      drv.seq_item_port.connect(sqr.seq_item_export);
    endfunction
  endclass
  class axi_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(axi_scoreboard)
    uvm_analysis_imp #(axi_item, axi_scoreboard) analysis_export;
    bit [31:0] model[0:DEPTH-1];
    int checked;
    function new(string n, uvm_component p);
      super.new(n, p);
      analysis_export = new("analysis_export", this);
      foreach (model[i]) model[i] = 0;
    endfunction
    function void write(axi_item tr);
      bit valid = (tr.addr < DEPTH * 4 && tr.addr[1:0] == 0);
      bit [1:0] exp_resp = valid ? 2'b00 : 2'b11;
      checked++;
      if (tr.resp !== exp_resp)
        `uvm_error("RESP", $sformatf("addr=%03h expected=%02b got=%02b", tr.addr, exp_resp, tr.resp
                   ))
      if (valid) begin
        if (tr.op == AXI_WRITE) begin
          for (int b = 0; b < 4; b++)
          if (tr.strb[b]) model[tr.addr[$clog2(DEPTH)+1:2]][b*8+:8] = tr.data[b*8+:8];
        end else if (tr.rdata !== model[tr.addr[$clog2(DEPTH)+1:2]])
          `uvm_error("DATA", $sformatf(
                     "addr=%03h expected=%08h got=%08h",
                     tr.addr,
                     model[tr.addr[$clog2(
                         DEPTH
                     )+1:2]],
                     tr.rdata
                     ))
      end
    endfunction
    function void report_phase(uvm_phase phase);
      `uvm_info("AXI_SUMMARY", $sformatf("Checked %0d transactions", checked), UVM_LOW)
    endfunction
  endclass
  class axi_coverage extends uvm_subscriber #(axi_item);
    `uvm_component_utils(axi_coverage)
    axi_item tr;
    covergroup cg;
      cp_op: coverpoint tr.op;
      cp_resp: coverpoint tr.resp {bins okay = {0}; bins decerr = {3};}
      cp_strb: coverpoint tr.strb {
        bins single_byte[] = {'b0001, 'b0010, 'b0100, 'b1000};
        bins full = {'1};
        bins partial = default;
      }
      cp_skew: coverpoint (tr.aw_delay > tr.w_delay ? 0 : tr.aw_delay == tr.w_delay ? 1 : 2);
      cx: cross cp_op, cp_resp;
    endgroup
    function new(string n, uvm_component p);
      super.new(n, p);
      cg = new();
    endfunction
    function void write(axi_item t);
      tr = t;
      cg.sample();
    endfunction
  endclass
  class axi_env extends uvm_env;
    `uvm_component_utils(axi_env)
    axi_agent agent;
    axi_scoreboard sb;
    axi_coverage cov;
    function new(string n, uvm_component p);
      super.new(n, p);
    endfunction
    function void build_phase(uvm_phase phase);
      agent = axi_agent::type_id::create("agent", this);
      sb = axi_scoreboard::type_id::create("sb", this);
      cov = axi_coverage::type_id::create("cov", this);
    endfunction
    function void connect_phase(uvm_phase phase);
      agent.mon.ap.connect(sb.analysis_export);
      agent.mon.ap.connect(cov.analysis_export);
    endfunction
  endclass
  class axi_sequence extends uvm_sequence #(axi_item);
    `uvm_object_utils(axi_sequence)
    function new(string n = "axi_sequence");
      super.new(n);
    endfunction
    task body();
      for (int i = 0; i < 8; i++) begin
        req = axi_item::type_id::create("wr");
        start_item(req);
        req.op = AXI_WRITE;
        req.addr = i * 4;
        req.data = 32'hABCD0000 + i;
        req.strb = '1;
        req.aw_delay = i % 3;
        req.w_delay = (i + 1) % 3;
        req.ready_delay = i % 4;
        finish_item(req);
      end
      for (int i = 0; i < 8; i++) begin
        req = axi_item::type_id::create("rd");
        start_item(req);
        req.op = AXI_READ;
        req.addr = i * 4;
        req.aw_delay = 0;
        req.ready_delay = i % 3;
        req.data = 0;
        req.strb = '1;
        req.w_delay = 0;
        finish_item(req);
      end
      repeat (120) begin
        req = axi_item::type_id::create("rand");
        start_item(req);
        if (!req.randomize()) `uvm_fatal("RAND", "randomization failed")
        finish_item(req);
      end
    endtask
  endclass
  class axi_test extends uvm_test;
    `uvm_component_utils(axi_test)
    axi_env env;
    function new(string n, uvm_component p);
      super.new(n, p);
    endfunction
    function void build_phase(uvm_phase phase);
      env = axi_env::type_id::create("env", this);
    endfunction
    task run_phase(uvm_phase phase);
      axi_sequence seq;
      phase.raise_objection(this);
      seq = axi_sequence::type_id::create("seq");
      seq.start(env.agent.sqr);
      repeat (6) @(posedge env.agent.mon.vif.ACLK);
      phase.drop_objection(this);
    endtask
  endclass
endpackage
