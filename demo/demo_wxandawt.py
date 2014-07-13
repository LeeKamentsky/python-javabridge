#!/usr/bin/env python

"""demo_wxandawt.py - show how to start the Javabridge with wxPython and AWT

python-javabridge is licensed under the BSD license.  See the
accompanying file LICENSE for details.

Copyright (c) 2003-2009 Massachusetts Institute of Technology
Copyright (c) 2009-2013 Broad Institute
All rights reserved.

"""

from __future__ import absolute_import

import os
import wx
import javabridge

class EmptyApp(wx.PySimpleApp):
    def OnInit(self):
        javabridge.activate_awt()

        return True

javabridge.start_vm()

try: 
    app = EmptyApp(False)

    frame = wx.Frame(None)
    frame.Sizer = wx.BoxSizer(wx.HORIZONTAL)
    launch_button = wx.Button(frame, label="Launch AWT frame")
    frame.Sizer.Add(launch_button, 1, wx.ALIGN_CENTER_HORIZONTAL)

    def fn_launch_frame(event):
        javabridge.execute_runnable_in_main_thread(javabridge.run_script("""
        new java.lang.Runnable() {
            run: function() {
                with(JavaImporter(java.awt.Frame)) Frame().setVisible(true);
            }
        };"""))
    launch_button.Bind(wx.EVT_BUTTON, fn_launch_frame)

    frame.Layout()
    frame.Show()
    app.MainLoop()

finally:

    javabridge.kill_vm()
