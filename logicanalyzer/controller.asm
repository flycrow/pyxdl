	org	0

restart:
	set	#0x0,r15
		
	nop
	nop
	set	#0x0,r0
	set	#0x0,r1

	set	#0xff,r0
	set	#0xff,r1

;;; Wait a little while before starting the main program
delayloop:
	add	r0,r1,r0
	jmpc	delayloop
	nop

	set	#0x40,r0
	jsr	putc

;;; Print greeting
	set	LOW greetingstring,r3	; Pointer to greeting string
	set	HIGH greetingstring,r4
	
greetloop:
	jsr	puts


;;; ----------------------------------------------------------------------
;;; Main loop
;;; ----------------------------------------------------------------------
menuloop:
	set	#0x0d,r0	
	jsr	putc
	set	#0x0a,r0
	jsr	putc
	
	set	#0x3e,r0	; '>'
	jsr	putc		; print prompt

	jsr	getc		; get command character

	set	#0x44,r1	; 'D'
	xor	r0,r1,r1
	jmpz	handle_logicanalyzer
	nop

	set	#0x54,r1	;  'T' set trigger
	xor	r0,r1,r1
	jmpz	handle_settrigger
	nop

	set	#0x74,r1	;  't' trigger it
	xor	r0,r1,r1
	jmpz	handle_trigger
	nop

illegal_command:	
	set	#0x7,r0		; ctrl g
	jsr	putc
	jmp	menuloop




	

;; get32bitval:
;; 	jsr	getnibble
;; 	swap	r3,r7
;; 	jsr	getnibble
;; 	or	r3,r7,r7

;; 	jsr	getnibble
;; 	swap	r3,r6
;; 	jsr	getnibble
;; 	or	r3,r6,r6

;; 	jsr	getnibble
;; 	swap	r3,r5
;; 	jsr	getnibble
;; 	or	r3,r5,r5

;; 	jsr	getnibble
;; 	swap	r3,r4
;; 	jsr	getnibble
;; 	or	r3,r4,r4
;; 	rts
		


	
;;; ----------------------------------------------------------------------
;;; Subroutine to print one character
;;; Character to print in r0
;;; Uses r1,r2
;;; ----------------------------------------------------------------------
putc:
	set	#0x1,r1
	out0	r1
	set	#0x2,r2		; UART_TX_IDLE
	nop
	

putc_waitidle:	
	in2	r1		; get status flags from UART
	and	r1,r2,r1	; zero flag set if no TX slot available
	jmpz	putc_waitidle
	nop

	set	#0x0,r1		; Output register of UART
	out0	r1		; Address for TX transmit reg
	out1	r0		; Transmit character
	rts

;;; ----------------------------------------------------------------------
;;; Subroutine to get one character
;;; Returns character in r0
;;; Uses r1,r2
;;; ----------------------------------------------------------------------
getc:
	set	#0x1,r1
	out0	r1
	set	#0x1,r2		; UART_RX_IDLE
	nop

getc_waitchar:	
	in2	r1
	and	r1,r2,r1
	jmpz	getc_waitchar
	nop
	
	set	#0x0,r1		; Address of RX recv reg
	out0	r1
	nop
	nop
	in2	r0		; Get character

;;; Check for ctrl c
	set	#0x3,r1		; ctrl c
	xor	r0,r1,r1
	jmpz	restart		; Restart if ctrl c was pressed
	nop
	
	jmp	putc		; Echo character

;;; ----------------------------------------------------------------------
;;; Subroutine to get one character (without echo)
;;; Returns character in r0
;;; Uses r1,r2
;;; ----------------------------------------------------------------------
getc_quiet:
	set	#0x1,r1
	out0	r1
	set	#0x1,r2		; UART_RX_IDLE
	nop

getc_quiet_waitchar:
	in2	r1
	and	r1,r2,r1
	jmpz	getc_quiet_waitchar
	nop
	
	set	#0x0,r1		; Address of RX recv reg
	out0	r1
	nop
	nop
	in2	r0		; Get character

;;; Check for ctrl c
	set	#0x3,r1		; ctrl c
	xor	r0,r1,r1
	jmpz	restart		; Restart if ctrl c was pressed
	nop
	
	rts


;;; ----------------------------------------------------------------------
;;; Send a 4 byte value to the IO port r0, r0+1, r0+2, r0+3
;;; value to send is in r7..r4
;;; IO port address is in r0
;;; Uses r1
;;; ----------------------------------------------------------------------
setport:
	set	#0x1,r1		; inc factor
	out0	r0
	out1	r4
	
	add	r0,r1,r0
	out0	r0
	out1	r5

	add	r0,r1,r0
	out0	r0
	out1	r6

	add	r0,r1,r0
	out0	r0
	out1	r7
	rts
	

;;; ----------------------------------------------------------------------
;;; Get a 4 byte value from IO port r0, r0+1,r0+2,r0+3
;;; Value is returned in r7..r4
;;; IO port address in r0
;;; Uses r1
;;; ----------------------------------------------------------------------
getport:
	set	#0x01,r1	; increment constant

	out0	r0
	nop			; Get rid of nop!
	nop
	in2	r4

	add	r0,r1,r0
	out0	r0
	nop
	nop
	in2	r5
	
	add	r0,r1,r0
	out0	r0
	nop
	nop
	in2	r6

	add	r0,r1,r0
	out0	r0
	nop
	nop
	in2	r7

	rts



;;; ----------------------------------------------------------------------
;;; Get a nibble from Uart and convert it to binary
;;; Will print ctrl g to the uart for every illegal character entered
;;; (Only 0..9 and a..f are legal)
;;; BUGS: Does not handle A..F
;;; Uses (lots of regs)
;;; Result in r3
;;; ----------------------------------------------------------------------
;;; FIXME - redo getnibble to not use subroutines. And write
;;; Getvalue to get a 8 byte value into r4..r7
getnibble:
	jsr	getc_quiet

convascii_to_nibble:
	set	#0xd0,r1	; 0x100 - 0x30
	add	r0,r1,r1
	jmpc	convascii_ge0	; jump if greater or equal to '0'
	nop

	set	#0x7,r0		; ctrl g
	jsr	putc
	jmp	getnibble	; restart nibbleloop
	
;;; ascii in r0 is larger than or equal to '0'
convascii_ge0:	
	set	#0xc6,r1	; 0x100 - 0x39
	add	r0,r1,r1
	jmpc	convascii_gt9
	nop

;;; Value between '0' and '9'
	set	#0xd0,r1		; -0x30
	add	r0,r1,r3	; result in r3
	jmp	putc		; jump to putc to end it all

convascii_gt9:
	set	#0x9f,r1	; 0x100 - 0x61 ('a')
	add	r0,r1,r1
	jmpc	convascii_gea	; Value is larger than or equal to 'a'
	nop

	set	#0x7,r0		; ctrl g
	jsr	putc
	jmp	getnibble	; restart nibbleloop

convascii_gea:	
	set	#0x99,r1; 0x100 - 0x66 - 1 (0x66 = 'f')
	add	r0,r1,r1
	jmpc	invalidchar
	nop

	set	#0xa9,r1	; -0x61+0xa
	add	r0,r1,r3	; result in r3
	jmp	putc

invalidchar:
 	set	#0x7,r0
 	jsr	putc
	jmp	getnibble

	

	
	
	





;;; ----------------------------------------------------------------------
;;; Subroutine to convert 8 bit value in r0 to two ascii
;;; characters in r0 and r3 (uses r1,r2)
;;; ----------------------------------------------------------------------
convnibble:
	set	#0xf,r2 	; Mask out LSB nibble
	and	r0,r2,r2

	set	#0xf6,r3
	add	r2,r3,r3
	jmpc	convnibble_lsb_gtten ; Jump if r2 greater than 9
	nop

	set	#0x30,r3	; '0'
	add	r2,r3,r1	; convert first nibble into '0'..'9'
	jmp	convnibble_msb

convnibble_lsb_gtten:
	set	#0x57,r3	; 'a'
	add	r2,r3,r1

;;; LSB nibble done, result in r1. Now, convert MSB nibble
convnibble_msb:
	set	#0xf,r2		; mask out MSB nibble
	swap	r0,r0
	and	r0,r2,r2

	set	#0xf6,r3
	add	r2,r3,r3
	jmpc	convnibble_msb_gtten
	nop

	set	#0x30,r3	; '0'
	add	r2,r3,r0
	jmp	convnibble_msb_done

convnibble_msb_gtten:
	set	#0x57,r3	; 'a'
	add	r2,r3,r0

convnibble_msb_done:
	or	r1,r1,r3	; move r1 to r3 FIXME - remove the need for this?
	rts









logicanalyzer_nextrow:
	set	#0xd,r0
	jsr	putc
	set	#0xa,r0
	jsr	putc
	
	set	#0x1,r0
	add	r0,r12,r12
	add	r0,r11,r11
	jmpc	nextrow_carry
	nop

;;; Compensate for carry..
	set	#0xff,r0
	add	r0,r12,r12
nextrow_carry:
	set	#0x8,r5
	set	#0x0,r4
	xor	r5,r12,r5
	xor	r4,r11,r4
	or	r5,r4,r4
	jmpz	menuloop
	nop

nextrow_setup:
	set	LOW signalinfo,r13
	set	#0x0,r7
	set	#0x0,r6
	set	#0x0,r5
	set	#0x14,r4
	jsr	setwbaddr

	or	r12,r12,r5
	or	r11,r11,r4
	jsr	setwbdata
	jsr	write_to_wb

	jmp	handle_logicanalyzer_mainloop




handle_logicanalyzer:
	set	LOW signalnames,r3
	set	HIGH signalnames,r4
	jsr	puts

	set	#0x0,r11
	set	#0x0,r12	;  Entry to display...
	jmp	nextrow_setup
	
handle_logicanalyzer_mainloop:
	
	
	set	#0x9,r0		; tab
	jsr	putc

	set	HIGH signalinfo,r1
	ld	r1,r13,r14
	ld	r1,r13,r14
	
	set	#0x1,r0
	add	r0,r13,r13
	
	ld	r1,r13,r15
	ld	r1,r13,r15
	
	add	r0,r13,r13

	or	r14,r14,r14
	jmpz	logicanalyzer_nextrow	; Finished (well, not really...)
	nop
	
	

	set	#0x0,r9

logicloop:

	or	r15,r15,r8
	jsr	getbit_from_analyzer
	add	r9,r9,r9
	or	r8,r9,r9
	
	set	#0xff,r0
	add	r0,r15,r15
	add	r0,r14,r14
	set	#0x3,r0
	and	r0,r14,r0
	jmpz	logicloop_printnibble
	nop

logicloop_continue:	
	or	r14,r14,r14
	jmpz	handle_logicanalyzer_mainloop
	nop
	jmp	logicloop

logicloop_printnibble:
	or	r9,r9,r0
	jsr	convnibble
	or	r3,r3,r0
	jsr	putc
	set	#0x0,r9
	jmp	logicloop_continue

;;; Read from wishbone (clobbers r0)
wishbone_do_read:
	set	#0x18,r0
	out0	r0
	set	#0xf1,r5	; Read, sel is 0xf
	out1	r5
	;; Transaction will finish quickly in this design, no need to poll...
	rts
	

;;; Rotates r0 1 step to the left
;;; Clobbers r1
rol1:
	set	#0x1,r1
	add	r0,r0,r0
	jmpc	rol1_carry
	nop
	rts
rol1_carry:	
	add	r0,r1,r0
	rts

;;; r8 contains bitnumber to get
getbit_from_analyzer:
	
	set	#0xe0,r1
	and	r8,r1,r0	; r0 contains the address to read from logicanalyzer
	jsr	rol1
	jsr	rol1
	jsr	rol1		

	add	r0,r0,r0	; Multiply it with 2
	add	r0,r0,r0

	set	#0x40,r1
	add	r0,r1,r4	; Add the offset to logic analyzer port (0x40) to it
	
	set	#0x0,r5
	set	#0x0,r6
	set	#0x0,r7
	set	#0x10,r0	; Set wishbone address 
	jsr	setport		; r4-r7 -> port 0x10 => wb addr
	
	jsr	wishbone_do_read

	set	#0x18,r1	; Byte to read
	and	r8,r1,r0	
	jsr	rol1
	jsr	rol1
	jsr	rol1
	jsr	rol1
	jsr	rol1		; r0 now contains the byte to read from logicanalyzer


	set	#0x14,r1	; offset to WB master peripheral
	add	r0,r1,r1
	out0	r1

	set	#0x7,r1
	and	r8,r1,r0	; r0 contains the bitnumber we are interested in
	in2	r8		; r8 now contains the byte we are interested in
	set	#0xff,r3
	set	#0x1,r2		; mask

	;;; Create bitmask
getbit_loopstart:
	or	r0,r0,r0
	jmpz	getbit_loopend
	nop

	add	r0,r3,r0	; r0--
	add	r2,r2,r2	; r2 = r2 << 1
	jmp	getbit_loopstart

getbit_loopend:	
	
	and	r2,r8,r8	; r8 is now masked
	jmpz	getbit_iszero
	nop
	set	#0x1,r8
getbit_iszero:
	rts


write_to_wb:
;;; Write
	set	#0x18,r0
	set	#0xf9,r1
	out0	r0
	out1	r1
	rts

setwbaddr:
	set	#0x10,r0
	jmp	setport

setwbdata:
	set	#0x14,r0
	jmp	setport



handle_trigger:
	
	set	#0x0,r7
	set	#0x0,r6
	set	#0x0,r5
	set	#0x20,r4
	jsr	setwbaddr
	
	set	#0x0,r4
	jsr	setwbdata
	jsr	write_to_wb	;  Stop tracer machine

	;;; ARM the logicanalyzer
	set	#0x0,r7
	set	#0x0,r6
	set	#0x0,r5
	set	#0x0,r4
	jsr	setwbaddr
	set	#0x1,r4
	jsr	setwbdata
	jsr	write_to_wb

	;;; Wait for logic analyzer to match...
handle_trigger_wait:	
	jsr	wishbone_do_read
	set	#0x14,r0
	jsr	getport
	or	r4,r4,r4
	jmpz	handle_trigger_wait

	set	LOW triggermessage,r3
	set	HIGH triggermessage,r4
	jmp	greetloop

;;; Create a bitmask, r0 is the bit index
;;; Clobbers r3
;;; Returns bitmask in r2
createbitmask:
	set	#0x1,r2
	set	#0xff,r3
createbitmask_loop:	
	or	r0,r0,r0
	jmpz	createbitmask_end
	;; Nop not needed? FIXME - check for all unneeded nops!
	nop

	add	r0,r3,r0	; r0--
	add	r2,r2,r2	; r2 = r2 << 1
	jmp	createbitmask_loop

createbitmask_end:
	rts
	


	
;;; r8 contains bit index
;;; r9 contains 0 if we should clear bit, non-zero if we should set bit
;;; r11 contains the offset to the LSB of the WB addr (i.e. select
;;; if we want to write to match or mask bits of tracer)
;;; Clobbers (r7-r4, r0, r1, r10, r9)
setbit:
	set	#0x00,r7
	set	#0x00,r6
	set	#0x00,r5
	or	r11,r11,r4

	;; First, calculate word offset
	set	#0xe0,r1
	and	r8,r1,r0
	jsr	rol1
	jsr	rol1
	jsr	rol1
	add	r0,r0,r0
	add	r0,r0,r0
	add	r0,r4,r4	; r7-r4 now contains WB word for matchbit
	jsr	setwbaddr

	jsr	wishbone_do_read

	set	#0x18,r1	; Byte to read
	and	r8,r1,r0	
	jsr	rol1
	jsr	rol1
	jsr	rol1
	jsr	rol1
	jsr	rol1		; r0 now contains the byte to read from logicanalyzer
	
	set	#0x14,r1	; offset to WB master peripheral
	add	r0,r1,r10	; Save port offset in r10
	out0	r10
	in2	r4		; r4 contains the byte we want to mask

	set	#0x7,r1
	and	r8,r1,r0	; r0 contains the bitnumber we are interested in

	jsr	createbitmask
	;; Now r2 contains the bitmask

	set	#0xff,r3
	xor	r2,r3,r3	; r3 now contains inverted mask for anding
	and	r4,r3,r4	; r4 is now cleared
	or	r9,r9,r9	; set flags
	jmpz	setbit_writeback
	nop

	or	r4,r2,r4	; r9 now contains correct byte value

setbit_writeback:
	or	r4,r4,r9	; Save byte in r9
	set	#0x14,r0
	jsr	getport		; Read port data
	set	#0x14,r0
	jsr	setport		; Write it back

	out0	r10		; Update this particular byte
	out1	r9
	jmp	write_to_wb


handle_settrigger:
	set	LOW signalnames,r3
	set	HIGH signalnames,r4
	jsr	puts
	
	set	#0x0,r11
handle_settrigger_setvalormask:
	set	#0x0,r0
	xor	r11,r0,r0
	jmpz	handle_settrigger_setval

	set	#0xc,r0
	xor	r11,r0,r0
	jmpz	handle_settrigger_setmask
	jmp	menuloop	; Exit handle_settrigger

handle_settrigger_setmask:	
	
	set	#0x4,r11
	set	LOW maskvalstring,r3
	set	HIGH maskvalstring,r4
	jsr	puts
	
	jmp	handle_settrigger_main


handle_settrigger_setval:
	set	LOW trigvalstring,r3
	set	HIGH trigvalstring,r4
	jsr	puts
	set	#0xc,r11
	;;;  Fall through
	
handle_settrigger_main:	
	set	LOW signalinfo,r13 ;r13 contains pointer to current

handle_settrigger_nextentry:	
	set	#0x9,r0		; '\t'
	jsr	putc
	set	HIGH signalinfo,r1
	ld	r1,r13,r14	   
	ld	r1,r13,r14	   ;r14 contains length of current entry
	or	r14,r14,r14
	jmpz	handle_settrigger_setvalormask	; No more entry
	nop
	
	set	#0x1,r0
	add	r0,r13,r13
	ld	r1,r13,r15	
	ld	r1,r13,r15	; r15 contains bit offset of current entry
	add	r0,r13,r13	; r13 points to next entry


handle_settrigger_nextnibble:	
	or	r14,r14,r14
	jmpz	handle_settrigger_nextentry	; No more entry
	nop
	jsr	getnibble	; r3 contains input
	or	r3,r3,r12

	set	#0x3,r2
	and	r2,r14,r2	; r2 contains length & 3

	set	#0x0,r9
	xor	r9,r2,r9	; (length & 3) == 0 ?
	jmpz	handle_settrigger_use4

	set	#0x3,r9
	xor	r9,r2,r9	; (length & 3) == 3 ?
	jmpz	handle_settrigger_use3

	set	#0x2,r9
	xor	r9,r2,r9	; (length & 3) == 2 ?
	jmpz	handle_settrigger_use2

	set	#0x1,r9
	xor	r9,r2,r9	; (length & 3) == 1 ?
	jmpz	handle_settrigger_use1

handle_settrigger_use4:
	set	#0x8,r0
	and	r0,r12,r9
	or	r15,r15,r8
	jsr	setbit

	set	#0xff,r10	; r10 = -1
	add	r14,r10,r14
	add	r15,r10,r15

handle_settrigger_use3:
	set	#0x4,r0
	and	r0,r12,r9
	or	r15,r15,r8
	jsr	setbit

	set	#0xff,r10	; r10 = -1
	add	r14,r10,r14
	add	r15,r10,r15

handle_settrigger_use2:
	set	#0x2,r0
	and	r0,r12,r9
	or	r15,r15,r8
	jsr	setbit

	set	#0xff,r10	; r10 = -1
	add	r14,r10,r14
	add	r15,r10,r15

handle_settrigger_use1:
	set	#0x1,r0
	and	r0,r12,r9
	or	r15,r15,r8
	jsr	setbit

	set	#0xff,r10	; r10 = -1
	add	r14,r10,r14
	add	r15,r10,r15
	jmp	handle_settrigger_nextnibble
	

handle_settrigger_end:
	jmp	menuloop

	
	


puts:
	ld	r4,r3,r0
	ld	r4,r3,r0

	or	r0,r0,r0
	jmpz	end_puts
	nop

	jsr	putc

	set	#0x01,r0
	add	r0,r3,r3	;charptr++
	jmp	puts
end_puts:	
	rts
	
	

	
	org	0x280
greetingstring:	
	dw	0x0d0a		; \r\n
	dw	0x0d0a		; \r\n
	dw	0x2a2a		; **
	dw	0x2a20		; *
	dw	0x4145		; AE
	dw	0x2044		;  D
	dw	0x6562		; eb
	dw	0x7567		; ug
	dw	0x2049		;  I
	dw	0x4600		; F\0
trigvalstring:
	dw	0x0d0a		; \r\n
	dw	0x5472		;
	dw	0x6967
	dw	0x7661
	dw	0x6c3a
	dw	0x0d0a		; \r\n
	dw	0x0000

maskvalstring:
	dw	0x0d0a		; \r\n
	dw	0x4d61
	dw	0x736b
	dw	0x7661
	dw	0x6c3a
	dw	0x0d0a		; \r\n
	dw	0x0000

triggermessage:
	dw	0x5761
	dw	0x6974
	dw	0x696e
	dw	0x6720
	dw	0x666f
	dw	0x7220
	dw	0x7472
	dw	0x6967
	dw	0x6765
	dw	0x722e
	dw	0x2e2e
	dw	0x0d0a
	dw	0x0000


	org	0x200
signalinfo:
	dw	0x070e
	dw	0x0807
	dw	0x0000
	dw	0x0000

	org	0x300
signalnames:
	dw	0x0d0a
	dw	0x4145
	dw	0x0000
	
	org	0x3ff
controller_signature:	
	dw	0xab54		; Just a check intended for tools that automatically poke around inside this memory
