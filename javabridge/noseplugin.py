# CellProfiler is distributed under the GNU General Public License.
# See the accompanying file LICENSE for details.
# 
# Copyright (c) 2003-2009 Massachusetts Institute of Technology
# Copyright (c) 2009-2013 Broad Institute
# 
# Please see the AUTHORS file for credits.
# 
# Website: http://www.cellprofiler.org

import logging
from nose.plugins import Plugin
import os
import numpy as np
np.seterr(all='ignore')
import sys

import javabridge


log = logging.getLogger(__name__)

#class_path = os.pathsep.join(javabridge.JARS)
#javabridge.start_vm(['-Djava.class.path=' + class_path],
#                    run_headless=True)

class JavabridgePlugin(Plugin):
    '''Javabridge nose test plugin
    
    This plugin starts the JVM before running tests and kills it when
    the tests are done. The plugin is necessary because the JVM cannot
    be restarted once it is killed, so unittest's setUp() and
    tearDown() methods cannot be used to start and stop the JVM.
    '''
    enabled = False
    name = "javabridge"
    score = 100

    def begin(self):
        class_path = os.pathsep.join(javabridge.JARS)
        javabridge.start_vm(['-Djava.class.path=' + class_path],
                            run_headless=True)

    def prepareTestRunner(self, testRunner):
        '''Need to make the test runner call finalize if in Wing
        
        Wing IDE's XML test runner fails to call finalize, so we
        wrap it and add that function here
        '''
        if (getattr(testRunner, "__module__","unknown") == 
            "wingtest_common"):
            outer_self = self
            class TestRunnerProxy(object):
                def run(self, test):
                    result = testRunner.run(test)
                    outer_self.finalize(testRunner.result)
                    return result
                
                @property
                def result(self):
                    return testRunner.result
            return TestRunnerProxy()
            
    def finalize(self, result):
        javabridge.kill_vm()
