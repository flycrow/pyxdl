#!/usr/bin/perl -w

# FIXME - figure out a way to use strict
#use strict;

my $address = 0;
my $newaddress = 0;
my $largestaddr = 0;
my $orig;
my %lables;
my $line;
my $op;
my $value;

my @program;
my $i;

# Very very simple and ugly two pass assembler

# first pass
open (FILE,$ARGV[0]);
while(<FILE>) {
    chomp;
    $orig = $_;
    s/;.*//g; # remove comments

    if(/^([a-z0-9A-Z_]+):/) {
	$lables{$1} = $address;
    }
    
    s/^[a-z0-9A-Z_]+://g; # remove label

    if ($address > 1023) {
	print STDERR "Program too large\n";
	exit 1;
    }

    if(/^[ \t]*$/) {
	# blank line
    }else{
	if(/org[ \t]+((0x)?([0-9a-fA-F]+))/){
	    $address = hex($1);
	}else{
	    $address++;
	}
    }

    if($address > $largestaddr) {
	$largestaddr = $address;
    }

}
close FILE;

for($i=0;$i<1024;$i++) {
    $program[$i] = sprintf("        10'h%03x: pm_insn_o <= 16'h0000;\n",$i);
}

$address = 0;
# second pass
open (FILE,$ARGV[0]);
$line = 0;
while(<FILE>) {
    chomp;
    $line++;
    $orig = $_;
    s/;.*//g; # remove comments

    s/^[a-z0-9A-Z_]+://g; # remove label

    # Check for org directive

    $op = "    ";

    if(/^[ \t]*$/) {
	# blank line
    }else{
	$newaddress = $address + 1;
	# remove start/ending blank space
	s/^[ \t]*//g;
	s/[ \t]*$//g;
	if(/org[ \t]+((0x)?([0-9a-fA-F]+))/){
	    $newaddress = hex($1);
	    $address = $newaddress;
	}elsif(/add[ \t]+r([0-9]+),r([0-9]+),r([0-9]+)/){
	    &validatereg($1);
	    &validatereg($2);
	    &validatereg($3);
	    $op = sprintf("0%x%x%x",$3,$1,$2);
	}elsif(/xor[ \t]+r([0-9]+),r([0-9]+),r([0-9]+)/){
	    &validatereg($1);
	    &validatereg($2);
	    &validatereg($3);
	    $op = sprintf("1%x%x%x",$3,$1,$2);
	}elsif(/and[ \t]+r([0-9]+),r([0-9]+),r([0-9]+)/){
	    &validatereg($1);
	    &validatereg($2);
	    &validatereg($3);
	    $op = sprintf("2%x%x%x",$3,$1,$2);
	}elsif(/or[ \t]+r([0-9]+),r([0-9]+),r([0-9]+)/){
	    &validatereg($1);
	    &validatereg($2);
	    &validatereg($3);
	    $op = sprintf("3%x%x%x",$3,$1,$2);
	}elsif(/set[ \t]+#0x([0-9a-fA-F]+),r([0-9]+)/){
	    &validatereg($2);
	    &validateimm(hex($1));
	    $op = sprintf("4%x%02x",$2,hex($1));
	}elsif(/set[ \t]+HIGH[ \t]+([a-z0-9A-Z_]+),r([0-9]+)/){
	    &validatelabel($1);
	    &validatereg($2);
	    $value = (($lables{$1} * 2 ) & 0xff00) >> 8;
	    $op = sprintf("4%x%02x",$2,$value);
	}elsif(/set[ \t]+LOW[ \t]+([a-z0-9A-Z_]+),r([0-9]+)/){
	    &validatelabel($1);
	    &validatereg($2);
	    $value = (($lables{$1} * 2 ) & 0xff) >> 0;
	    $op = sprintf("4%x%02x",$2,$value);
	}elsif(/in2[ \t]+r([0-9]+)/){
	    &validatereg($1);
	    $op = sprintf("5%x00",$1);
	}elsif(/ld[ \t]+r([0-9]+),r([0-9]+),r([0-9]+)/){
	    &validatereg($1);
	    &validatereg($2);
	    &validatereg($3);
	    $op = sprintf("6%x%x%x",$3,$1,$2);
	}elsif(/swap[ \t]+r([0-9]+),r([0-9]+)/){
	    &validatereg($1);
	    &validatereg($2);
	    $op = sprintf("7%x%x0",$2,$1);
	}elsif(/jmp[ \t]+([a-z0-9A-Z_]+)/){
	    &validatelabel($1);
	    $op = sprintf("8%03x",$lables{$1});
	}elsif(/jmpz[ \t]+([a-z0-9A-Z_]+)/){
	    &validatelabel($1);
	    $op = sprintf("8%03x",$lables{$1}+0x200);
	}elsif(/jmpc[ \t]+([a-z0-9A-Z_]+)/){
	    &validatelabel($1);
	    $op = sprintf("8%03x",$lables{$1}+0x400);
	}elsif(/jsr[ \t]+([a-z0-9A-Z_]+)/){
	    &validatelabel($1);
	    $op = sprintf("8%03x",$lables{$1}+0x600);
	}elsif(/rts/){
	    $op = sprintf("8800");
	}elsif(/out0[ \t]+r([0-9]+)/){
	    &validatereg($1);
	    $op = sprintf("90%x0",$1);
	}elsif(/out1[ \t]+r([0-9]+)/){
	    &validatereg($1);
	    $op = sprintf("91%x0",$1);
	}elsif(/dw[ \t]+0x([a-fA-F0-9]+)/){
	    $op = sprintf("%04x",hex($1));
	}elsif(/nop/) {
	    $op = "ffff";
	}elsif(/brk/) {
	    $op = "fffe";
	}else{
	    print STDERR "*** Error on line $line\n";
	    exit 1;
	}
    }

    if($address != $newaddress) {
	$program[$address] = sprintf("        10'h%03x: pm_insn_o <= 16'h%s; // %s\n",$address,$op,$orig);
    }

# Uncomment these lines if you want a 
# verbose listing of the program

#    if($address != $newaddress) {
#	print sprintf("0x%03x:",$address);
#    }else{
#	print "      ";
#    }
#    print "$op $orig \n";


    $address = $newaddress;
	

}
close FILE;



# Print program as verilog code
printf("// This Verilog file automatically generated from $ARGV[0]\n");
printf("//\n");
#($Second, $Minute, $Hour, $Day, $Month, $Year, $WeekDay, $DayOfYear, $IsDST) = localtime(time);
#printf("// Generated on %04d-%02d-%02d\n", $Year+1900, $Month+1, $Day);

printf("module serial_wb_program(clk_i, pm_addr_i, pm_insn_o);\n");
printf("   input         clk_i;\n");
printf("   input  [9:0]  pm_addr_i;\n");
printf("   output [15:0] pm_insn_o;\n");
printf("\n");
printf("   wire          clk_i;\n");
printf("   wire [9:0]    pm_addr_i;\n");
printf("   reg  [15:0]   pm_insn_o;\n");
printf("\n");
printf("\n");
printf("\n");
printf("   always @(posedge clk_i)\n");
printf("       case(pm_addr_i)\n");

for($i = 0;$i < 1024; $i++) {
    print $program[$i];
}

printf("        default: pm_insn_o <= 16'h0000;\n");
printf("      endcase // case(pm_addr_i)\n");
printf("\n");
printf("endmodule // serial_wb_program\n");

sub validatereg {
    if(($_[0] > 15) || ($_[0] < 0)) {
	print STDERR "Invalid reg on line $line\n";
	exit 1;
    }
}

sub validateimm {
    if(($_[0] > 255) || ($_[0] < 0)) {
	print STDERR "Invalid immediate on line $line\n";
	exit 1;
    }
}

sub validatelabel {
    if (!exists($lables{$_[0]}) ){
	print STDERR "Invalid label '$_[0]' on line $line\n";
	exit 1;
    }
}
