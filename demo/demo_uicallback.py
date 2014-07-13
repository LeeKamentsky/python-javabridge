#!/usr/bin/env python

"""demo_uicallback.py - An application that executes Python code from a Java UI

It would be handy to have a Java class that called Python through the Javabridge,
perhaps something like::

    public class PythonEnv {
        public native void exec(String script);
        public native String eval(String script);
    };

but there are myriad difficulties - a Python stack uses Javabridge to
create a Java stack which then uses JNI to execute Python on... what stack?

The easiest strategy is to use a Python thread dedicated to executing or
evaluating scripts sent from Java, using that thread's local context to
hold variables. The Python thread communicates with Java in this example using
two SynchronousQueue objects, one to transmit messages from Java to Python
and another to go in the reverse direction. This example shows how a Java UI
can use ActionListener anonymous classes to talk through the queues to Python.

python-javabridge is licensed under the BSD license.  See the
accompanying file LICENSE for details.

Copyright (c) 2003-2009 Massachusetts Institute of Technology
Copyright (c) 2009-2013 Broad Institute
All rights reserved.

"""

from __future__ import absolute_import
import javabridge
import sys
import traceback

def main(args):
    javabridge.activate_awt()
    script = """
    //--------------------------------------
    //
    // The anonymous callable runs on the thread
    // that started Java - that's the rule with AWT.
    //
    // The callable returns a Java Map whose keys
    // have the labels of objects like "qUp" for
    // the upward queue. Python can then fetch
    // whichever ones it wants and do Java stuff
    // with them.
    //
    //--------------------------------------
    new java.util.concurrent.Callable() {
        call: function() {
            importClass(javax.swing.SpringLayout);
            importClass(javax.swing.JFrame);
            importClass(javax.swing.JTextField);
            importClass(javax.swing.JButton);
            importClass(javax.swing.JScrollPane);
            importClass(javax.swing.JTextArea);
            importClass(java.util.Hashtable);
            importClass(java.awt.event.ActionListener);
            importClass(java.awt.event.WindowAdapter);
            importClass(java.util.concurrent.SynchronousQueue);
            
            d = new Hashtable();
            frame = new JFrame("Callbacks in Java");
            d.put("frame", frame);
            contentPane = frame.getContentPane();
            layout = new SpringLayout();
            contentPane.setLayout(layout);
            
            textField = new JTextField("'Hello, world.'", 60);
            d.put("textField", textField);
            contentPane.add(textField);
            
            execButton = new JButton("Exec");
            contentPane.add(execButton);
            
            evalButton = new JButton("Eval");
            contentPane.add(evalButton);
            
            result = new JTextArea("None");
            scrollPane = new JScrollPane(result)
            contentPane.add(scrollPane);
            d.put("result", result);
            
            //-----------------------------------------------------
            //
            // The layout is:
            //
            // [ textField] [execButton] [evalButton]
            // [    scrollPane                      ]
            //
            //-----------------------------------------------------

            layout.putConstraint(SpringLayout.WEST, textField,
                                 5, SpringLayout.WEST, contentPane);
            layout.putConstraint(SpringLayout.NORTH, textField,
                                 5, SpringLayout.NORTH, contentPane);

            layout.putConstraint(SpringLayout.WEST, execButton,
                                 5, SpringLayout.EAST, textField);
            layout.putConstraint(SpringLayout.NORTH, execButton,
                                 0, SpringLayout.NORTH, textField);
                                 
            layout.putConstraint(SpringLayout.WEST, evalButton,
                                 5, SpringLayout.EAST, execButton);
            layout.putConstraint(SpringLayout.NORTH, evalButton,
                                 0, SpringLayout.NORTH, textField);

            layout.putConstraint(SpringLayout.NORTH, scrollPane,
                                 5, SpringLayout.SOUTH, textField);
            layout.putConstraint(SpringLayout.WEST, scrollPane,
                                 0, SpringLayout.WEST, textField);
            layout.putConstraint(SpringLayout.EAST, scrollPane,
                                 0, SpringLayout.EAST, evalButton);
                                 
            layout.putConstraint(SpringLayout.EAST, contentPane,
                                 5, SpringLayout.EAST, evalButton);
            layout.putConstraint(SpringLayout.SOUTH, contentPane,
                                 20, SpringLayout.SOUTH, scrollPane);
            
            //------------------------------------------------
            //
            // qUp sends messages from Java to Python
            // qDown sends messages from Python to Java
            //
            // The communications protocol is that qUp sends
            // a command. For Exec and Eval commands, qUp sends
            // text and qDown must send a reply to continue.
            // For the Exit command, qUp sends the command and
            // Python must dispose of Java
            //
            //-------------------------------------------------
            
            qUp = new SynchronousQueue();
            qDown = new SynchronousQueue();
            d.put("qUp", qUp);
            d.put("qDown", qDown);
            
            //-----------------------------------------------
            //
            // Create an action listener that binds the execButton
            // action to a function that instructs Python to
            // execute the contents of the text field.
            //
            //-----------------------------------------------
            alExec = new ActionListener() {
                actionPerformed: function(e) {
                    qUp.put("Exec");
                    qUp.put(textField.getText());
                    result.setText(qDown.take());
                }
            };
            execButton.addActionListener(alExec);

            //-----------------------------------------------
            //
            // Create an action listener that binds the evalButton
            // action to a function that instructs Python to
            // evaluate the contents of the text field.
            //
            //-----------------------------------------------
            alEval = new ActionListener() {
                actionPerformed: function(e) {
                    qUp.put("Eval");
                    qUp.put(textField.getText());
                    result.setText(qDown.take());
                }
            };
            evalButton.addActionListener(alEval);
            
            //-----------------------------------------------
            //
            // Create a window listener that binds the frame's
            // windowClosing action to a function that instructs 
            // Python to exit.
            //
            //-----------------------------------------------
            wl = new WindowAdapter() {
                windowClosing: function(e) {
                    qUp.put("Exit");
                }
            };
            
            frame.addWindowListener(wl);

            frame.pack();
            frame.setVisible(true);
            return d;
        }
    };"""
    c = javabridge.run_script(script);
    f = javabridge.make_future_task(c)
    d = javabridge.execute_future_in_main_thread(f);
    d = javabridge.get_map_wrapper(d)
    qUp = d["qUp"]
    qDown = d["qDown"]
    frame = d["frame"]
    while True:
        cmd = javabridge.run_script("qUp.take();", dict(qUp=qUp))
        if cmd == "Exit":
            break
        text = javabridge.run_script("qUp.take();", dict(qUp=qUp))
        if cmd == "Eval":
            try:
                result = eval(text, globals(), locals())
            except Exception as e:
                result = "%s\n%s" % (str(e), traceback.format_exc())
            except:
                result = "What happened?"
        else:
            try:
                exec(text, globals(), locals())
                result = "Operation succeeded"
            except Exception as e:
                result = "%s\n%s" % (str(e), traceback.format_exc())
            except:
                result = "What happened?"
            
        javabridge.run_script("qDown.put(result);", 
                              dict(qDown=qDown, result = str(result)))
    javabridge.run_script("frame.dispose();", dict(frame=frame))

if __name__=="__main__":
    javabridge.start_vm()
    if sys.platform == 'darwin':
        #
        # For Mac, we need to start an event loop
        # on the main thread and run the UI code
        # on a worker thread.
        #
        import threading
        javabridge.mac_run_loop_init()
        class Runme(threading.Thread):
            def run(self):
                javabridge.attach()
                try:
                    main(sys.argv)
                finally:
                    javabridge.detach()
        t = Runme()
        t.start()
        javabridge.mac_enter_run_loop()
    else:
        #
        # For everyone else, the event loop
        # is run by Java and we do everything
        # on the main thread.
        #
        main(sys.argv)
    javabridge.deactivate_awt()
    javabridge.kill_vm()
    