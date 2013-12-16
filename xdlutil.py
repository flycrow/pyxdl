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
from PIL import Image

# For debugging
def printnet(design,name):
    slice = design.insts[name]
    print "*** Slice",slice.name,"is connected from:"
    for i in slice.inpins:
        net = slice.inpins[i]
        print "  *** Netname is",net.name
        for iname in net.outpins:
            print "    ",iname[0]

    print "*** Slice is connected to:"
    for i in slice.outpins:
        net = slice.outpins[i]
        for oname in net.inpins:
            print "   ",oname[0]

# Should move these to a separate directory...
mux = Image.open("mux.png")
ff  = Image.open("ff.png")
sliceimg = Image.open("slice.png")
generic = Image.open("generic.png")
slicemask = Image.open("slicemask.png")
shapemask = Image.open("shapemask.png")
adder     = Image.open("adder.png")

import re
# Pattern for recognizing a mux
lut = re.compile(r'#LUT:D=\(\(~A([0-9])\*A[0-9]\)\+\(A\1\*A[0-9]\)\)')

def figure_lut(f):
    global mux,ff,generic,lut
    fimg = generic
    if f == "#OFF":
        fimg = None
    elif lut.match(f):
        fimg = mux
        

    return fimg




def decidecolor(name,slicecolors):
    col = (255,255,255)
    for i in slicecolors:
        if i[0].match(name):
            return i[1]
    return col

def setslice(img,slice,slicecolors):
    global mux,ff,generic
    
    c = slice.getslicecoord()

    imagex = c[0]*35+1
    imagey = c[1]*35+1

    img.paste(sliceimg,(imagex,imagey))

    img.paste(decidecolor(slice.name,slicecolors),(imagex,imagey,imagex+34,imagey+34),slicemask)

    if slice.cfgentry("_INST_PROP") is not False:
        img.paste(shapemask,(imagex,imagey),shapemask)


    
    

    ffx = slice.cfgentry("FFX")
    if ffx is False:
        ffx= ["","#OFF"]
        
    if ffx[1] != "#OFF":
        img.paste(ff,(imagex+16+1,imagey+1),ff)

    ffy = slice.cfgentry("FFX")
    if ffy is False:
        ffy= ["","#OFF"]
    if ffy[1] != "#OFF":
        img.paste(ff,(imagex+16+1,imagey+1+16),ff)

    
    f = slice.cfgentry("F")
    if f is False:
        f = ["","#OFF"]
    fimg = figure_lut(f[1])

    tmp = slice.cfgentry("FXMUX")
    if tmp is not False:
        if tmp[1] == "FXOR":
            fimg = adder
        
    
    if fimg is not None:
        img.paste(fimg,(imagex+1+1,imagey+1+1),fimg)

    g = slice.cfgentry("G")
    if g is False:
        g = ["","#OFF"]
    gimg = figure_lut(g[1])

    tmp = slice.cfgentry("GYMUX")
    if tmp is not False:
        if tmp[1] == "GXOR":
            gimg = adder
            # A bit ugly, should add more checks here to make sure that it really
            # is an adder.

    if gimg is not None:
        img.paste(gimg,(imagex+1+1,imagey+16+1),gimg)


        
        
    

# Only works for Virtex-4 SX35 (need to add code to
# configure height and width of device)
def design_to_image(design,imgname,slicecolors):
    maxx = design.dev.maxslicex
    maxy = design.dev.maxslicey
    img = Image.new("RGB",((maxx+1)*35,(maxy+1)*35),(255,255,255))

    for x in range(0,maxx*35,35*2):
        img.paste((128,128,128),(x,0,x+1,maxy*35-1))

    for y in range(0,maxy*35,35*2):
        img.paste((128,128,128),(0,y,maxx*35-1,y+1))

    for name in design.insts:
        s = design.insts[name]
        if (s.thetype != "SLICEL") and (s.thetype != "SLICEM"):
            continue

        setslice(img,s,slicecolors)
        

    img.save(imgname,"PNG")
        
# Uses default command line tools to route design
def par_with_guide(design,constraints,resultfile,tempbase):
    import os

    design.savedesign(tempbase+".xdl")
    constraints.savepcf(tempbase+".pcf")
    ret = os.system('xdl -xdl2ncd "'+tempbase+'.xdl"')
    if ret != 0:
        raise "Could not run xdl -xdl2ncd"
    
    # FIXME - should raise error if par fails as well
    ret = os.system('par -gf "'+tempbase+'.ncd" "'+tempbase+'.ncd" "'+resultfile+'" "'+tempbase+'.pcf" -w')

def bitgen(designfile):
    import os
    ret = os.system('bitgen -w ' + designfile)
