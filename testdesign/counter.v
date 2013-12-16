module counter(input clk_i,
	       output wire [7:0] led_o);

   reg [31:0] 	      ctr;

   assign 	      led_o = ctr[29:22];
   
   always @(posedge clk_i) begin
      ctr <= ctr +1 ;
   end
   

endmodule // counter
