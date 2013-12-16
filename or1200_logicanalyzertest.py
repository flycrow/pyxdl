from xdl import xdl
from pcf import pcf
from xdlutil import par_with_guide

import logic

# Load the design
design = xdl("/extra/skel/lab0-4/hw/synthdir/dafk_mikro.xdl")
designpcf = pcf("/extra/skel/lab0-4/hw/synthdir/dafk_mikro.pcf")

# Decide which clock the logic analyzexr should be connected to
clknet = design.netsbyname["sys_clk"]


# Decide which signals to connect to the logic analyzer
netspec = []
#netspec.append(logic.createbus("s1_addr","s1_addr<%d>",15,2))
netspec.append(logic.createbus("s1_dat_i","s1_dat_i<%d>",31,0))
netspec.append(["ack",["wb_conbus/s_signal<2>_map2"]])
netspec.append(["stb",["m0_stb"]])

# Merge the design
logic.merge_logicanalyzer(design,designpcf,clknet,"sys_sig_gen_div0_CLKFX_BUF",netspec,"AC1","AB1")

# Save the new design
#design.savedesign("des.xdl")
#designpcf.savepcf("new.pcf")

par_with_guide(design,designpcf,"new.ncd","analyzer_enhanced")
