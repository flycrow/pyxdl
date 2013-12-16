# PyXDL - Analyze and manipulate XDL files
# Copyright (C) 2007 Andreas Ehliar <ehliar@isy.liu.se>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA
#
from xdl import xdl,xdlnet
from pcf import pcf

# FIXME clocknet should be a string, not an xdlnet!
def merge_logicanalyzer(design,designpcf,clocknet,timegrpname,netstoinspect,rxname,txname):

    logicanalyzer = xdl("logicanalyzer/system.xdl")
    logicanalyzerpcf = pcf("logicanalyzer/system.pcf")
    logicanalyzer.unplace_design()

    logicanalyzer.remove_unused_dcminsts()
    logicanalyzer.remove_inst("clk_i")
    logicanalyzer.remove_net("clk_i")

    logicanalyzer.add_prefix("LOGICANALYZER/")

    tracerpins = []
    for i in range(0,64):
        iname = "LOGICANALYZER/tracein<%d>" % i
        iob = logicanalyzer.insts[iname]
        pin = logicanalyzer.convert_input_to_internal(iob)
        tracerpins.append(pin)

    logic_clknet = logicanalyzer.netsbyname["LOGICANALYZER/clk_i_BUFGP"]
    logicanalyzer.remove_net("LOGICANALYZER/clk_i_BUFGP")
    logicanalyzer.remove_inst("LOGICANALYZER/clk_i_BUFGP/BUFG")

    # FIXME - make sure this is the correct memory name... (instantiate a RAMB16 in serial_wb_program.v)
    controller_program = logicanalyzer.insts["LOGICANALYZER/mcu/program_memory/Mrom_pm_insn_o_mux00001"]
    program = controller_program.get_memory_array()

    if (program[511] >> 16) & 0xffff != 0xab54:
        raise "Did not find expected signature in logicanalyzer microcontroller program memory"



    design.mergedesign(logicanalyzer)
    for pin in logic_clknet.inpins:
        logicanalyzer.add_inpin_to_net(clocknet,pin[0],pin[1])

    logicanalyzerpin = 0
    controllerindex = 0
    labels = "\r\n"
    for bus in netstoinspect:
        labels = labels + "\t"+bus[0]
#        print "Adding bus",bus[0],"which contains",len(bus[1]),"nets"
        endpin = logicanalyzerpin

        for net in bus[1]:
            if logicanalyzerpin > 63:
                raise "Too many pins in netstoinspect"

            net = design.netsbyname[net]
            pin = tracerpins[logicanalyzerpin]
            design.add_inpin_to_net(net,pin[0],pin[1])
            logicanalyzerpin += 1

        startpin = logicanalyzerpin - 1
        length = logicanalyzerpin - endpin
        configval = (length << 8) | startpin
        programaddr = 0x200 + controllerindex
        controllerindex +=1
        if (programaddr % 2) == 1:
            program[programaddr / 2] &= 0xffff
            program[programaddr / 2] |= configval << 16
        else:
            program[programaddr / 2] &= 0xffff0000

            program[programaddr / 2] |= configval
    
    labels=labels + "\r\n\0\0\0\0" # NUL terminate it

    for i in range(0,len(labels)-4,4):
        a = ord(labels[i+2])
        a = (a << 8) | ord(labels[i+3])
        a = (a << 8) | ord(labels[i+0])
        a = (a << 8) | ord(labels[i+1])
        program[i/4+0x300/2] = a

    

    # FIXME - maximum limit of 15 entries here...



    controller_program.set_memory_array(program)
    # print "Memory is",program

    vccnet = xdlnet('net "LOGICANALYZER/vccnet" vcc,;')
    design.add_net(vccnet)
    for i in range(logicanalyzerpin,64):
        pin = tracerpins[i]
        design.add_inpin_to_net(vccnet,pin[0],pin[1])



    timegrpbels = logicanalyzerpcf.timegrpbels(timegrpname)
    for i in range(len(timegrpbels)):
        timegrpbels[i] = (timegrpbels[i][0],"LOGICANALYZER/"+timegrpbels[i][1])

    designpcf.add_nets_to_timegrp("clk_i",timegrpbels)
    extrapins = logicanalyzerpcf.getall_pins()
    designpcf.add_pins(extrapins,"LOGICANALYZER/")

    designpcf.addiob("LOGICANALYZER/rx_i","AC1")
    designpcf.addiob("LOGICANALYZER/tx_o","AB1")


def createbus(busname,busstring,msb,lsb):
    bus = []
    for i in range(lsb,msb+1):
        bus.append(busstring % i)

    return [busname,bus]
