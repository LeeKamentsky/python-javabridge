#!/usr/bin/env python

"""demo_nogui.py - show how to start the Javabridge without a GUI

python-javabridge is licensed under the BSD license.  See the
accompanying file LICENSE for details.

Copyright (c) 2003-2009 Massachusetts Institute of Technology
Copyright (c) 2009-2013 Broad Institute
All rights reserved.

"""

from __future__ import print_function

from __future__ import absolute_import

import os
import javabridge

javabridge.start_vm(run_headless=True)
try:
    print(javabridge.run_script('java.lang.String.format("Hello, %s!", greetee);', 
                                dict(greetee='world')))
finally:
    javabridge.kill_vm()
