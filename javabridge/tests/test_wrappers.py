'''test_wrappers.py test JWrapper and JClassWrapper

python-javabridge is licensed under the BSD license.  See the
accompanying file LICENSE for details.

Copyright (c) 2003-2009 Massachusetts Institute of Technology
Copyright (c) 2009-2013 Broad Institute
All rights reserved.

'''
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