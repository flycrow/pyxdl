module tracer(
   input wire clk_i,
   input wire rst_i,

   input wire [63:0] data_i,
   
   // Wishbone slave interface
   input wire [31:0] wbs_dat_i,
   output reg [31:0] wbs_dat_o,
   output reg 	 wbs_ack_o,
   input wire [31:0]  wbs_adr_i,
   input wire 	 wbs_stb_i,
    input wire 	 wbs_we_i);
   


   reg [63:0] 	 trig_enable_r;
   reg [63:0] 	 trig_val_r;
   reg 		 trig;
   

   reg [10:0] 	 counter_r;

   // Block ram interface
   reg [63:0] 	 tomem_r;
   wire [63:0] 	 frommem;
   reg 		 mem_we_r;
   
   reg [63:0] datain_r;
   


   always @(posedge clk_i) begin
      datain_r <= data_i;
   end
   
   // Trigger
   always @(*) begin
      if((datain_r & trig_enable_r) == trig_val_r) begin
	 trig = 1;
      end else begin
	 trig = 0;
      end
   end


   reg [1:0] state_r;

   parameter IDLE = 2'b00;
   parameter ARMED = 2'b01;
   parameter RUNNING = 2'b10;
   wire      abort_running;

   assign    abort_running = wbs_stb_i && wbs_we_i && (wbs_adr_i[7:0] == 8'h20);

   always @(*) begin
      wbs_ack_o = wbs_stb_i;
      wbs_dat_o = 32'h4c4f4749;
      case(wbs_adr_i[7:0])
	8'h00: wbs_dat_o = {31'b0,state_r == IDLE ? 1'b1 : 1'b0};
	8'h04: wbs_dat_o = trig_enable_r[31:0];
	8'h08: wbs_dat_o = trig_enable_r[63:32];
	8'h0c: wbs_dat_o = trig_val_r[31:0];	
	8'h10: wbs_dat_o = trig_val_r[63:32];
	8'h14: wbs_dat_o = counter_r;
	8'h40: wbs_dat_o = frommem[31:0];
	8'h44: wbs_dat_o = frommem[63:32];
      endcase // case(wbs_adr_i[7:0])
   end

   
   always @(posedge clk_i) begin
      if(rst_i) begin
	 counter_r <= 0;
	 state_r   <= IDLE;
	 mem_we_r <= 1'b0;

	 trig_enable_r <= 64'h0;
	 trig_val_r <= 64'h1; // Can never trigger!
      end else begin
	 case(state_r)
	   IDLE: begin
	      mem_we_r <= 0;
	      if(wbs_stb_i & wbs_we_i) begin
		 case(wbs_adr_i[7:0])
		   8'h00:
		      if(wbs_dat_i[0]) begin
			 state_r <= ARMED;
			 counter_r <= 11'h7ff;
		      end
		   8'h04: trig_enable_r[31:0] <= wbs_dat_i;
		   8'h08: trig_enable_r[63:32] <= wbs_dat_i;
		   8'h0c: trig_val_r[31:0] <= wbs_dat_i;
		   8'h10: trig_val_r[63:32] <= wbs_dat_i;
		   8'h14: counter_r <= wbs_dat_i[10:0];
		 endcase // case(wbs_adr_i[15:0])
	      end // if (wbs_stb_i & wbs_we_i)
	   end // case: IDLE
	   ARMED:
	     if(abort_running) begin
		state_r <= IDLE;
	     end else if(trig) begin
		state_r <= RUNNING;
		tomem_r <= datain_r;
		mem_we_r <= 1'b1;
		counter_r <= counter_r + 1;
	     end
	   RUNNING: begin
	      tomem_r <= datain_r;
	      mem_we_r <= 1'b1;
	      counter_r <= counter_r + 1;
	      if(abort_running) begin
		 state_r <= IDLE;
	      end
	      if(counter_r == 11'h7ff) begin
		 state_r <= IDLE;
		 mem_we_r <= 1'b0;
	      end
	   end
	 endcase // case(state_r)
      end
   end


   RAMB16_S9 ram0(
		  .CLK(clk_i),
		  .SSR(1'b0),
		  .ADDR(counter_r),
		  .DI(tomem_r[7:0]),
		  .DO(frommem[7:0]),
		  .DIP(1'b0),
		  .DOP(),
		  .WE(mem_we_r),
		  .EN(1'b1)
		  );

   RAMB16_S9 ram1(
		  .CLK(clk_i),
		  .SSR(1'b0),
		  .ADDR(counter_r),
		  .DI(tomem_r[15:8]),
		  .DO(frommem[15:8]),
		  .DIP(1'b0),
		  .DOP(),
		  .WE(mem_we_r),
		  .EN(1'b1)
		  );

   RAMB16_S9 ram2(
		  .CLK(clk_i),
		  .SSR(1'b0),
		  .ADDR(counter_r),
		  .DI(tomem_r[23:16]),
		  .DO(frommem[23:16]),
		  .DIP(1'b0),
		  .DOP(),
		  .WE(mem_we_r),
		  .EN(1'b1)
		  );

   RAMB16_S9 ram3(
		  .CLK(clk_i),
		  .SSR(1'b0),
		  .ADDR(counter_r),
		  .DI(tomem_r[31:24]),
		  .DO(frommem[31:24]),
		  .DIP(1'b0),
		  .DOP(),
		  .WE(mem_we_r),
		  .EN(1'b1)
		  );

   RAMB16_S9 ram4(
		  .CLK(clk_i),
		  .SSR(1'b0),
		  .ADDR(counter_r),
		  .DI(tomem_r[39:32]),
		  .DO(frommem[39:32]),
		  .DIP(1'b0),
		  .DOP(),
		  .WE(mem_we_r),
		  .EN(1'b1)
		  );

   RAMB16_S9 ram5(
		  .CLK(clk_i),
		  .SSR(1'b0),
		  .ADDR(counter_r),
		  .DI(tomem_r[47:40]),
		  .DO(frommem[47:40]),
		  .DIP(1'b0),
		  .DOP(),
		  .WE(mem_we_r),
		  .EN(1'b1)
		  );

   RAMB16_S9 ram6(
		  .CLK(clk_i),
		  .SSR(1'b0),
		  .ADDR(counter_r),
		  .DI(tomem_r[55:48]),
		  .DO(frommem[55:48]),
		  .DIP(1'b0),
		  .DOP(),
		  .WE(mem_we_r),
		  .EN(1'b1)
		  );

   RAMB16_S9 ram7(
		  .CLK(clk_i),
		  .SSR(1'b0),
		  .ADDR(counter_r),
		  .DI(tomem_r[63:56]),
		  .DO(frommem[63:56]),
		  .DIP(1'b0),
		  .DOP(),
		  .WE(mem_we_r),
		  .EN(1'b1)
		  );
   
		  
   
endmodule // tracer
