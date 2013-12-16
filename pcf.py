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

import xdlhelper
import xdl
import re
import string



class pcf:
    timegrppattern = re.compile(r'^TIMEGRP\s+([^\s]+)\s+(.*);$')
    
    def __init__(self,filename):
        self.pcflines = []


        for line in xdlhelper.filereader(filename):
            self.pcflines.append(line)


    def add_nets_to_timegrp(self,timegrp,netinfo):
        for lineno in range(len(self.pcflines)):
            line = self.pcflines[lineno]
            tmp = self.timegrppattern.match(line)
            if tmp is None:
                continue

            if tmp.group(1) != timegrp:
                continue

            
#            print "Found a match for the timegrp, cfg line is:",line

            bellist = []
            for name in netinfo:
                bellist.append(' '+name[0]+' "'+name[1]+'"')

            bellist = string.join(bellist)

            self.pcflines[lineno] = "TIMEGRP "+tmp.group(1)+' '+tmp.group(2)+bellist+';'
            return

        raise xdl.badName("Timegroup does not exist")
            


    def savepcf(self,filename):
        f = open(filename,"w")
        for line in self.pcflines:
            print >> f,line
        f.close()


    def addiob(self,compname,location):
        self.addcomp(compname,'LOCATE = SITE "'+location+'" LEVEL 1')
        
    def addcomp(self,compname,constraint):
        self.pcflines.append('COMP "'+compname+'" '+constraint+';')
        

    def timegroups(self):
        x = []
        for line in self.pcflines:
            tmp = self.timegrppattern.match(line)
            if tmp is None:
                continue
            x.append(tmp.group(1))


        return x


    def getall_pins(self):
        pinpattern = re.compile(r'^PIN\s+([^\s]+)\s+=\s+BEL\s+"([^"]+)"\s+(.*);$')
        x = []
        for line in self.pcflines:
            tmp = pinpattern.match(line)
            if tmp is None:
                continue
            x.append((tmp.group(1),tmp.group(2),tmp.group(3)))
        return x


    def add_pins(self,pinlist,prefix):
        for x in pinlist:
            self.pcflines.insert(0,'PIN '+prefix+x[0]+' = BEL "'+prefix+x[1]+'" '+x[2]+";")


    def timegrpbels(self,timegrpname):
        nettype = None
        nets = []
        for lineno in range(len(self.pcflines)):
            line = self.pcflines[lineno]
            tmp = self.timegrppattern.match(line)
            if tmp is None:
                continue

            if tmp.group(1) != timegrpname:
                continue


            bellist = tmp.group(2).split(' ')
            if(bellist[0] != "="):
                raise xdl.badNetlist("Expected = in timegrp, found "+bellist[0]+"something else")
            bellist.pop(0)
            
            for i in bellist:
                if len(i) == 0:
                    continue
                
                if i[0] != '"':
                    if nettype is not None:
                        raise xdl.badNetlist("Did not expect more than one nettype for a net in the TIMEGRP constraint")
                    nettype = i
                elif nettype is not None:
                    nets.append((nettype,i.strip('"').rstrip('"')))
                    nettype = None
                else:
                    raise xdl.badNetlist("Found net without nettype")

            if nettype is not None:
                raise xdl.badNetlist("Found nettype without net")
        return nets
    
            

            
