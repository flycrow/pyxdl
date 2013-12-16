// A small processor I once created, intended to be used as a debug
// processor in ASICs and FPGAs.
//
// Very limited instruction set, but I never intended to write
// many programs for it.
// 
// In an FPGA it would probably be better to use for example
// PicoBlaze...
//

module serial_wb_top(

   input wire clk_i,rst_i,rx_i,
   output wire tx_o,
   input wire [31:0] parport_i,
   output wire [31:0] parport_o,
   output wire 	 parport_readstrobe_o,
   output wire 	 parport_writestrobe_o,
 
   // Wishbone master interface wbm_*:
   input wire [31:0] wbm_dat_i,
   output wire [31:0] wbm_dat_o,
   input wire 	 wbm_ack_i,
   output wire [31:0] wbm_adr_o,
   output wire 	 wbm_cyc_o,
   input wire 	 wbm_err_i,
   output wire 	 wbm_lock_o,
   input wire 	 wbm_rty_i,
   output wire [3:0]  wbm_sel_o,
   output wire 	 wbm_stb_o,
   output wire 	 wbm_we_o
   );
   



   wire [9:0]  pm_addr;
   wire [15:0]  pm_insn;

   wire [7:0] port0;
   wire [7:0] port1;
   wire [7:0] port2;

   wire       strobe1;
   wire       strobe2;


   serial_wb_mcu controller(.clk_i(clk_i),
		  .rst_i(rst_i),
		  .pm_addr_o(pm_addr),
		  .pm_insn_i(pm_insn),
		  .port0_o(port0),
		  .port1_o(port1),
		  .port2_i(port2),
		  .strobe1_o(strobe1),
		  .strobe2_o(strobe2));

   serial_wb_program program_memory(.clk_i(clk_i),
			 .pm_addr_i(pm_addr),
			 .pm_insn_o(pm_insn));
   

   serial_wb_io io(
		   .clk_i		(clk_i),
		   .rst_i		(rst_i),

		   // Serial port
		   .tx_o		(tx_o),
		   .rx_i		(rx_i),

		   // Parallell port I/O
		   .parport_o           (parport_o),
		   .parport_i           (parport_i),
		   .parport_readstrobe_o (parport_readstrobe_o),
		   .parport_writestrobe_o (parport_writestrobe_o),
		   
		   
		   // Wishbone interface
		   .wbm_dat_o(wbm_dat_o),
		   .wbm_adr_o(wbm_adr_o),
		   .wbm_cyc_o(wbm_cyc_o),
		   .wbm_lock_o(wbm_lock_o),
		   .wbm_sel_o(wbm_sel_o),
		   .wbm_stb_o(wbm_stb_o),
		   .wbm_we_o(wbm_we_o),
		   .wbm_dat_i(wbm_dat_i),
		   .wbm_ack_i(wbm_ack_i),
		   .wbm_err_i(wbm_err_i),
		   .wbm_rty_i(wbm_rty_i),
		   
		   // Processor bus
		   .data_o		(port2),
		   .address_i		(port0),
		   .data_i		(port1),
		   .read_strobe_i	(strobe2),
		   .write_strobe_i	(strobe1));
   

endmodule // serial_wb_top
