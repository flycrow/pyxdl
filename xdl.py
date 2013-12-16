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


#FIXME - error handling, raising errors, etc is not consistent
import re
import string
import xdlhelper


class xdlError:
    def __init__(self,str):
        self.errorstr = str

    def __repr__(self):
        return str

    def __str__(self):
        return str

class xdlInternalError(xdlError): 
    def __init__(self): pass
    def __repr__(self): pass
    def __str__(self): pass

class badNetlist(xdlError): pass

class badName(xdlError): pass

class badStructure(xdlError): pass



class xdlinst:


    genericinstpattern = re.compile(r'\s*,placed\s+([^\s]+)\s+([^\s]+)\s*,\s*cfg\s+"([^"]+)"\s*;\s*$')
    genericunplacedpattern = re.compile(r'\s*,unplaced\s*,\s*cfg\s+"([^"]+)"\s*;\s*$')

    cfgentry_with_name_pattern = re.compile(r'([^:]+):([^:]+):(.*)')

    def cfgentry(self,str):
        pat = re.compile(r'.*\s'+str+':([^:]*):([^\s]*).*')
        e = pat.match(self.cfg)
        if not e:
            return False

        
        return (e.group(1),e.group(2) )


    def setcfgentry(self,entryname,newcontents):
        pat = re.compile(r'(.*)\s'+entryname+':([^:]*):([^\s]*)(.*)')
        x = pat.match(self.cfg)
        if x is None:
            self.cfg = self.cfg + ' '+entryname+':'+newcontents[0]+':'+newcontents[1]
        else:
            self.cfg = pat.sub(r'\1 '+entryname+':'+newcontents[0]+':'+newcontents[1]+r' \4',self.cfg)
            
    def __init__(self,name,str):
        foo = self.genericinstpattern.match(str)

        self.name = name
        self.outpins = {}
        self.inpins = {}
        if foo is not None:
            self.pos1 = foo.group(1)
            self.pos2 = foo.group(2)
            self.cfg = foo.group(3)
        else:
            foo = self.genericunplacedpattern.match(str)
            if foo is None:
                raise badNetlist("Cannot parse instance")

            self.pos1 = False
            self.pos2 = False
            self.cfg = foo.group(1)


    def unplace(self):
        self.pos1 = False
        self.pos2 = False

    def unlink(self):
        self.outpins = {}
        self.inpins = {}

        
    def instheader(self):
        return 'inst "'+self.name+'"'

    def display(self,disp):
        if self.pos1 is not False:
            print >> disp, self.instheader()+' "'+self.thetype+'",placed '+self.pos1+' '+self.pos2+' , \n cfg "'+self.cfg+'"\n;\n'
        else:
            print >> disp, self.instheader()+' "'+self.thetype+'",unplaced '+' , \n cfg "'+self.cfg+'"\n;\n'





    def add_net_to(self,port,net):
        self.inpins[port] = net

    def add_net_from(self,port,net):
        self.outpins[port] = net


    def port_to_net(self,port):
        if self.inpins.has_key(port):
            return self.inpins[port]
        elif self.outpins.has_key(port):
            return self.outpins[port]
        else:
            return None

    def remove_net(self,port):
        if self.inpins.has_key(port):
            del self.inpins[port]
        elif self.outpins.has_key(port):
            del self.outpins[port]
        else:
            raise badName("No such port")

    # Does not update the links in outpins/inpins!
    def add_prefix(self,prefix):
        self.name = prefix+self.name
        self.rename_instprop("XDL_SHAPE_DESC",prefix)
        self.rename_instprop("XDL_SHAPE_MEMBER",prefix)

        # FIXME - change this to honor cfgentries with spaces in...
        cfgentries = self.cfg.split(' ')
        for i in range(len(cfgentries)):
            cfgentry = cfgentries[i]
            tmp = self.cfgentry_with_name_pattern.match(cfgentry)
            if tmp is None:
                continue

            cfgentries[i] = tmp.group(1)+':'+prefix+tmp.group(2)+':'+tmp.group(3)
#            print "Replacing cfg entry",cfgentry,"with",cfgentries[i]

        self.cfg = string.join(cfgentries)
            

    def rename_instprop(self,str,prefix):
        instproppattern = re.compile(r'(.*\s_INST_PROP::'+str+':)([^:]+):(.*)')
        foo = instproppattern.match(self.cfg)
        if foo is not None:
#            print "Replacing",foo.group(2),"with",prefix+foo.group(2)
            newcfg = instproppattern.sub(r'\1'+prefix+r'\2:\3',self.cfg,)
            self.cfg = newcfg


    def clocknet(self):
        if self.inpins.has_key("CLK"):
            return self.inpins["CLK"]
        return None


class device:
    def __init__(self,str):
        self.name = str
# FIXME - correct these maxvalues for other devices than Virtex4-SX35...
        self.maxslicex = 79
        self.maxslicey = 191

# Number of DCMs in the device
        self.numdcm    = 8


class xdlnet:
    xdlnetnamepattern = re.compile(r'^\s*net\s+"([^"]+)"\s*(power|vcc|vdd|ground|gnd)?$')
    
    xdlnetinpinpattern = re.compile(r'^\s*inpin\s+"([^"]+)"\s+([A-Z0-9]+)\s*$')
    xdlnetoutpinpattern = re.compile(r'^\s*outpin\s+"([^"]+)"\s+([A-Z0-9]+)\s*$')
    xdlnetpippattern    = re.compile(r'^\s*pip\s+([^\s]+)\s+([^\s]+)\s+([^\s]+)\s+([^\s]+)\s*$')
    xdlnettrailer       = re.compile(r'^\s*;\s*$')
    xdlcfgpattern       = re.compile(r'\s*cfg\s+"([^"]*)"\s*$')

    def __init__(self,str):
        # FIXME - should these be dictionaries instead?
        self.inpins = []
        self.outpins = []
        self.pips = []
        self.cfg = None


        netparts = str.split(',')

        # First, find the name of this net
        netpart = netparts.pop(0)
        name = self.xdlnetnamepattern.match(netpart)
        
        if(name):
            self.name = name.group(1)
            if name.group(2):
                self.nettype = name.group(2)
            else:
                self.nettype = ""
        else:
            print "Could not parse net, expected name, got ",netpart


        # The trailing ;
        netpart = netparts.pop()
        if(not self.xdlnettrailer.match(netpart)):
            print "Expected ;, got",netpart

        netpart = ""
        instring = 0
        for part in netparts:
            if instring:
                netpart = netpart + ','+part
            else:
                netpart = part
            
            instring = instring ^ (part.count('"') % 2)

            if instring:
                continue
            

            
            inpin = self.xdlnetinpinpattern.match(netpart)
            if(inpin):
                self.add_inpin(inpin.group(1),inpin.group(2))
                continue
            
            
            pip = self.xdlnetpippattern.match(netpart)
            if(pip):
                self.pips.append((pip.group(1),pip.group(2),pip.group(3),pip.group(4)))
                continue

            outpin = self.xdlnetoutpinpattern.match(netpart)
            if(outpin):
                self.add_outpin(outpin.group(1),outpin.group(2))
                continue
            

            cfg = self.xdlcfgpattern.match(netpart)
            if cfg:
                self.cfg = cfg.group(1)
                continue

            # FIXME - raise error here
            print "Could not parse net string", netpart
            print "  Entire string is: ",str

    def add_inpin(self,instname,port):
        self.inpins.append((instname,port))

    # FIXME - add check for TBUFs here on architectures which have such devices
    def add_outpin(self,instname,port):
        if len(self.outpins) != 0:
            raise badLink("More than one outpin on a net is not allowed")
        self.outpins.append((instname,port))

    # Quickly unroute the net (remove all pips from the net)
    # This is used in many places since we do not know how to unroute just
    # a part of the net which we would need to do if we for example want to
    # remove a destination from a net.
    def unroute(self):
        self.pips = []

    def isp2p(self):
        if (len(self.inpins) == 1) and (len(self.outpins) == 1):
            return True
        return False

    def isempty(self):
        if (len(self.inpins) == 0) and (len(self.outpins) == 0):
            return True
        return False

    def display(self,disp):
        print >> disp, 'net "'+self.name+'" '+self.nettype+' ,'
        for pin in self.outpins:
            print >> disp,  '  outpin "'+pin[0]+'" '+pin[1]+" ,"

        for pin in self.inpins:
            print >> disp,  '  inpin "'+pin[0]+'" '+pin[1]+" ,"

        for pip in self.pips:
            print >> disp,  '  pip',pip[0],pip[1],pip[2],pip[3],","

        if self.cfg:
            print >> disp, 'cfg "'+self.cfg,'" ,'



        print >> disp, '  ;'


    def remove_inpin(self,instname,instport):
        # Need to unroute the net since we don't have a router/unrouter capable
        # of just unrouting the net to instname
        self.unroute()
        self.inpins.remove((instname,instport))

    def remove_outpin(self,instname,instport):
        # Need to unroute the net since we don't have a router/unrouter capable
        # of just unrouting the net to instname
        self.unroute()
        self.outpins.remove((instname,instport))


    def add_prefix(self,prefix):
        self.name = prefix + self.name
        for pin in range(len(self.inpins)):
            tmp = self.inpins[pin]
            self.inpins[pin] = (prefix+tmp[0],tmp[1])
        for pin in range(len(self.outpins)):
            tmp = self.outpins[pin]
            self.outpins[pin] = (prefix+tmp[0],tmp[1])

        if self.cfg is not None:
            belsigpattern = re.compile(r'(.*\s_BELSIG:PAD,PAD,)([^,]+):(.*)')
            if belsigpattern.match(self.cfg):
                self.cfg = belsigpattern.sub(r'\1'+prefix+r'\2:'+prefix+r'\3',self.cfg)
                                       
            
            
        # FIXME - check for cfg entry as well and modify the _BELSIG there...




class xdlslice(xdlinst):
    slicecoordpattern = re.compile(r'SLICE_X(\d+)Y(\d+)')
    thetype = "SLICE (not to be used)"

    def getslicecoord(self):
        foo = self.slicecoordpattern.match(self.pos2)
        slicex = int(foo.group(1))
        slicey = int(foo.group(2))
        return (slicex,slicey)

    

class slicel(xdlslice):
    thetype = "SLICEL"

class slicem(xdlslice):
    thetype = "SLICEM"

class xdldsp48(xdlinst):
    thetype = "DSP48"
        
class ramb16(xdlinst):
    thetype = "RAMB16"

    # FIXME - change this so you can say the kind of configuration you want the
    # data in. Right now you only get 36 bit wide data and 512 entries.
    def get_memory_array(self):
        mem = []
        memtmp = []
        paritytmp = []
        for i in range(0,64):
            tmp = self.cfgentry(string.upper("INIT_%02x" % i))
            if tmp is False:
                raise xdlBadnetlist("Didn't find expected init entry in blockram")
            memtmp.append(long(tmp[1],16))

        for i in range(0,8):
            tmp = self.cfgentry(string.upper("INITP_%02x" % i))
            if tmp is False:
                raise xdlBadnetlist("Didn't find expected init entry in blockram")
            paritytmp.append(long(tmp[1],16))

        for i in range(0,512):
            parityindex = i / 64
            memindex    = i / 8
            paritybits = (paritytmp[parityindex] >> (i % 64)*4) & 0xf
            membits    = (memtmp[memindex] >> ((i % 8)*32) ) & 0xffffffff
            mem.append((paritybits << 32) | membits)

        return mem

    def set_memory_array(self,mem):
        for i in range(0,8):
            paritybits = []
            for j in range(0,64):
                paritybits.insert(0,string.upper("%x" % ((mem[i*64+j] >> 32) & 0xf)))
            initp = string.join(paritybits,'')
            self.setcfgentry(string.upper("INITP_%02x" % i),("",initp))

            

        for i in range(0,64):
            membits = []
            for j in range(0,8):
                membits.insert(0,string.upper("%08x" % ((mem[i*8+j]) & 0xffffffff)))
            init = string.join(membits,'')
            self.setcfgentry(string.upper("INIT_%02x" % i),("",init))


        


class iob(xdlinst):
    thetype = "IOB"

    def isinput(self):
        if (self.inpins == 1) and (self.outpins == 0):
            if self.inpins.has_key("I"):
                return True
        return False

    def isoutput(self):
        if (self.inpins == 0) and (self.outpins == 1):
            if self.outpins.has_key("O"):
                return True
        return False

        

                
        


class xdltieoff(xdlinst):
    thetype = "TIEOFF"

class xdldcmadv(xdlinst):
    thetype = "DCM_ADV"

class xdlilogic(xdlinst):
    thetype = "ILOGIC"

    def oneff(self):
        patterns = [ re.compile(r'.*\sQ1MUX:[^:]*:IFF1\s.*'),
                     re.compile(r'.*\sIFFMUX:[^:]*:1\s.*'),
                     re.compile(r'.*\sIFFDELMUX:[^:]*:0\s.*'),
                     re.compile(r'.*\sIDELAYMUX:[^:]*:1\s.*'),
                     re.compile(r'.*\sCE1INV:[^:]*:#OFF\s.*'),
                     re.compile(r'.*\sCLKINV:[^:]*:CLK\s.*'),
                     re.compile(r'.*\sIFF1:[^:]*:#FF\s.*')]

        for p in patterns:
            if not p.match(self.cfg):
                return False

        return True

    def toslice(self):
        if(self.oneff()):
            ffentry = self.cfgentry("IFF1")
            
            return slicel(self.name,',unplaced,cfg "BXINV::BX CEINV::CE CLKINV::CLK DXMUX::BX FFX:'+ffentry[0]+':#FF FFX_INIT_ATTR::INIT0" ;' )
        return False


            

        
    
class xdlologic(xdlinst):
    thetype = "OLOGIC"

class xdlbufg(xdlinst):
    thetype = "BUFG"

class xdlpmv(xdlinst):
    thetype = "PMV"

class xdliserdes(xdlinst):
    thetype = "ISERDES"

class xdloserdes(xdlinst):
    thetype = "OSERDES"























class xdl:
    # Assumes there is nothing important after a ";"
    # Assumes a ; does not appear except at the end of a statement
    # such as for example inside ""
    # Assumes a # at the beginning of the line is always a comment
    # even if it would be inside a "string"

    instpattern   = re.compile(r'^\s*inst\s+"([^"]+)"\s+"([^"]+)"(.*)$')

    slicelpattern = re.compile(r'^\s*,placed\s+CLB_X(\d+)Y(\d+)\s+SLICE_X(\d+)Y(\d+)\s*,\s*cfg\s+"([^"]*)"\s*;')
    slicempattern = re.compile(r'^\s*,placed\s+CLB_X(\d+)Y(\d+)\s+SLICE_X(\d+)Y(\d+)\s*,\s*cfg\s+"([^"]*)"\s*;')
    iobpattern    = re.compile(r'^\s*,placed\sIOIS_([^\s]+)_X(\d+)Y(\d+)\s([^\s]+)\s+,\s*cfg\s+"([^"]*)"\s*;')
    rampattern    = re.compile(r'^\s*,placed\s+BRAM_X(\d+)Y(\d+)\s+RAMB16_X(\d+)Y(\d+)\s*,\s*cfg\s+"([^"]*)"\s*;')
    tieoffpattern = re.compile(r'^\s*,placed\s+INT_X(\d+)Y(\d+)\s+TIEOFF_X(\d+)Y(\d+)\s*,\s*cfg\s+"([^"]*)"\s*;')

    genericinstpattern = re.compile(r'\s*,placed\s+([^\s]+)\s+([^\s]+)\s*,\s*cfg\s+"([^"]+)"\s*;\s*$')


    designpattern = re.compile(r'^\s*design\s+"([^"]+)"\s+([^\s]+)\s+([^\s]+)\s+,\s+cfg\s+"([^"]*)"\s*;')

    netpattern = re.compile(r'\s*net\s+"([^"]+)"\s+(.*);\s*$')



    def __init__ (self,filename):
        self.designname = "***UNKNOWN***"
        self.designdevice = "***UNKNOWN***"
        self.designncdversion = "***UNKNOWN"
        self.designcfg = ""
    

        self.netsbyname = {}
        self.insts = {}

        self.readfile(filename)
        self.link()







    def parseslicel(self,name,str):
        s = slicel(name,str)
        self.insts[name] = s

    def parseslicem(self,name,str):
        s = slicem(name,str)
        self.insts[name] = s
        
    def parseiob(self,name,str):
        io = iob(name,str)
        self.insts[name] = io
        

    def parseramb(self,name,str):
        ram = ramb16(name,str)
        self.insts[name] = ram

    def parsetieoff(self,name,str):
        t = xdltieoff(name,str)
        self.insts[name] = t

    def parsedcmadv(self,name,str):
        d = xdldcmadv(name,str)
        self.insts[name] = d
        

    def parseilogic(self,name,str):
        i = xdlilogic(name,str)
        self.insts[name] = i

    def parseologic(self,name,str):
        o = xdlologic(name,str)
        self.insts[name] = o

    def parseinst(self,name,type,remaining):
        if type == "SLICEL":
            self.parseslicel(name,remaining)
        elif type == "SLICEM":
            self.parseslicem(name,remaining)
        elif type == "IOB":
            self.parseiob(name,remaining)
        elif type == "RAMB16":
            self.parseramb(name,remaining)
        elif type == "TIEOFF":
            self.parsetieoff(name,remaining)
        elif type == "DCM_ADV":
            self.parsedcmadv(name,remaining)
        elif type == "ILOGIC":
            self.parseilogic(name,remaining)
        elif type == "OLOGIC":
            self.parseologic(name,remaining)
        elif type == "BUFG":
            bufg = xdlbufg(name,remaining)
            self.insts[name] = bufg
        elif type == "PMV":
            pmv = xdlpmv(name,remaining)
            self.insts[name] = pmv
        elif type == "ISERDES":
            iserdes = xdliserdes(name,remaining)
            self.insts[name] = iserdes
        elif type == "OSERDES":
            oserdes = xdloserdes(name,remaining)
            self.insts[name] = oserdes
        elif type == "DSP48":
            dsp48 = xdldsp48(name,remaining)
            self.insts[name] = dsp48
        else:
            print "Unknown inst "+name+" (type is "+type+")"

    

    def parsenet(self,str):
        thenet = xdlnet(str)
        self.netsbyname[thenet.name] = thenet
        
        
    def readfile(self,filename):
        semicolon = re.compile('.*;$')
        lines = []
        instring = 0;
        lineno = 0

        for line in xdlhelper.filereader(filename):

            inst = self.instpattern.match(line)
            if inst:
                self.parseinst(inst.group(1),inst.group(2),inst.group(3))
            elif(self.netpattern.match(line)):
                self.parsenet(line)
            elif self.designpattern.match(line):
                design = self.designpattern.match(line)
                self.designname = design.group(1)
                self.designdevice = design.group(2)
                self.designncdversion = design.group(3)
                self.designcfg = design.group(4)
#                print "Design details"
#                print "  Name:", self.designname
#                print "  Device:", self.designdevice
#                print "  NCD version:", self.designncdversion

                self.dev = device(self.designdevice)
                
            else:
                raise badNetlist("Unknown line in XDL file")



    
                
                        
    def savedesign(self,filename):
        f = open(filename,"w")
        
        print >>f,'design "'+self.designname+'" '+self.designdevice+' '+self.designncdversion+' ,\n  cfg "'+self.designcfg+'";\n\n'

        for inst in self.insts:
            self.insts[inst].display(f)

        for net in self.netsbyname:
            self.netsbyname[net].display(f)

        f.close()

    def unlink(self):
        for inst in self.insts:
            i = self.insts[inst]
            i.unlink()


    def link(self):
        self.unlink()
        for net in self.netsbyname:
            thenet = self.netsbyname[net]
            for inpin in thenet.inpins:
                instance = inpin[0]
                pinname = inpin[1]
                inst = self.insts[instance]
                inst.add_net_to(pinname,thenet)

            for outpin in thenet.outpins:
                instance = outpin[0]
                pinname = outpin[1]
                inst = self.insts[instance]
                inst.add_net_from(pinname,thenet)

        
                

    def del_inpin(self,instname,instport):
        theinst = self.insts[instname]
        thenet = theinst.port_to_net(instport)
        thenet.remove_inpin(net,instname,instport)
        theinst.remove_net(instport)

    def del_outpin(self,instname,instport):
        theinst = self.insts[instname]
        thenet = theinst.port_to_net(instport)
        thenet.remove_outpin(net,instname,instport)
        theinst.remove_net(instport)



    # We probably don't need to unroute the net when we
    # add a destination to it...
    def add_inpin_to_net(self,net,instname,instport):
        net.add_inpin(instname,instport)
        theinst = self.insts[instname]
        theinst.add_net_to(instport,net)
        
    def add_outpin_to_net(self,net,instname,instport):
        net.add_outpin(instname,instport)
        theinst = self.insts[instname]
        theinst.add_net_from(instport,net)

    
    def remove_inst(self,instname):
#        print "Removing instance:",instname
        theinst = self.insts[instname]
        for portname in theinst.inpins:
            net = theinst.inpins[portname]
            net.remove_inpin(instname,portname)
            if net.isempty():
                del self.netsbyname[net.name]

        for portname in theinst.outpins:
            net = theinst.outpins[portname]
            net.remove_outpin(instname,portname)
            if net.isempty():
                del self.netsbyname[net.name]

        del self.insts[instname]


    def remove_net(self,netname):
        net = self.netsbyname[netname]
        for port in net.inpins:
            inst = self.insts[port[0]]
            inst.remove_net(port[1])
        for port in net.outpins:
            inst = self.insts[port[0]]
            inst.remove_net(port[1])

        del self.netsbyname[netname]


    def unplace_design(self):
        for inst in self.insts:
            i = self.insts[inst]
            i.unplace()

        for net in self.netsbyname:
            n = self.netsbyname[net]
            n.unroute()


    def convert_input_to_internal(self,io):
        ilnet = io.outpins["I"]
        if not ilnet.isp2p():
            raise badNetlist("Net from IOB is not point to point")

        il = self.insts[ilnet.inpins[0][0]]

        s = il.toslice()
        if s is False:
            raise badStructure("ILOGIC structure type not supported");
            
        clknet = il.clocknet()
        d = il.port_to_net("D")
        q = il.port_to_net("Q1")

        self.remove_inst(il.name)
        self.remove_inst(io.name)

        self.insts[s.name] = s
        self.add_outpin_to_net(q,s.name,"XQ")
        self.add_inpin_to_net(clknet,s.name,"CLK")

#        if not self.netsbyname.has_key(io.name):
#            raise badNetlist("Expected a net with the same name as an IOB")

        # Find the net with the _BELSIG,PAD,PAD cfg data.
        net = self.netsbyname[io.name]

        if not net.isempty():
            raise badNetlist("Expected IOB pad net to have no in and outpins")

        self.remove_net(io.name)

        # Returns the name of the port the input signal should be connected to
        return (s.name,"BX")



    

        
        
    def remove_unused_dcminsts(self):
        for i in range(1,self.dev.numdcm+1):
            dcmname = "XIL_ML_UNUSED_DCM_%d" % i
            if self.insts.has_key(dcmname):
                self.remove_inst(dcmname)

        if self.insts.has_key("XIL_ML_PMV"):
            self.remove_inst("XIL_ML_PMV")


    def add_prefix(self,prefix):
        self.unlink() # Just to be safe...
        instlist = []
        for inst in self.insts:
            instlist.append(self.insts[inst])

        self.insts = {}
        for i in instlist:
            i.add_prefix(prefix)
            self.insts[i.name] = i

        netlist = []
        for net in self.netsbyname:
            netlist.append(self.netsbyname[net])

        self.netsbyname = {}
        for i in netlist:
            i.add_prefix(prefix)
            self.netsbyname[i.name] = i
        self.link()
        
            
                
                              
    def mergedesign(self,otherdesign):
        # FIXME - check for design compatibility using self.dev!
        self.unlink()
        otherdesign.unlink()
        for inst in otherdesign.insts:
            if self.insts.has_key(inst):
                raise badNetlist("Instance already exists")
        for net in otherdesign.netsbyname:
            if self.netsbyname.has_key(net):
                raise badNetlist("Net already exists")
                
            
        for inst in otherdesign.insts:
            self.insts[inst] = otherdesign.insts[inst]

        for net in otherdesign.netsbyname:
            self.netsbyname[net] = otherdesign.netsbyname[net]
        self.link()



    def add_inst(self,inst):
        self.insts[inst.name] = inst


    def add_net(self,net):
        self.netsbyname[net.name] = net


    # FIXME - does not care about block rams due to 
    # the two clocks on a block ram!
    def clocknets(self):
        clocknets = {}
        for iname in self.insts:
            i = self.insts[iname]
            net = i.clocknet()
            if net is not None:
                if not clocknets.has_key(net.name):
                    clocknets[net.name] = 0
                clocknets[net.name] = clocknets[net.name] + 1

        retval = []
        for n in clocknets:
            retval.append([n,clocknets[n]])
        return retval

