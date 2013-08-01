.. -*- visual-line-mode -*-

Starting and killing the JVM
============================

API
---

.. autofunction:: javabridge.start_vm
.. autofunction:: javabridge.kill_vm

.. py:data:: javabridge.JARS

   a list of strings; gives the full path to some JAR files that should be added to the class path in order for all the feature sof the Javabridge to work properly.

.. autofunction:: javabridge.activate_awt
.. autofunction:: javabridge.deactivate_awt

Environment
+++++++++++

In order to use the Javabridge in a thread, you need to attach to the JVM's environment in that thread. In order for the garbage collector to be able to collect thread-local variables, it is also necessary to detach from the environment before the thread ends.

.. autofunction:: javabridge.attach
.. autofunction:: javabridge.detach



Without GUI (headless mode)
---------------------------

Using the JVM in headless mode is straighforward::

    import os
    import javabridge
    
    javabridge.start_vm(['-Djava.class.path=' + os.pathsep.join(javabridge.JARS)], 
                run_headless=True)
    try:
        print javabridge.run_script('java.lang.String.format("Hello, %s!", greetee);', 
                                    dict(greetee='world'))
    finally:
        javabridge.kill_vm()

With GUI on the Java side
-------------------------

Using the JVM with a graphical user interface is much more involved
because you have to run an event loop on the Python side. You also
have to make sure that everything executes in the proper thread; in
particular, all GUI operations have to run in the main thread on Mac
OS X. Here is an example, using a wxPython app to provide the event loop::

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

With GUI on both the Java side and the Python side
--------------------------------------------------

Finally, an example combining AWT for GUI on the Java side with
wxPython for GUI on the Python side::

    import os
    import wx
    import javabridge

    class EmptyApp(wx.PySimpleApp):
        def OnInit(self):
            javabridge.activate_awt()

            return True

    javabridge.start_vm(['-Djava.class.path=' + os.pathsep.join(javabridge.JARS)])

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

