# File: Makefile

TOP = tb
SV_SRC = sv/tb.sv sv/core.sv sv/register_file.sv sv/imem.sv sv/dmem.sv

lint:
	verilator $(SV_SRC) --lint-only -Wall --timing

build:
	verilator --binary $(SV_SRC) --top $(TOP) -Wall --trace

run: build
	./obj_dir/V$(TOP)

gui: build
	./obj_dir/V$(TOP) > run.log
	gtkwave wave.vcd

clean:
	rm -rf obj_dir wave.vcd run.log hex/*dump*