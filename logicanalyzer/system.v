`default_nettype none

module system(input wire clk_i,
	      input wire rx_i,
	      output wire tx_o,
	      input wire [63:0] tracein);

   reg 	     rst_int;
   wire      rstfromsrl;
   defparam  rstsrl.INIT = 16'hffff;
   SRL16 rstsrl(.CLK(clk_i), .A0(1'b1),.A1(1'b1),.A2(1'b1),.A3(1'b1),.Q(rstfromsrl),.D(1'b0));
   always @(posedge clk_i) begin
      rst_int <= rstfromsrl;
   end


   
   wire           wb_stb;
   wire 	  wb_cyc;
   wire 	  wb_cab;
   wire 	  wb_we;
   wire [31:0] 	  wb_adr;
   wire [31:0] 	  wb_dati;
   wire [3:0] 	  wb_sel;
   wire [31:0] 	  wb_dato;
   wire 	  wb_ack;
   wire 	  wb_rty;
   wire 	  wb_err;

   wire [63:0] 	  tracein_internal;

   genvar i;
   generate
      for(i = 0; i < 64; i = i + 1) begin: inputbuffers
	 IBUF ibuf(.I(tracein[i]),.O(tracein_internal[i]));
      end
   endgenerate

   // synthesis attribute keep of tracein_internal is "true"
   
   
   

   
   
   serial_wb_top mcu(
		     // Outputs
		     .tx_o		(tx_o),
		     .parport_o		(/*led_o*/),
		     .parport_readstrobe_o(),
		     .parport_writestrobe_o(),
		     .wbm_dat_o		(wb_dato),
		     .wbm_adr_o		(wb_adr),
		     .wbm_cyc_o		(wb_cyc),
		     .wbm_lock_o	(),
		     .wbm_sel_o		(wb_sel),
		     .wbm_stb_o		(wb_stb),
		     .wbm_we_o		(wb_we),
		     // Inputs
		     .clk_i		(clk_i),
		     .rst_i		(rst_int),
		     .rx_i		(rx_i),
		     .parport_i		(32'hf00f1234),
		     .wbm_dat_i		(wb_dati),
		     .wbm_ack_i		(wb_ack),
		     .wbm_err_i		(1'b0),
		     .wbm_rty_i		(1'b0));


   tracer traceit(/*AUTOINST*/
		 // Outputs
		 .wbs_dat_o		(wb_dati[31:0]),
		 .wbs_ack_o		(wb_ack),
		 // Inputs
		 .clk_i			(clk_i),
		 .rst_i			(rst_int),
		 .data_i		(tracein_internal),
		 .wbs_dat_i		(wb_dato[31:0]),
		 .wbs_adr_i		(wb_adr[31:0]),
		 .wbs_stb_i		(wb_stb),
		 .wbs_we_i		(wb_we));
   

endmodule // system
