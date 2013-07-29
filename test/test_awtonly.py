#!/usr/bin/env python

import os
import threading
import time
import wx
import javabridge.jutil as j

# Start the JVM
jars_dir = os.path.join(os.path.dirname(__file__), '..', 'jars')
class_path = os.pathsep.join([os.path.join(jars_dir, name + '.jar')
                              for name in ['rhino-1.7R4', 'runnablequeue-1.0.0']])
j.start_vm(['-Djava.class.path=' + class_path])

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
