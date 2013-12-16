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
from xdlutil import *
from sys import argv

# Sorry, hardcoded now, just for demonstration purposes
#
# Eventually it would be nice to automatically select which areas
# to color
slicecolors = [[re.compile('^cpu/or1200_cpu/or1200_alu'),(255,0,0)],
               [re.compile('^cpu/or1200_cpu/or1200_mult_mac'),(0,255,0)],
               [re.compile('^cpu/or1200_cpu/or1200_sprs'),(0,0,255)],
               [re.compile('^cpu/or1200_cpu/or1200_genpc'),(0,255,255)],
               [re.compile('^cpu/or1200_cpu/or1200_except'),(255,0,255)],
               [re.compile('^cpu/or1200_cpu/or1200_if'),(0,128,0)],
               [re.compile('^cpu/or1200_cpu/or1200_rf'),(0,128,128)],
               [re.compile('^cpu'),(0,255,0)]]

d = xdl(argv[1])

design_to_image(d,"test.png",slicecolors)

