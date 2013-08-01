#!/usr/bin/env python

import os
import threading
import time
import wx
import javabridge

javabridge.start_vm(['-Djava.class.path=' + os.pathsep.join(javabridge.JARS)])

class EmptyApp(wx.App):
    def OnInit(self):
        javabridge.activate_awt()
        return True
    
app = EmptyApp(False)

# Must exist (perhaps the app needs to have a top-level window?), but
# does not have to be shown.
frame = wx.Frame(None)

javabridge.execute_runnable_in_main_thread(javabridge.run_script("""
            new java.lang.Runnable() {
                run: function() {
                    with(JavaImporter(java.awt.Frame)) Frame().setVisible(true);
                }
            };"""))

app.MainLoop()

javabridge.kill_vm()
