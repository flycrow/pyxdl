
module serial_wb_parport( 
		  /*AUTOARG*/
		  // Outputs
		  parport_o, data_o, parport_readstrobe_o,parport_writestrobe_o,
		  // Inputs
		  clk_i, rst_i, parport_i, writestrobe_i, readstrobe_i,data_i, address_i
		  );



   output [31:0] parport_o;
   
   output [7:0]  data_o;
   input         clk_i;
   input         rst_i;
   input [31:0]  parport_i;
   
   input         writestrobe_i;
   input [7:0] 	 data_i;
   input [1:0] 	 address_i;
   input         readstrobe_i;

   output 	 parport_writestrobe_o;
   output 	 parport_readstrobe_o;

   reg [31:0] parport_o;
   reg [7:0] 	 data_o;
   wire 	 clk_i;
   wire 	 rst_i;
   wire 	 writestrobe_i;
   wire [31:0]  parport_i;
   wire [7:0] 	 data_i;
   wire [1:0] 	 address_i;
   wire 	 readstrobe_i;


   reg [23:0]	 outputreg_r;
   reg [23:0]	 inputreg_r;

   reg 		 parport_readstrobe_o;
   reg 		 parport_writestrobe_o;
   


   always @(*) begin
      data_o = parport_i[7:0];
      case(address_i)
	 2'b01: data_o = inputreg_r[7:0];
	 2'b10: data_o = inputreg_r[15:8];
	 2'b11: data_o = inputreg_r[23:16];
      endcase // case(address_i)

      
      parport_readstrobe_o = 0;
      if((address_i == 2'b00) && readstrobe_i) begin
	 parport_readstrobe_o = 1;
      end
   end

   always @(posedge clk_i) begin
      parport_writestrobe_o <= 0;
      if(rst_i) begin
	 parport_o <= 0;
	 outputreg_r <= 0;
	 parport_writestrobe_o <= 0;
      end else if(writestrobe_i) begin
	 parport_writestrobe_o <= 0;
	 case(address_i)
	   2'b00: outputreg_r[7:0] <= data_i;
	   2'b01: outputreg_r[15:8] <= data_i;
	   2'b10: outputreg_r[23:16] <= data_i;
	   2'b11: begin
	      parport_o <= {data_i[7:0],outputreg_r[23:0]};
	      parport_writestrobe_o <= 1;
	   end
	   
	 endcase // case(address_i)
      end else if(readstrobe_i) begin
	 if(address_i == 2'b00) begin
	    inputreg_r <= parport_i[31:8];
	 end
      end
   end

endmodule // serial_wb_parport
