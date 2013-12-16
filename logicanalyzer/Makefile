all:
	perl asm.pl controller.asm > serial_wb_program.v
	../bin/xil_synt_test.sh system.v serial_wb*.v tracer.v system.ucf
	cp testsynthdir/system.xdl .
	cp testsynthdir/system.pcf .


test: testfiles
	vsim -c tb_opt -do 'run -all;quit -f'


testfiles:
	perl asm.pl controller.asm > serial_wb_program.v
	vlib work
	vmap unisims_ver /extra/ise9.1/verilog/mti_se/unisims_ver
	vlog *.v
	vlog $$XILINX/verilog/src/glbl.v
	vopt +acc tb glbl -L unisims_ver -o tb_opt
