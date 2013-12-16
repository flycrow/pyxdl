// FIXME - naming convention in this file!!

module serial_wb_io(/*AUTOARG*/
   // Outputs
   tx_o, data_o, parport_o, parport_readstrobe_o, 
   parport_writestrobe_o, wbm_dat_o, wbm_adr_o, wbm_cyc_o, 
   wbm_lock_o, wbm_sel_o, wbm_stb_o, wbm_we_o, 
   // Inputs
   clk_i, rst_i, rx_i, address_i, data_i, parport_i, read_strobe_i, 
   write_strobe_i, wbm_dat_i, wbm_ack_i, wbm_err_i, wbm_rty_i
   );

   input wire clk_i;
   input wire rst_i;

   input wire rx_i;
   output tx_o;

   input wire [7:0] address_i;
   input wire [7:0] data_i;
   output reg [7:0] data_o;

   input wire [31:0] parport_i;
   output wire [31:0] parport_o;

   output 	 parport_readstrobe_o;
   output 	 parport_writestrobe_o;
   
   

   input wire 	read_strobe_i;
   input wire 	write_strobe_i;


   // Wishbone master interface wbm_*:
   input wire [31:0] wbm_dat_i;
   output [31:0] wbm_dat_o;
   input wire 	 wbm_ack_i;
   output [31:0] wbm_adr_o;
   output 	 wbm_cyc_o;
   input wire 	 wbm_err_i;
   output 	 wbm_lock_o;
   input wire 	 wbm_rty_i;
   output [3:0]  wbm_sel_o;
   output 	 wbm_stb_o;
   output 	 wbm_we_o;
   


   

   
   wire [7:0]	uart_data;
   wire [7:0]	wb_data;
   wire [7:0]	parport_data;

   

   // Uart on address 0 and 1
   wire 	uart_read_strobe = (address_i[7:1] == 7'b0) && read_strobe_i;
   wire 	uart_write_strobe = (address_i[7:1] == 7'b0) && write_strobe_i;

   // Parport on address 4 to 7
   wire	pp_read_strobe = (address_i[7:2] == 6'b1) && read_strobe_i;
   wire 	pp_write_strobe = (address_i[7:2] == 7'b1) && write_strobe_i;

   wire 	wbbridge_strobe = (address_i[7:4] == 4'b1) && write_strobe_i;
   

   always @(*) begin
      data_o = uart_data;
      if(address_i[7:2] == 6'b1) begin
	 data_o = parport_data;
      end else if(address_i[7:4] == 4'b1) begin
	 data_o = wb_data;
      end
      
   end

   serial_wb_uart uart(// Outputs
		    .tx_o		(tx_o),
		    .data_o		(uart_data),
		    // Inputs
		    .clk_i		(clk_i),
		    .rst_i		(rst_i),
		    .rx_i		(rx_i),
		    .writestrobe_i	(uart_write_strobe),
		    .data_i		(data_i),
		    .address_i		(address_i[0]),
		    .readstrobe_i	(uart_read_strobe));

   serial_wb_parport parport(
			     // Outputs
			     .parport_o	(parport_o),
			     .parport_readstrobe_o (parport_readstrobe_o),
			     .parport_writestrobe_o (parport_writestrobe_o),
			     .data_o	(parport_data),
			     // Inputs
			     .clk_i	(clk_i),
			     .rst_i	(rst_i),
			     .parport_i	(parport_i[31:0]),
			     .writestrobe_i(pp_write_strobe),
			     .data_i	(data_i[7:0]),
			     .address_i	(address_i[1:0]),
			     .readstrobe_i(pp_read_strobe));

   serial_wb_wbmaster wbmaster(
			       .clk_i	(clk_i),
			       .rst_i	(rst_i),

			       // System connect interface
			       .data_o	(wb_data),
			       .data_i	(data_i),
			       .writestrobe_i(wbbridge_strobe),
			       .address_i(address_i),

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
			       .wbm_rty_i(wbm_rty_i));
   

endmodule // serial_wb_io
