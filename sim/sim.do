
setenv LMC_TIMEUNIT -9
vlib work
vmap work work

set SV_DIR "../sv"

vlog -sv -work work "$SV_DIR/globals_pkg.sv"
vlog -sv -work work "$SV_DIR/quant_pkg.sv"
vlog -sv -work work "$SV_DIR/frozenlake_pkg.sv"

vlog -sv -work work "$SV_DIR/fifo.sv"
vlog -sv -work work "$SV_DIR/bram.sv"
vlog -sv -work work "$SV_DIR/bram_block.sv"

vlog -sv -work work "$SV_DIR/q_learner.sv"
vlog -sv -work work "$SV_DIR/ql_top.sv"

# uvm library
vlog -work work +incdir+$env(UVM_HOME)/src $env(UVM_HOME)/src/uvm.sv
vlog -work work +incdir+$env(UVM_HOME)/src $env(UVM_HOME)/src/uvm_macros.svh
vlog -work work +incdir+$env(UVM_HOME)/src $env(MTI_HOME)/verilog_src/questa_uvm_pkg-1.2/src/questa_uvm_pkg.sv

# uvm package
vlog -work work +incdir+$env(UVM_HOME)/src "../uvm/my_uvm_pkg.sv"
vlog -work work +incdir+$env(UVM_HOME)/src "../uvm/my_uvm_tb.sv"

# start uvm simulation
vsim\
	-classdebug\
	-voptargs=+acc +notimingchecks\
	-L work work.my_uvm_tb\
	-wlf my_uvm_tb.wlf\
	-sv_lib /vol/mentor/modelsim-2020.1/modeltech/uvm-1.2/linux_x86_64/uvm_dpi \
	-dpicpppath /usr/bin/gcc

do wave.do

run -all

