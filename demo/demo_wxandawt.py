#!/usr/bin/env python

import os
import threading
import time
import wx
import javabridge

javabridge.start_vm(['-Djava.class.path=' + os.pathsep.join(javabridge.JARS)])

class EmptyApp(wx.PySimpleApp):
    def OnInit(self):
        javabridge.activate_awt()

        return True

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

javabridge.kill_vm()
