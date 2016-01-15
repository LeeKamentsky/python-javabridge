#!/usr/bin/env python

"""demo_nogui.py - show how to start the Javabridge without a GUI

python-javabridge is licensed under the BSD license.  See the
accompanying file LICENSE for details.

Copyright (c) 2003-2009 Massachusetts Institute of Technology
Copyright (c) 2009-2013 Broad Institute
All rights reserved.

"""

import os
import javabridge

with javabridge.vm(run_headless=True):
    print javabridge.run_script('java.lang.String.format("Hello, %s!", greetee);', 
                                dict(greetee='world'))
