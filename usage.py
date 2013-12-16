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

from xdl import xdl
from sys import argv

# Load design
des = xdl(argv[1])

if len(argv) > 2:
    hierarchylimit = int(argv[2])
else:
    hierarchylimit = 1

# Find all instances
toplevel = ({},{})
for name in des.insts:
    inst = des.insts[name]


    hierpos = toplevel
    types = hierpos[0]

    if not hierpos[0].has_key(inst.thetype):
        hierpos[0][inst.thetype] = 0
        
    hierpos[0][inst.thetype] += 1
    hierpos = hierpos[1]

    fullname = "/"
    hierarchy = inst.name.split('/')
    lastname = hierarchy.pop()
    for n in hierarchy:
        fullname = fullname + n + '/'
        if not hierpos.has_key(fullname):
            hierpos[fullname] = [{},{}]

        if not hierpos[fullname][0].has_key(inst.thetype):
            hierpos[fullname][0][inst.thetype] = 0
        
        hierpos[fullname][0][inst.thetype] += 1
        hierpos = hierpos[fullname][1]

    fullname = fullname + lastname
    hierpos[fullname] = [{inst.thetype:1},{}]


sortkey = ""

def sortfunc(a,b):
    global sortkey
    tmpb = b[1]
    tmpa = a[1]

    if not tmpa[0].has_key(sortkey):
        return 1
    if not tmpb[0].has_key(sortkey):
        return -1

    return tmpb[0][sortkey] - tmpa[0][sortkey]

# Print the analysis
def printit(insts,name,printlimit,levellimit,keys,thelist):
    global sortkey
    # We don't want to print single instances
    if len(insts[1]) == 0:
        return


    if not insts[0].has_key(sortkey):
        return

    if (levellimit < 0) and (printlimit > insts[0][sortkey]):
        return


    l = [name]
    for i in keys:
        if(insts[0].has_key(i)):
            l.append(str(insts[0][i]))
        else:
            l.append(str(0))
    thelist.append(l)

    l = []
    for i in insts[1]:
        tmp = insts[1][i]
        l.append((i,tmp))

    l.sort(sortfunc)
    for i in l:
        printit(i[1],i[0],printlimit,levellimit-1,keys,thelist)




# Sort based on slice usage
sortkey = "SLICEL"
types = ["SLICEL","SLICEM","RAMB16","IOB","DSP48"]
mainlist = []
printit(toplevel,"/",0.1*toplevel[0][sortkey],hierarchylimit, types,mainlist)

maxlen = []

types.insert(0,"Name")
mainlist.insert(0,types)

# Find the maximum lengths for various fields...
maxlengths = [0]*len(types)
for row in mainlist:
    for j in range(0,len(types)):
        maxlengths[j] = max(maxlengths[j],len(row[j]))

from sys import stdout

mainlist.insert

mainlist.append(["#"])
mainlist.insert(1,["#"])
mainlist.insert(0,["#"])

# Pretty printing...
for row in mainlist:
    if row[0] == "#":
        length = sum(maxlengths)+3*len(maxlengths)+1
        print "#"*length
        continue
        
    print '#',
    print row[0].ljust(maxlengths[0]),

    for col in range(1,len(row)):
        print "#",
        print row[col].rjust(maxlengths[col]),
    print "#"

