`define STATE_IDLE  2'b00
`define STATE_STARTBIT  2'b01
`define STATE_DATABITS  2'b10
`define STATE_STOPBIT  2'b11
   

module serial_wb_uart( 
		  /*AUTOARG*/
		  // Outputs
		  tx_o, data_o, 
		  // Inputs
		  clk_i, rst_i, rx_i, writestrobe_i, readstrobe_i,data_i, address_i
		  );



   output        tx_o;
   output [7:0]  data_o;
   input         clk_i;
   input         rst_i;
   input         rx_i;
   input         writestrobe_i;
   input [7:0] 	 data_i;
   input  	 address_i;
   input         readstrobe_i;
   


   reg 		 tx_o;
   wire [7:0] 	 data_o;
   wire 	 clk_i;
   wire 	 rst_i;
   wire 	 rx_i;
   wire 	 writestrobe_i;
   wire [7:0] 	 data_i;
   wire  	 address_i;
   wire 	 readstrobe_i;

   wire [7:0]	 statusreg;
   
   

   
   reg 		 rx_int_r;

   // Baud rate divisor
   parameter [11:0]	 baudrate_r = 868; // For 100 MHz. FIXME - make this configurable!
   //   parameter [11:0]	 baudrate_r = 271; // For 31.25 MHz. FIXME - make this configurable!
   
   reg 		 rx_avail_r;
   reg 		 rx_avail_strobe;

   reg [1:0] 	 next_rx_state;
   reg [1:0] 	 rx_state_r;

   reg [7:0] 	 next_rx_shiftreg;
   reg [7:0] 	 rx_shiftreg_r;
   reg [3:0] 	 next_rx_bitcount;
   reg [3:0] 	 rx_bitcount_r;
   reg [15:0] 	 rx_counter_r;
   reg [15:0] 	 next_rx_counter;

   reg 		 next_tx_o;
   reg [3:0] 	 next_tx_bitcount;
   


   reg [1:0] 	 next_tx_state;
   reg [1:0] 	 tx_state_r;

   reg [7:0] 	 next_tx_shiftreg;
   reg [7:0] 	 tx_shiftreg_r;
   reg [3:0] 	 tx_bitcount_r;
   reg [15:0] 	 tx_counter_r;
   reg [15:0] 	 next_tx_counter;

   
   
   
   

   always @(posedge clk_i) begin
      rx_int_r <= rx_i;
   end

   


   
   always @(posedge clk_i) begin
      if(rst_i == 1'b1) begin
	 rx_avail_r <= 0;
      end else begin
	 if(rx_avail_strobe) begin
	    rx_avail_r <= 1;
	 end else if((address_i == 1'b1) && readstrobe_i) begin
	    // Clear UART rx reg by writing 1 to bit 14 of this reg
	    rx_avail_r <= 0;
	 end
      end
   end
   
   
   // RX Flip flops
   always @(posedge clk_i)  begin
      if(rst_i == 1'b1) begin
	 rx_state_r <= `STATE_IDLE;
	 rx_shiftreg_r <= 0;
	 rx_counter_r <= 0;
	 rx_bitcount_r <= 0;
	 
      end else begin
	 rx_state_r <= next_rx_state;
	 rx_shiftreg_r <= next_rx_shiftreg;
	 rx_counter_r <= next_rx_counter;
	 rx_bitcount_r <= next_rx_bitcount;
      end
   end // always @ (posedge clk_i)

   always @(*) begin
      rx_avail_strobe = 0;
      next_rx_state = rx_state_r;
      next_rx_shiftreg = rx_shiftreg_r;
      next_rx_counter = rx_counter_r;
      next_rx_bitcount = rx_bitcount_r;

      case(rx_state_r)
	`STATE_IDLE: begin
	   if(rx_int_r == 1'b0) begin
	      next_rx_state = `STATE_STARTBIT;
	      next_rx_counter = {5'd0, baudrate_r[11:1]};	 // Half a period
	   end
	end

	`STATE_STARTBIT: begin
	   next_rx_counter = rx_counter_r - 1;
	   
	   if(rx_counter_r == 16'd0) begin
	      if(rx_int_r == 1'b0) begin
		 next_rx_state = `STATE_DATABITS;
		 next_rx_counter = {4'd0, baudrate_r};	 // A full period
		 next_rx_bitcount = 4'd7;
	      end else begin
		 next_rx_state = `STATE_IDLE; // Probably a spurious startbit
	      end
	   end
	end

	`STATE_DATABITS: begin
	   next_rx_counter = rx_counter_r - 1;

	   if(rx_counter_r == 16'd0) begin
	      next_rx_shiftreg[6:0] = rx_shiftreg_r[7:1];
	      next_rx_shiftreg[7] = rx_int_r;
	      next_rx_counter = {4'd0, baudrate_r};
	      next_rx_bitcount = rx_bitcount_r - 1;
	      if(rx_bitcount_r == 4'b0) begin
		 next_rx_state = `STATE_STOPBIT;
	      end
	   end
	end

	`STATE_STOPBIT: begin
	   next_rx_counter = rx_counter_r - 1;

	   if(rx_counter_r == 16'd0) begin
	      rx_avail_strobe = 1;
	      next_rx_state = `STATE_IDLE;
	   end
	end
	
      endcase // case(rx_state_r)
   end
   
   

   // TX Flip flop
   always @(posedge clk_i)  begin
      if(rst_i == 1'b1) begin
	 tx_state_r <= `STATE_IDLE;
	 tx_shiftreg_r <= 0;
	 tx_counter_r <= 0;
	 tx_o <= 1;
	 tx_bitcount_r <= 0;
	 
      end else begin
	 tx_state_r <= next_tx_state;
	 tx_shiftreg_r <= next_tx_shiftreg;
	 tx_counter_r <= next_tx_counter;
	 tx_o <= next_tx_o;
	 tx_bitcount_r <= next_tx_bitcount;
      end
   end // always @ (posedge clk_i)

   // TX combinational logic

   assign statusreg[7:2] = 6'b0;
   assign statusreg[1] = (tx_state_r == `STATE_IDLE);
   assign statusreg[0] = rx_avail_r;
   
   assign data_o = (address_i == 1'b0) ? rx_shiftreg_r : statusreg;
   
   
   
   always @(*) begin
      // Default values
      next_tx_state = tx_state_r;
      next_tx_shiftreg = tx_shiftreg_r;
      next_tx_counter = tx_counter_r;
      next_tx_o = 1;
      next_tx_bitcount = tx_bitcount_r;
      
      case(tx_state_r)
	`STATE_IDLE: begin
	   if(writestrobe_i && (address_i == 1'b0)) begin
	      next_tx_shiftreg = data_i[7:0];
	      next_tx_state = `STATE_STARTBIT;
	      next_tx_counter = {4'd0, baudrate_r};
	      $display("%m: Writing out '%c'",data_i[7:0]);
	   end
	end

	`STATE_STARTBIT : begin
	   next_tx_o = 0;
	   if(tx_counter_r == 16'd0) begin
	      next_tx_counter = {4'd0, baudrate_r};
	      next_tx_state = `STATE_DATABITS;
	      next_tx_bitcount = 4'd8;
	   end else begin
	      next_tx_counter = tx_counter_r - 1;
	   end
	end

	`STATE_DATABITS : begin
	   if(next_tx_bitcount != 0) begin
	      next_tx_o = tx_shiftreg_r[0];
	   end else begin
	      next_tx_o = 1;
	      next_tx_state = `STATE_STOPBIT;
	   end
	   

	   if(tx_counter_r == 16'd0) begin
	      next_tx_counter = {4'd0,baudrate_r};
	      next_tx_bitcount = tx_bitcount_r - 1;
	      next_tx_shiftreg[6:0] = tx_shiftreg_r[7:1];
	      next_tx_shiftreg[7] = 0;
	   end else begin
	      next_tx_counter = tx_counter_r - 1;
	   end
	   
	end // case: `STATE_DATABITS

	`STATE_STOPBIT : begin
	   next_tx_counter = tx_counter_r - 1;
	   if(tx_counter_r == 0) begin
	      next_tx_state = `STATE_IDLE;
	   end
	end
      endcase // case(tx_state_r)
   end // always @ (*)



endmodule // fpga_uart
