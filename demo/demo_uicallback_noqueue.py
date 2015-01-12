#!/usr/bin/env python

"""demo_uicallback_noqueue.py - An application that executes Python code in a UI from Java

This example uses org.cellprofiler.javabridge.CPython to execute
Python code from within a Java callback.

python-javabridge is licensed under the BSD license.  See the
accompanying file LICENSE for details.

Copyright (c) 2003-2009 Massachusetts Institute of Technology
Copyright (c) 2009-2013 Broad Institute
All rights reserved.

"""
import javabridge
import sys
import traceback

def main(args):
    javabridge.activate_awt()
    cpython = javabridge.make_instance(
        "org/cellprofiler/javabridge/CPython", "()V")
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
            importClass(java.util.ArrayList);
            importClass(java.util.concurrent.CountDownLatch);
            importClass(java.awt.event.ActionListener);
            importClass(java.awt.event.WindowAdapter);
            
            d = new Hashtable();
            signal = new CountDownLatch(1);
            d.put("signal", signal);
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
            
            //-----------------------------------------------
            //
            // Create an action listener that binds the execButton
            // action to a function that instructs Python to
            // execute the contents of the text field.
            //
            //-----------------------------------------------
            alExec = new ActionListener() {
                actionPerformed: function(e) {
                    try {
                        cpython.exec(textField.getText());
                        result.setText("OK");
                    } catch(err) {
                        result.setText(err.message);
                    }
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
                    try {
                        locals = new Hashtable();
                        jresult = new ArrayList();
                        locals.put("script", textField.getText());
                        locals.put("jresult", jresult);
                        script = "import javabridge\\n" +
                                 "result=eval(javabridge.to_string(script))\\n" +
                                 "jwresult=javabridge.JWrapper(jresult)\\n" +
                                 "jwresult.add(str(result))"
                        cpython.exec(script, locals, null);
                        result.setText(jresult.get(0));
                    } catch(err) {
                        result.setText(err.message);
                    }
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
                    signal.countDown();
                }
            };
            
            frame.addWindowListener(wl);

            frame.pack();
            frame.setVisible(true);
            return d;
        }
    };"""
    c = javabridge.run_script(script, dict(cpython=cpython));
    f = javabridge.make_future_task(c)
    d = javabridge.execute_future_in_main_thread(f);
    d = javabridge.get_map_wrapper(d)
    frame = javabridge.JWrapper(d["frame"])
    signal = javabridge.JWrapper(d["signal"]);
    signal.await();
    frame.dispose();

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
    