'''test_wrappers.py test JWrapper and JClassWrapper

python-javabridge is licensed under the BSD license.  See the
accompanying file LICENSE for details.

Copyright (c) 2003-2009 Massachusetts Institute of Technology
Copyright (c) 2009-2013 Broad Institute
All rights reserved.

'''

from __future__ import absolute_import
import unittest
import javabridge as J

class TestJWrapper(unittest.TestCase):
    def test_01_01_init(self):
        jobj = J.get_env().new_string(u"Hello, world.")
        obj = J.JWrapper(jobj)
        self.assertEquals(jobj, obj.o)
        
    def test_01_02_call_noargs(self):
        jobj = J.get_env().new_string(u"Hello, world.")
        obj = J.JWrapper(jobj)
        self.assertEquals(obj.toLowerCase(), "hello, world.")
        
    def test_01_03_call_args(self):
        jobj = J.get_env().new_string(u"Hello, world.")
        obj = J.JWrapper(jobj)
        result = obj.replace("Hello,", "Goodbye cruel")
        self.assertEquals(result, "Goodbye cruel world.")
        
    def test_02_01_get_field(self):
        obj = J.JClassWrapper("org.cellprofiler.javabridge.test.RealRect")(
            1.5, 2.5, 3.5, 4.5)
        self.assertEquals(obj.x, 1.5)
        
    def test_02_02_set_field(self):
        obj = J.JClassWrapper("org.cellprofiler.javabridge.test.RealRect")(
            1.5, 2.5, 3.5, 4.5)
        obj.x = 2.5
        self.assertEquals(obj.x, 2.5)
        
class TestJClassWrapper(unittest.TestCase):
    def test_01_01_init(self):
        c = J.JClassWrapper("java.lang.Integer")
        
    def test_01_02_field(self):
        c = J.JClassWrapper("java.lang.Short")
        field = c.MAX_VALUE
        self.assertEquals(field, (1 << 15)-1)
        
    def test_02_03_static_call(self):
        c = J.JClassWrapper("java.lang.Integer")
        self.assertEquals(c.toString(123), "123")

    
if __name__=="__main__":
    import javabridge
    javabridge.start_vm()
    try:
        unittest.main()
    finally:
        javabridge.kill_vm()