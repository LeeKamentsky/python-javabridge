#!/usr/bin/env python

import os
import javabridge.jutil as j

jars_dir = os.path.join(os.path.dirname(__file__), '..', 'jars')
class_path = os.pathsep.join([os.path.join(jars_dir, name + '.jar')
                              for name in ['rhino-1.7R4', 'runnablequeue-1.0.0']])
j.start_vm(['-Djava.class.path=' + class_path], 
            run_headless=True)
try:
    print j.run_script('java.lang.String.format("Hello, %s!", greetee);', 
                       dict(greetee='world'))
finally:
    j.kill_vm()
