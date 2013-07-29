#!/usr/bin/env python

import os
import threading
import time
import wx
import javabridge.jutil as j

javabridge.start_vm(['-Djava.class.path=' + os.pathsep.join(javabridge.JARS)])

class EmptyApp(wx.App):
    def OnInit(self):
        j.activate_awt()
        return True
    
app = EmptyApp(False)

# Must exist (perhaps the app needs to have a top-level window?), but
# does not have to be shown.
frame = wx.Frame(None)

j.execute_runnable_in_main_thread(j.run_script("""
            new java.lang.Runnable() {
                run: function() {
                    with(JavaImporter(java.awt.Frame)) Frame().setVisible(true);
                }
            };"""))

app.MainLoop()

j.kill_vm()
