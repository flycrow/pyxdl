module serial_wb_mcu_tb();


   reg   clk;
   reg   rst;

   wire [8:0] pm_addr;
   reg [15:0] pm_insn;

   wire [7:0] port0;
   wire [7:0] port1;
   wire [7:0] port2;
   wire       strobe0;
   wire       strobe1;



   reg [6:0]  clockcycles;
   reg 	      done;
   reg [6:0]  testpoints;
   reg [6:0]  errors;
   
   reg [7:0] expected_port0;
   reg       expected_none;
   
   
   

   assign     port2 = 8'hab;
   

   serial_wb_mcu controller(.clk_i(clk),
		  .rst_i(rst),
		  .pm_addr_o(pm_addr),
		  .pm_insn_i(pm_insn),
		  .port0_o(port0),
		  .port1_o(port1),
		  .strobe0_o(strobe0),
		  .strobe1_o(strobe1),
		  .port2_i(port2));
   


   always @(posedge clk)
     case(pm_addr)
       // Test all regs, set and out0
       9'h000: pm_insn <= 16'h4034; // set #0x34,r0 
       9'h001: pm_insn <= 16'h41a0; // set #0xa0,r1 
       9'h002: pm_insn <= 16'h42d0; // set #0x54,r2 
       9'h003: pm_insn <= 16'h43ff; // set #0x01,r3 
       9'h004: pm_insn <= 16'h4401; // set #0xff,r4 
       9'h005: pm_insn <= 16'h45ca; // set #0xca,r5 
       9'h006: pm_insn <= 16'h4600; // set #0x00,r6 
       9'h007: pm_insn <= 16'h4701; // set #0x01,r7 
       9'h008: pm_insn <= 16'h4802; // set #0x02,r8 
       9'h009: pm_insn <= 16'h4904; // set #0x04,r9 
       9'h00a: pm_insn <= 16'h4a08; // set #0x08,r10
       9'h00b: pm_insn <= 16'h4b10; // set #0x10,r11
       9'h00c: pm_insn <= 16'h4c20; // set #0x20,r12
       9'h00d: pm_insn <= 16'h4d40; // set #0x40,r13
       9'h00e: pm_insn <= 16'h4e80; // set #0x80,r14
       9'h00f: pm_insn <= 16'h4faa; // set #0xaa,r15
       9'h010: pm_insn <= 16'h9000; // out0 r0 
       9'h011: pm_insn <= 16'h9010; // out0 r1 
       9'h012: pm_insn <= 16'h9020; // out0 r2 
       9'h013: pm_insn <= 16'h9030; // out0 r3 
       9'h014: pm_insn <= 16'h9040; // out0 r4 
       9'h015: pm_insn <= 16'h9050; // out0 r5 
       9'h016: pm_insn <= 16'h9060; // out0 r6 
       9'h017: pm_insn <= 16'h9070; // out0 r7 
       9'h018: pm_insn <= 16'h9080; // out0 r8 
       9'h019: pm_insn <= 16'h9090; // out0 r9 
       9'h01a: pm_insn <= 16'h90a0; // out0 r10
       9'h01b: pm_insn <= 16'h90b0; // out0 r11
       9'h01c: pm_insn <= 16'h90c0; // out0 r12
       9'h01d: pm_insn <= 16'h90d0; // out0 r13
       9'h01e: pm_insn <= 16'h90e0; // out0 r14
       9'h01f: pm_insn <= 16'h90f0; // out0 r15
       // Test all ALU instructions
       9'h020: pm_insn <= 16'h40a0; // set #0xa0,r0
       9'h021: pm_insn <= 16'h4175; // set #0x75,r1
       9'h022: pm_insn <= 16'h4201; // set #0x01,r2
       // test add
       9'h023: pm_insn <= 16'h0401; // add r0,r1,r4
       9'h024: pm_insn <= 16'h0512; // add r1,r2,r5
       9'h025: pm_insn <= 16'h9040; // out0 r4
       9'h026: pm_insn <= 16'h9050; // out0 r5
       // test xor
       9'h027: pm_insn <= 16'h1601; // xor r0,r1,r6
       9'h028: pm_insn <= 16'h1702; // xor r0,r2,r7
       9'h029: pm_insn <= 16'h9060; // out0 r6
       9'h02a: pm_insn <= 16'h9070; // out0 r7
       // test and
       9'h02b: pm_insn <= 16'h2801; // and r0,r1,r8
       9'h02c: pm_insn <= 16'h2902; // and r0,r2,r9
       9'h02d: pm_insn <= 16'h9080; // out0 r8
       9'h02e: pm_insn <= 16'h9090; // out0 r9
       // test or
       9'h02f: pm_insn <= 16'h3a01; // or r0,r1,r10
       9'h030: pm_insn <= 16'h3b02; // or r0,r2,r11
       9'h031: pm_insn <= 16'h90a0; // out0 r10
       9'h032: pm_insn <= 16'h90b0; // out0 r11
       // Test in2
       9'h033: pm_insn <= 16'h4000; // set #0,r0
       9'h034: pm_insn <= 16'h5000; // in2 r0
       9'h035: pm_insn <= 16'h9000; // out0 r0
       // test ld [R]
       9'h036: pm_insn <= 16'h40e0; // set #0xe0,r0 (&data)
       9'h037: pm_insn <= 16'h41e1; // set #0xe1,r1 (&data+1)
       9'h038: pm_insn <= 16'h6200; // ld [r0],r2
       9'h039: pm_insn <= 16'h6310; // ld [r1],r3
       9'h03a: pm_insn <= 16'h9020; // out0 r2
       9'h03b: pm_insn <= 16'h9030; // out0 r3
       // test swap
       9'h03c: pm_insn <= 16'h40f0; // set #0xf0,r0
       9'h03d: pm_insn <= 16'h7100; // swap r0,r1
       9'h03e: pm_insn <= 16'h9010; // out0 r1

       // test jmp
       9'h03f: pm_insn <= 16'h4000; // set #0,r0
       9'h040: pm_insn <= 16'h8044; // set #0,r0
       9'h041: pm_insn <= 16'h9000; // out0 r0
       9'h042: pm_insn <= 16'h9000; // out0 r0
       9'h043: pm_insn <= 16'h9000; // out0 r0
       9'h044: pm_insn <= 16'h40fe; // set #fe,r0
       9'h045: pm_insn <= 16'h9000; // out0 r0

       9'h046: pm_insn <= 16'h4040; // set #0x40,r0
       9'h047: pm_insn <= 16'h0000; // add r0,r0,r0
       9'h048: pm_insn <= 16'h824b; // beq 4b
       9'h049: pm_insn <= 16'h9000; // out0 r0
       9'h04a: pm_insn <= 16'h9000; // out0 r0
       9'h04b: pm_insn <= 16'h0000; // add r0,r0,r0
       9'h04c: pm_insn <= 16'h9000; // out0 r0
       9'h04d: pm_insn <= 16'h8250; // beq 50
       9'h04e: pm_insn <= 16'h9000; // out0 r0
       9'h04f: pm_insn <= 16'h9000; // out0 r0
       9'h050: pm_insn <= 16'h40df; // set #0xdf,r0
       9'h051: pm_insn <= 16'h9000; // out0 r0
       

       9'h1f0: pm_insn <= 16'hbeef; // data
       
       default: begin
	  if(!rst) begin
	     $display("*** ERROR: Executing on undefined location in PM at clock cycle %d",clockcycles);
	  end
	  pm_insn <= 16'h3000; // or r0,r0,r0 ; (nop)
       end
     endcase // case(pm_addr_i)
   


   initial begin
      rst = 1;
      clk = 0;
      done = 0;
      
      #50 clk = 1;
      #50 clk = 0;
      #50 clk = 1;
      #50 clk = 0;
      #50 clk = 1;

      #20 rst = 0;
      #30 clk = 0;
      #50 clk = 1;

   end // initial begin


   always begin
      if(done)
	$finish;
      
      
      #50 clk <= !clk;
   end

   always @(posedge clk)
     begin
	if(rst) begin
	   clockcycles <= 0;
	   testpoints <= 0;
	   errors <= 0;
	end else begin
	   clockcycles <= clockcycles + 1;

	   // Check for termination of testbench
	   if((strobe1 == 1) && (port1 == 8'hee)) begin
	      $display("Testbench finished:");
	      $display("  Testpoints passed: %d of 2",testpoints);
	      $display("  Clockcycles: %d",clockcycles);
	      $display("  Number of errors: %d",errors);
	      $stop;
	      
           // Check for runaway testbench
	   end else if(clockcycles > 120) begin
	      $display("*** ERROR: Testbench did not terminate in 120 clock cycles");
	      $stop;
	   end else begin

	      if(strobe0) begin
		 if(expected_none) begin
		    $display("*** Unexpected value written to port0 at clock cycle %d",clockcycles);
		    errors <= errors + 1;
		 end else if(expected_port0 == port0) begin
		  testpoints <= testpoints + 1;
		 end else begin
		    $display("*** Error: port0 == 0x%02x, expected value is 0x%02x at clock cycle %d",
			     port0,expected_port0,clockcycles);
		    errors <= errors + 1;
		 end
	      end else if(!expected_none) begin // if (strobe0)
		 $display("Expected a value on port0 at clock cycle %d",clockcycles);
		 errors <= errors + 1;
	      end
	      
	   end
	end
     end // always @ (posedge clk)

   always @(clockcycles) begin
      expected_none <= 0;
      case(clockcycles)
	7'd18: expected_port0 <= 8'h34;
	7'd19: expected_port0 <= 8'ha0;
	7'd20: expected_port0 <= 8'hd0;
	7'd21: expected_port0 <= 8'hff;
	7'd22: expected_port0 <= 8'h01;
	7'd23: expected_port0 <= 8'hca;
	7'd24: expected_port0 <= 8'h00;
	7'd25: expected_port0 <= 8'h01;
	7'd26: expected_port0 <= 8'h02;
	7'd27: expected_port0 <= 8'h04;
	7'd28: expected_port0 <= 8'h08;
	7'd29: expected_port0 <= 8'h10;
	7'd30: expected_port0 <= 8'h20;
	7'd31: expected_port0 <= 8'h40;
	7'd32: expected_port0 <= 8'h80;
	7'd33: expected_port0 <= 8'haa;
	
	7'd39: expected_port0 <= 8'h15;
	7'd40: expected_port0 <= 8'h76;
	
	7'd43: expected_port0 <= 8'hd5;
	7'd44: expected_port0 <= 8'ha1;
	
	7'd47: expected_port0 <= 8'h20;
	7'd48: expected_port0 <= 8'h00;
	
	7'd51: expected_port0 <= 8'hf5;
	7'd52: expected_port0 <= 8'ha1;
	
	7'd55: expected_port0 <= 8'hab;

	7'd62: expected_port0 <= 8'hbe;
	7'd63: expected_port0 <= 8'hef;
	7'd66: expected_port0 <= 8'h0f;

	7'd70: expected_port0 <= 8'hfe;

	7'd74: expected_port0 <= 8'h80;
	7'd75: expected_port0 <= 8'h80;
	7'd77: expected_port0 <= 8'h00;
	
	7'd80: expected_port0 <= 8'hdf;
	
	default:
	  expected_none <= 1;
      endcase // case(clockcycles)
   end
   
endmodule // serial_wb_top
