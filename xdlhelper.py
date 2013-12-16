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

import xdl
import re
import string

# Some helper functions used by xdl.py

nostring_ends_in_comment = re.compile(r'([^"#]*("[^"]*"[^#"]*)*[^"#]*)(#.*)')
string_ends_in_comment = re.compile(r'([^"#]*"[^"#]*("[^"]*"[^#"]*)*[^"#]*)(#.*)')

def filereader(filename):

    f = open(filename,"r")
    semicolon = re.compile('.*;$')
    lines = []
    instring = 0;
    lineno = 0
    for line in f:
        line = line.rstrip("\n\r")
        # FIXME - this destroys cfg strings which contains a " in it...
        line = line.replace('\\"',"'")
        
        lineno = lineno + 1
#        if not (lineno % 10000):
#            print lineno
            
        # Skip line with // at starting position
        if (len(line) >= 2) and (line[0] == '/') and (line[1] == '/'):
            continue

        if instring:
            tmp=string_ends_in_comment.match(line)
            if tmp:
                line = tmp.group(1)
                
            # Check if we are still in the string
            if line.count('"') % 2 == 1: # Odd number of quotes
                instring = 0
        else:
            tmp = nostring_ends_in_comment.match(line)
            if tmp:
                line = tmp.group(1)
            if line.count('"') % 2 == 1:
                instring = 1



        if(semicolon.match(line)):
            finished = 1
        else:
           finished = 0

        lines.append(line)


        if not finished:
           continue

        if instring:
           raise xdlInternalError()


        line = string.join(lines)
        lines = []
        yield line

    f.close()
    return


