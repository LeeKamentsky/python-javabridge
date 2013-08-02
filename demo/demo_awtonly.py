#!/usr/bin/env python

"""demo_awtonly.py - show how to start the Javabridge with only a Java GUI

python-javabridge is licensed under the BSD license.  See the
accompanying file LICENSE for details.

Copyright (c) 2003-2009 Massachusetts Institute of Technology
Copyright (c) 2009-2013 Broad Institute
All rights reserved.

"""

import os
import wx
import javabridge

javabridge.start_vm(['-Djava.class.path=' + os.pathsep.join(javabridge.JARS)])

class EmptyApp(wx.App):
    def OnInit(self):
        javabridge.activate_awt()
        return True

try:

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

finally:

    javabridge.kill_vm()
