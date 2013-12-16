`default_nettype none

module serial_wb_mcu(
	   // System signals
	   clk_i, rst_i,

	   // Program memory address, instruction from program memory
	   pm_addr_o, pm_insn_i,

	   // Data port 0 and 1 (out)
	   port0_o,
	   port1_o,

	   strobe1_o,

	   // Data port 0 and 1 (in)
	   port2_i,
	   strobe2_o
	   );

   input clk_i;
   input rst_i;

   output [9:0] pm_addr_o;
   input [15:0] pm_insn_i;

   output reg [7:0] port0_o;
   output reg [7:0] port1_o;

   output 	strobe1_o;
   

   input wire [7:0] 	port2_i;
   
   output 	strobe2_o;

   wire 	clk_i;
   wire 	rst_i;

   reg [9:0] 	pm_addr_o;
   wire [15:0] 	pm_insn_i;


   reg 	strobe1_o;

   reg  strobe2_o;

   reg [7:0] port2_r;


   reg [15:0] insnreg;
   



   // Internal registers and wires:
   //

   
   // Register file (16x8 bit registers)
   reg [7:0] 	regfile[15:0];
   reg [7:0] 	rf_op_a;
   reg [7:0] 	rf_op_b;
   
   reg 		rf_w; // Writeback enable
   reg [7:0] 	rf_result; // Writeback input
   reg [3:0] 	rf_index_r; // Writeback register
   

   // ALU
   reg [8:0] 	alu_result;
   reg 		alu_flag_z;
   reg 		alu_flag_c;
   
   
   // Program counter
   reg [8:0] 	pc;


   // 2 slot stack for PC
   reg [8:0] 	returnpc_0; // Return address from a jsr
   reg [8:0] 	next_returnpc_0;

   reg [8:0] 	returnpc_1; // Return address from a jsr
   reg [8:0] 	next_returnpc_1;


   
   
   // Instructions  ( *tested means that it is tested in the testbench)
   // Register modification group
   // 0x0000ddddssssSSSS Rd = Rs + RS (set flags)     
   // 0x0001ddddssssSSSS Rd = Rs ^ RS (set flags)     
   // 0x0010ddddssssSSSS Rd = Rs & RS (set flags)     
   // 0x0011ddddssssSSSS Rd = Rs | RS (set flags)     
   // 0x0100ddddiiiiiiii Rd = immediate               
   // 0x0101dddd00000000 Rd = Port 2                  
   // 0x0110dddd00000000 Rd = Address[port0+768]
   // 0x0111ddddssss0000 Rd = Swap nibbles(Rs)        

   // Jump/misc group
   // 0x1000000aaaaaaaaa Jump to address a            
   // 0x1000001aaaaaaaaa Jump to address a if zero
   // 0x1000010aaaaaaaaa Jump to address a if carry
   // 0x1000011aaaaaaaaa Jump to subroutine
   // 0x1000100000000000 Return from subroutine
   // 0x10010000ssss0000 Port 0 = Rs                  
   // 0x10010001ssss0000 Port 1 = Rs
   

   always @(posedge clk_i) begin
      port2_r <= port2_i;
   end
   
   
   reg [7:0] from_pm_r;
   always @(posedge clk_i) begin
      if(!rf_op_b[0]) begin
	 from_pm_r <= pm_insn_i[15:8];
      end else begin
	 from_pm_r <= pm_insn_i[7:0];
      end
   end


   // Writeback
   always @(posedge clk_i)
     if(rst_i) begin
     end else begin
	if(rf_w)
	  regfile[rf_index_r] <= rf_result;
     end

   wire [7:0] rf_output;
   
   // Decode operands
   assign rf_output = regfile[rf_index_r];



   localparam [1:0] FETCH = 2'd0;   // Fetch INSN  && Writeback
   localparam [1:0] DECODE1 = 2'd1;  // Fetch OP1
   localparam [1:0] DECODE2 = 2'd2; // Fetch OP2
   localparam [1:0] EXECUTE = 2'd3; // Execute
   reg [1:0] 	    state_r;

   always @(posedge clk_i)
      if(rst_i) begin
	 $display("In reset");
	 state_r <= FETCH;
      end else begin
	 case(state_r)
	   FETCH: state_r <= DECODE1;
	   DECODE1: state_r <= DECODE2;
	   DECODE2: state_r <= EXECUTE;
	   EXECUTE: state_r <= FETCH;
	 endcase // case(state_r)
      end

   always @(posedge clk_i)
     if(rst_i) begin
	insnreg <= 16'hffff;
     end else begin
	if(state_r == FETCH) begin
	   insnreg <= pm_insn_i;

	   if(pm_insn_i == 16'hfffe) begin
	      $display("Breakpoint!");
	      $stop;
	   end
	end
     end

   always @* 
      case(state_r)
	FETCH: rf_index_r = insnreg[11:8];
	DECODE1: rf_index_r = insnreg[7:4];
	DECODE2: rf_index_r = insnreg[3:0];
	default: rf_index_r = insnreg[3:0];
      endcase // case(state_r)
   
   always @(posedge clk_i) begin
      if(state_r == DECODE1) rf_op_a <= rf_output;
      if(state_r == DECODE2) rf_op_b <= rf_output;
   end
   
   
   always @* begin
      if(state_r == DECODE1) begin
	 pm_addr_o = {rf_op_a[2:0],rf_op_b[7:1]};
	 //	 pm_addr_o = {2'b11, port0_o[7:1]};
      end else begin
	 pm_addr_o = pc;
      end
   end // UNMATCHED !!


   always @(posedge clk_i)
     if(rst_i) begin
	pc <= 0;
	returnpc_0 <= 0;
	returnpc_1 <= 0;
     end else begin
	if(state_r == FETCH) begin
	   pc <= pc + 1;
	end else if(state_r == DECODE1) begin
	   if(insnreg[15:12] == 4'b1000) begin
	      case(insnreg[11:9])
		3'b000:
		  pc <= insnreg[8:0];
		3'b001:
		  if(alu_flag_z)
		    pc <= insnreg[8:0];
		3'b010:
		  if(alu_flag_c)
		    pc <= insnreg[8:0];
		3'b011: begin
		   pc <= insnreg[8:0];
		   returnpc_0 <= pc;
		   returnpc_1 <= returnpc_0;
		end
		
		default: begin
		   pc <= returnpc_0;
		   returnpc_0 <= returnpc_1;
		end
	      endcase // case(insnreg[11:9])
	   end // if (insnreg[15:12] == 4'b1000)
	end
     end // else: !if(rst_i)

   // Output ports:
   always @(posedge clk_i)
     if(rst_i) begin
	port0_o <= 0;
	port1_o <= 0;
	strobe1_o <= 0;
     end else begin
	strobe1_o <= 0;
	if(state_r == EXECUTE) begin
	   if(insnreg[15:12] == 4'b1001) begin
	      if(insnreg[8] == 0) begin
		 port0_o <= rf_op_a;
	      end else begin
		 strobe1_o <= 1;
		 port1_o <= rf_op_a;
	      end
	   end
	end
     end // else: !if(rst_i)
   
   reg [7:0] alu_result_r;
   // ALU
   always @*
     case(insnreg[13:12])
       2'b00:   alu_result = { 1'b0 , rf_op_a} + {1'b0, rf_op_b};
       2'b01:   alu_result = rf_op_a ^ rf_op_b;
       2'b10:   alu_result = rf_op_a & rf_op_b;
       default: alu_result = rf_op_a | rf_op_b;
     endcase // case(pm_insn[13:12])
   

   // Flag generation
   always @(posedge clk_i)
     if(rst_i) begin
	alu_result_r <= 8'b0;
     end else begin
	alu_result_r <= alu_result;
	// Check to see if it is an ALU op
     end // else: !if(rst_i)


   always @(posedge clk_i)
     if(rst_i) begin
	alu_flag_c <= 0;
	alu_flag_z <= 0;
	strobe2_o <= 1'b0;
	rf_w <= 0;
     end else begin
	strobe2_o <= 1'b0;
	rf_w <= 0;
	
      if(state_r == DECODE1) begin
	 if(insnreg[15:12] == 4'b0101) begin
	    strobe2_o <= 1'b1;
	 end
      end else if(state_r == EXECUTE) begin
	 case(insnreg[15:14])

	   2'b00: begin // ALU operation
	      rf_result <= alu_result;
	      rf_w <= 1;
	      alu_flag_c <= alu_result[8];
	      if(alu_result[7:0] == 0) // Don't need ALU_flags just now...
		alu_flag_z <= 1;
	      else
		alu_flag_z <= 0;
	   end

	   2'b01: begin
	      rf_w <= 1;
	      case(insnreg[13:12])
		2'b00: begin
		   rf_result <= insnreg[7:0];
		end
		
		2'b01: begin
		   rf_result <= port2_r;
		end

		2'b10: begin
		   rf_result <= from_pm_r;
		end

		default: begin
		   rf_result <= {rf_op_a[3:0], rf_op_a[7:4]};
		end
	      endcase // case(insnreg[13:12])

	   end

	   default: begin
	      rf_w <= 0;
	   end
	 endcase // case(insnreg[15:14])
      end
   end



endmodule // mcu
