#!/usr/bin/env python

import os
import javabridge

javabridge.start_vm(['-Djava.class.path=' + os.pathsep.join(javabridge.JARS)], 
            run_headless=True)
try:
    print javabridge.run_script('java.lang.String.format("Hello, %s!", greetee);', 
                                dict(greetee='world'))
finally:
    javabridge.kill_vm()
