#!/usr/bin/python

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


# A GUI that can insert a logic analyzer into a design
# WARNING: GUI is not very well written... it works if
# you don't do thing in the wrong order...

import wx
import  wx.lib.filebrowsebutton as filebrowse
import  wx.lib.mixins.listctrl  as  listmix
import string
import os
import sys

from xdl import xdl
from pcf import pcf
import xdlutil
import logic

import re


# FIXME - filter out signals that are impossible to bring out:
#         (Carry signals for example)
# This will not be trivial...

class TextLabel(wx.Panel):
    def __init__(self, parent, labeltext, text=""):
        wx.Panel.__init__(self,parent,-1)
        l1 = wx.StaticText(self,-1,labeltext)
        t1 = wx.TextCtrl(self,-1,text)
        hbox = wx.BoxSizer(wx.HORIZONTAL)
        hbox.Add(l1,1)
        hbox.Add(t1,1,wx.EXPAND)
        self.SetSizer(hbox)
        self.SetAutoLayout(True)
        self.Layout()
        self.text = t1

    def getText(self):
        return self.text.GetValue()

class ButtonText(wx.Panel):
    def __init__(self, parent, buttontext,text, callback):
        wx.Panel.__init__(self,parent,-1)
        b1 = wx.Button(self,-1,buttontext)
        t1 = wx.TextCtrl(self,-1,text)
        hbox = wx.BoxSizer(wx.HORIZONTAL)
        hbox.Add(b1,1)
        hbox.Add(t1,1,wx.EXPAND)
        self.SetSizer(hbox)
        self.SetAutoLayout(True)
        self.Layout()
        self.text = t1
        self.Bind(wx.EVT_BUTTON,callback,b1)

    def getText(self):
        return self.text.GetValue()

    def setText(self,text):
        self.text.SetValue(text)




class SignalsPanel(wx.Panel):
    def __init__(self, parent):
        wx.Panel.__init__(self, parent, -1, style=wx.WANTS_CHARS)
        sizer = wx.BoxSizer(wx.VERTICAL)
        self.list = SignalsList(self,wx.NewId(),style=wx.LC_REPORT | wx.BORDER_NONE | wx.LC_SORT_ASCENDING, size=(500,500))
        sizer.Add(self.list,1,wx.EXPAND)
        self.SetSizer(sizer)
        self.SetAutoLayout(True)

    def buildNetSpec(self):
        return self.list.buildNetSpec()

    def addItem(self,netname,data):
        self.list.addItem(netname,data)



class SignalsList(wx.ListCtrl,
                  listmix.ListCtrlAutoWidthMixin,
                  listmix.TextEditMixin):

    def __init__(self, parent, ID, pos=wx.DefaultPosition,
                 size=wx.DefaultSize, style=0):
        wx.ListCtrl.__init__(self, parent, ID, pos, size, style)

        listmix.ListCtrlAutoWidthMixin.__init__(self)
        self.InsertColumn(0,"Short name")
        self.InsertColumn(1,"Net name")
        self.InsertColumn(2,"MSB")
        self.InsertColumn(3,"LSB")
        self.currentItem = 0
        self.SetAutoLayout(True)
        listmix.TextEditMixin.__init__(self)


    # netname is something like "cpu/instance/netname<5:0>"
    def addItem(self,netname, tag):
        lastpart = string.split(netname,'/')
        lastpart = lastpart.pop()
        id = self.InsertStringItem(sys.maxint,lastpart)
        nobusbrackets = string.split(netname,'<')
        nobusbrackets = nobusbrackets[0]
        self.SetStringItem(id,1,nobusbrackets)
        if tag:
            self.SetStringItem(id,2,str(tag[0]))
            self.SetStringItem(id,3,str(tag[1]))
        self.Layout()
        
    def buildNetSpec(self):
        netspec = []
        i = 0
        while i < self.GetItemCount():
            # Str in order to avoid Unicode strings
            name =    str(self.GetItem(i,0).GetText())
            netname = str(self.GetItem(i,1).GetText())
            msb =     str(self.GetItem(i,2).GetText())
            lsb =     str(self.GetItem(i,3).GetText())
            if msb:
                netspec.append(logic.createbus(name,netname + "<%d>",int(msb),int(lsb)))
            else:
                netspec.append([name,[netname]])
            i = i + 1

        return netspec



class LogicAnalyzerFrame(wx.Frame):


    def addpath(self, name,tag):
        pathparts = string.split(name,'/')
        current = self.root
        for i in pathparts:
            if not current[0].has_key(i):
                id = self.tree.AppendItem(current[1],i)
                current[0][i] = [ {} , id, None ]
            current = current[0][i]

        if current[2] is not None:
            raise "Duplicate!"
        current[2] = name
        self.tree.SetItemPyData(id,[name,tag])
        

# FIXME - fix GUI to look prettier...
# FIXME - perhaps we should filter out GLOBAL_LOGIC0/1, XIL_ML_UNUSED_DCM?
    def __init__(self, parent, id, title):
        wx.Frame.__init__(self, parent, id, title, wx.DefaultPosition)


        hbox = wx.BoxSizer(wx.HORIZONTAL)
        leftbox = wx.BoxSizer(wx.VERTICAL)
        leftpanel = wx.Panel(self, -1)
        rightpanel = wx.Panel(self,-1)
        rightbox = wx.BoxSizer(wx.VERTICAL)
        self.rightpanel = rightpanel

        buttonspanel = wx.Panel(rightpanel, -1)
        buttonbox = wx.BoxSizer(wx.VERTICAL)

        # TreeCtrl for the net list
        self.tree = wx.TreeCtrl(leftpanel, 1, wx.DefaultPosition, (-1,-1), wx.TR_HIDE_ROOT|wx.TR_HAS_BUTTONS)
        leftbox.Add(self.tree, 1, wx.EXPAND)
        hbox.Add(leftpanel, 1, wx.EXPAND)
        hbox.Add(rightpanel, 1)
        leftpanel.SetSizer(leftbox)
        leftpanel.SetAutoLayout(True)

        b1 = wx.Button(buttonspanel, -1, "Read files")
        b2 = wx.Button(buttonspanel, -1, "Create new BIT file")

        self.clknet = ButtonText(buttonspanel,"Clock net", "", self.OnClkNetSelect)
        self.timegrpwidget= ButtonText(buttonspanel,"Timing Group","",self.OnTimingNetSelect)

        # My default pins for Avnet SX-35 prototype board
        self.txbutton = TextLabel(buttonspanel,"RS232 Tx-pin","AB1")
        self.rxbutton = TextLabel(buttonspanel,"RS232 Rx-pin","AC1")

        b3 = wx.Button(buttonspanel, -1, "Add signal")
        self.searchwidget = ButtonText(buttonspanel,"Search",".*",self.OnSearch)

        buttonbox.Add(b1,-1,wx.EXPAND)
        buttonbox.Add(b2,-1,wx.EXPAND)
        buttonbox.Add(self.clknet,-1,wx.EXPAND)
        buttonbox.Add(self.timegrpwidget,-1,wx.EXPAND)
        buttonbox.Add(self.txbutton,-1,wx.EXPAND)
        buttonbox.Add(self.rxbutton,-1,wx.EXPAND)
        buttonbox.Add(self.searchwidget,-1,wx.EXPAND)
        buttonbox.Add(b3,-1,wx.EXPAND)

        buttonspanel.SetSizer(buttonbox)
        buttonbox.SetSizeHints(buttonspanel)
        buttonspanel.Fit()

        rightbox.Add(buttonspanel)


        self.sigpanel = SignalsPanel(rightpanel)
        
        rightbox.Add(self.sigpanel,-1)
        rightpanel.SetSizer(rightbox)
        rightpanel.Layout()
        rightpanel.Fit()
        

        self.Bind(wx.EVT_BUTTON, self.SelectFiles,b1)
        self.Bind(wx.EVT_BUTTON, self.OnNcdCreate,   b2)
        self.Bind(wx.EVT_BUTTON, self.OnAddSignal,   b3)

        

        self.SetSizer(hbox)
#        self.Centre()
        root = self.tree.AddRoot('/')
        self.root = [ {}, root, None ]

        return

    def error(self,txt):
        dlg = wx.MessageDialog(None, txt, "Error", wx.OK)
        dlg.ShowModal()
        dlg.Destroy()


    def OnNcdCreate(self,event):
        netspec = self.sigpanel.buildNetSpec()

        clknetname = str(self.clknet.getText())
        timegrpname = str(self.timegrpwidget.getText())
        rxname = str(self.rxbutton.getText())
        txname = str(self.txbutton.getText())
        

        if len(clknetname) == 0:
            wx.MessageBox("No clocknet selected","Error",wx.OK | wx.ICON_ERROR)
            return

        if len(timegrpname) == 0:
            wx.MessageBox("No timing group selected","Error",wx.OK | wx.ICON_ERROR)
            return

        if len(rxname) == 0:
            wx.MessageBox("No RX pin selected","Error",wx.OK | wx.ICON_ERROR)
            return

        if len(txname) == 0:
            wx.MessageBox("No RX pin selected","Error",wx.OK | wx.ICON_ERROR)
            return

        logic.merge_logicanalyzer(self.design, self.designpcf,
                                  self.design.netsbyname[clknetname],
                                  timegrpname, netspec,
                                  rxname, txname)

        xdlutil.par_with_guide(self.design, self.designpcf, "new.ncd", "analyzer_enhanced")
        xdlutil.bitgen("new.ncd")


    
    def OnTimingNetSelect(self,event):
        import wxPython.lib.dialogs 
        dialog = wx.SingleChoiceDialog ( None, 'Select the clock net', 'Clock net', self.designpcf.timegroups())
        if dialog.ShowModal() == wx.ID_OK:
            self.timegrpwidget.setText(dialog.GetStringSelection())
            

    def OnClkNetSelect(self,event):
        import wxPython.lib.dialogs 
        nets = self.design.clocknets()
        choices = []
        for i in nets:
            choices.append(i[0]+ " (" + str(i[1]) + " instances)")
        dialog = wx.SingleChoiceDialog ( None, 'Select the timing group', 'Timing group', choices)
        if dialog.ShowModal() == wx.ID_OK:
            self.clknet.setText(nets[dialog.GetSelection()][0])


        

    def OnSearch(self,event):
        search = re.compile(self.searchwidget.getText())
        self.tree.DeleteAllItems()
        root = self.tree.AddRoot('/')
        self.root = [ {}, root, None ]
        for n in self.nets:
            if search.match(n[0]):
                self.addpath(n[0],n[1])
        
    def OnAddSignal(self,event):
        item = self.tree.GetSelection()
        data = self.tree.GetItemPyData(item)
        netname = data[0]
        self.sigpanel.addItem(netname,data[1])
        self.rightpanel.Layout()
        self.rightpanel.Fit()
        

    def SelectFiles(self,event):
        dlg = wx.FileDialog(self,message="Choose an NCD or XDL file", defaultDir=os.getcwd(),defaultFile="",
                            wildcard="XDL design file (*.xdl)|*.xdl|(NCD design file (*.ncd)|*.ncd|All files(*)|*",
                            style = wx.OPEN | wx.CHANGE_DIR)
        if not dlg.ShowModal() == wx.ID_OK:
            dlg.Destroy()
            return

        xdlfile = dlg.GetPaths()[0]
        dlg.Destroy()

        dlg = wx.FileDialog(self,message="Choose a constraint file (PCF)", defaultDir=os.getcwd(),defaultFile="",
                            wildcard="PCF constraint file (*.pcf)|*.pcf|All files(*)|*",
                            style = wx.OPEN | wx.CHANGE_DIR)
        if not dlg.ShowModal() == wx.ID_OK:
            dlg.Destroy()
            return

        pcffile = dlg.GetPaths()[0]
        dlg.Destroy()

        self.ReadFiles(xdlfile,pcffile)



    # FIXME - Too long, refactor this into more than one function
    def ReadFiles(self,xdlfile,pcffile):
        self.design = xdl(xdlfile)
        self.designpcf = pcf(pcffile)

        buses = {}
        nets = []
        
        buspat = re.compile(r'^(.*)<([0-9]+)>$')
        for net in self.design.netsbyname:
            bus = buspat.match(net)
            if bus:
                busname = bus.group(1)
                if buses.has_key(busname):
                    buses[busname].append(int(bus.group(2)))
                else:
                    buses[busname] = [ int(bus.group(2)) ]
            else:
                nets.append([net,False])

        for busname in buses:
            bus = buses[busname]
            bus.sort()
            x = bus[0]
            bus.pop(0)
            bus.append(9999999) # FIXME - only works if noone has a bus with this index...
            first = x
            for i in bus:
                if( x + 1 != i):
                    # FIXME - assumes MSB:LSB-notation of vectors
                    nets.append([busname + "<" + str(x) + ":" + str(first) + ">",[x,first]])
                    first = i
                x = i

        nets.sort()
        self.nets = nets
        for n in nets:
            self.addpath(n[0],n[1])








class MyApp(wx.App):
    def OnInit(self):
        self.frame = LogicAnalyzerFrame(None, -1, 'Select nets')
        self.frame.Show(True)
        self.SetTopWindow(self.frame)
        return True

app = MyApp(0)
app.MainLoop()
