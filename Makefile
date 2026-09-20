XRUN?=xrun
VERILATOR?=verilator-cli
TEST?=axi_test
SEED?=random
.PHONY: uvm regress lint smoke clean
uvm:
	mkdir -p results
	$(XRUN) -64bit -sv -uvm -f sim/files.f -top tb_top +UVM_TESTNAME=$(TEST) -svseed $(SEED) -access +rwc -coverage all -covoverwrite -covworkdir results/xcelium_cov -l results/xrun_$(TEST).log
regress:
	@for seed in 13 31 61 89 137;do $(MAKE) uvm SEED=$$seed||exit 1;done
lint:
	$(VERILATOR) --lint-only --sv --timing -Wall -Wno-fatal rtl/axi4_lite_memory_slave.sv
smoke:
	rm -rf build/obj_axi;mkdir -p build
	$(VERILATOR) --binary --sv --timing --assert -Wall -Wno-fatal --top-module tb_axi_smoke --Mdir build/obj_axi rtl/axi4_lite_memory_slave.sv tb/smoke/tb_axi_smoke.sv
	./build/obj_axi/Vtb_axi_smoke|tee results_smoke.log
clean:
	rm -rf build xcelium.d INCA_libs waves.shm results *.log *.key
