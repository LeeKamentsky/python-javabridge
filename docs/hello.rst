Hello world
===========

Without a GUI::

    import os
    import javabridge
    
    javabridge.start_vm(run_headless=True)
    try:
        print javabridge.run_script('java.lang.String.format("Hello, %s!", greetee);', 
                                    dict(greetee='world'))
    finally:
        javabridge.kill_vm()
    
With only a Java AWT GUI::

    import os
    import wx
    import javabridge
    
    javabridge.start_vm()
    
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

Mixing wxPython and Java AWT GUIs::

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
