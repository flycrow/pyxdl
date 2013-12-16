`timescale 1ns / 10ps
`default_nettype none

module tb;

   wire [7:0] led;
   reg       clk;
   reg       rst;
   wire       tx;
   reg       rx;

   reg [31:0] parport_i;
   wire [31:0] parport_o;

   reg [63:0]  tracein;
   initial tracein = 0;

   always @(posedge clk) begin
      tracein <= tracein + 64'h1;
   end
   

   system mcu(
		     // Outputs
		     .tx_o		(tx),
		     // Inputs
		     .clk_i		(clk),
		     .rx_i		(rx),
	      .tracein(tracein));
   
		     

   reg 	       clockrunning;
   initial begin
      clockrunning = 1;
      while(clockrunning) begin
	 clk = 0;
	 #50;
	 clk = 1;
	 #50;
      end
   end

   parameter BAUDRATE = 100;
   defparam  mcu.mcu.io.uart.baudrate_r = BAUDRATE;
   

   
   reg [7:0] tx_char;

   task readchar;
     output reg [7:0] read_char;
     begin
	 @(posedge clk);
	 
	 while(tx == 1) begin
	    @(posedge clk);
	 end
	    
	 repeat (BAUDRATE / 2) @(posedge clk);
	 
	 repeat (8) begin
	    repeat (BAUDRATE) @(posedge clk);
	    tx_char <= (tx_char >> 1) | (tx<< 7);
	 end
	 
	 repeat (BAUDRATE) @(posedge clk);

	read_char <= tx_char;
	@(posedge clk);
	
     end
   endtask // readchar
      
   task expect_char;
      input [7:0] expectedchar;
      reg [7:0]   tmp;
      begin
	 readchar(tmp);
	 if(expectedchar !== tmp) begin
	    $display("%m: Did not receive the expected character: expected '%c' (%x), got '%c' (%x)",expectedchar,expectedchar,tx_char,tx_char);
	    $stop;
	 end
      end
   endtask // expect_char
   
      
   task wishbone_write;
      input [63:0] addr;
      input [63:0] data;
      integer 	    i;
      begin
	 putch("m");
	 expect_char("m");
	 expect_char(" ");
	 for(i = 7; i >= 0; i = i - 1) begin
	    putch(addr[63:56]);
	    expect_char(addr[63:56]);
	    addr = addr << 8;
	 end
	 expect_char(" ");
//	 putch(" ");
	 for(i = 7; i >= 0; i = i - 1) begin
	    putch(data[63:56]);
	    expect_char(data[63:56]);
	    data = data << 8;
	 end
	 expect_char(8'h0d);
	 expect_char("\n");
	 expect_char(">");
      end
   endtask // wishbone_write

   task parport_write;
      input [63:0] data;
      integer 	    i;
      begin
	 putch("o");
	 expect_char("o");
	 expect_char(" ");
	 for(i = 7; i >= 0; i = i - 1) begin
	    putch(data[63:56]);
	    expect_char(data[63:56]);
	    data = data << 8;
	 end
	 expect_char(8'h0d);
	 expect_char("\n");
	 expect_char(">");
      end
   endtask // parport_write
      
   task putch;
      input  [7:0] char;
      begin
	 $display("Trying to write out '%c'",char);
	 @(posedge clk);

	 rx <= 0;
	 repeat(BAUDRATE) @(posedge clk);

	 rx <= char[0];
	 repeat(BAUDRATE) @(posedge clk);

	 rx <= char[1];
	 repeat(BAUDRATE) @(posedge clk);

	 rx <= char[2];
	 repeat(BAUDRATE) @(posedge clk);

	 rx <= char[3];
	 repeat(BAUDRATE) @(posedge clk);

	 rx <= char[4];
	 repeat(BAUDRATE) @(posedge clk);

	 rx <= char[5];
	 repeat(BAUDRATE) @(posedge clk);

	 rx <= char[6];
	 repeat(BAUDRATE) @(posedge clk);

	 rx <= char[7];
	 repeat(BAUDRATE) @(posedge clk);

	 // stopbit
	 rx <= 1;
	 repeat(BAUDRATE) @(posedge clk);
      end
   endtask // putch

   task bytetohex;
      input wire [7:0] c;
      output reg [3:0] x;
      begin
	 if(c < 8'h30) begin
	    $display("%m: Unexpected character %x",c);
	    $stop;
	 end if(c <= 8'h39) begin
	    x = c - 8'h30;
	 end else if(c < 8'h41) begin
	    $display("%m: Unexpected character %x",c);
	    $stop;
	 end else if(c <= 8'h46) begin
	    x = c - 8'h41 + 10;
	 end else if(c < 8'h61) begin
	    $display("%m: Unexpected character %x",c);
	    $stop;
	 end else if(c <= 8'h66) begin
	    x = c - 8'h61 + 10;
	 end else begin
	    $display("%m: Unexpected character %x",c);
	    $stop;
	 end
      end
   endtask // bytetohex

   task read_longword;
      output reg [31:0] x;
      reg [7:0] 	c;
      reg [3:0] 	i;
      begin
	 for(i = 0; i < 8; i = i + 1) begin
	    readchar(c);
	    x = x << 4;
	    bytetohex(c,x[3:0]);
	 end
      end
   endtask // read_longword
   
   task parport_read;
      output reg [31:0] readval;
      reg [7:0] 	tmp;
      
      begin
	 putch("i");
	 expect_char("i");

	 expect_char(8'h0d);
	 expect_char(8'h0a);

	 read_longword(readval);

	 expect_char(8'h0d);
	 expect_char(8'h0a);
	 expect_char(">");
      end
   endtask // parport_read
   
   

   reg [7:0] thecharacter;
   reg [31:0] readval;
   task test_parport;
      begin
	 parport_read(readval);
	 if(readval == 32'hf00f1234) begin
	    $display("%m: Success, read parport successfully");
	 end else begin
	    $display("%m: Failure, parport_i is 32'haf5596de, read %x",readval);
	    $stop;
	 end
      end
   endtask // test_parport


   task test_display();
      begin
	 putch("T");
	 expect_char("T");
	 expect_char(8'h0d);
	 expect_char(8'h0a);
	 expect_char(8'h41);
	 expect_char(8'h45);

	 expect_char(8'h0d);
	 expect_char(8'h0a);
	 expect_char(8'h54);
	 expect_char(8'h72);
	 expect_char(8'h69);
	 expect_char(8'h67);
	 expect_char(8'h76);
	 expect_char(8'h61);
	 expect_char(8'h6c);
	 expect_char(8'h3a);

	 expect_char(8'h09);
	 putch_and_expect("7");
	 putch_and_expect("a");
	 expect_char(8'h09);
	 putch_and_expect("3");
	 putch_and_expect("2");
	 expect_char(8'h09);

	 expect_char(8'h0d);
	 expect_char(8'h0a);
	 expect_char(8'h4d);
	 expect_char(8'h61);
	 expect_char(8'h73);
	 expect_char(8'h6b);
	 expect_char(8'h76);
	 expect_char(8'h61);
	 expect_char(8'h6c);
	 expect_char(8'h3a);
	 
	 expect_char(8'h09);
	 putch_and_expect("f");
	 putch_and_expect("f");
	 expect_char(8'h09);
	 putch_and_expect("f");
	 putch_and_expect("f");
	 expect_char(8'h09);
	 

	 expect_char(8'h0d);
	 expect_char("\n");

	 
	 expect_char(">");

	 putch_and_expect("t");
	 expect_char(8'h0d);
	 expect_char("\n");
	 expect_char(">");

	 
	 putch("D");
	 @(parport_i);
      end
   endtask // test_display

   task putch_and_expect;
      input  [7:0] char;
      begin
	 putch(char);
	 expect_char(char);
      end
   endtask // putch_and_expect
   
   
   initial begin
      rx = 1;
      rst = 1;
      repeat(100) @(posedge clk);
      rst <= 0;

      thecharacter = 0;
      while(thecharacter != 8'h3e) begin
	 readchar(thecharacter);
	 $display("%m: Got %c",thecharacter);
      end

      test_display();
      
      clockrunning = 0;
   end

endmodule // tb_system
