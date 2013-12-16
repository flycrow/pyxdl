all:
	make -C logicanalyzer
	cd testdesign;../bin/xil_synt_test.sh counter.v counter.ucf
	cp testdesign/testsynthdir/counter.xdl .
	cp testdesign/testsynthdir/counter.pcf .
