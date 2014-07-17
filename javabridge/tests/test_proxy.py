'''test_proxy.py - test the interface proxy mechanism

python-javabridge is licensed under the BSD license.  See the
accompanying file LICENSE for details.

Copyright (c) 2003-2009 Massachusetts Institute of Technology
Copyright (c) 2009-2013 Broad Institute
All rights reserved.

'''

import unittest
from javabridge import InterfaceProxyServer
import javabridge as J

class TestProxy(unittest.TestCase):
    def test_01_01_close(self):
        server = InterfaceProxyServer()
        server.close()
        
    def test_02_01_make_invoker(self):
        class Invoker:
            def run(self):
                pass
        invoker = Invoker()
        server = InterfaceProxyServer()
        interface = server.make_interface_proxy(
            invoker, ["java.lang.Runnable"])
        server.close()
        
    def test_02_02_run_invoker(self):
        target = [False]
        class Invoker:
            def run(self):
                target[0] = True
        invoker = Invoker()
        server = InterfaceProxyServer()
        interface = server.make_interface_proxy(
            invoker, ["java.lang.Runnable"])
        
        server.close()
        
    def test_02_03_run_invoker_with_python_result(self):
        class Invoker:
            def call(self):
                return "Hello"
        invoker = Invoker()
        server = InterfaceProxyServer()
        interface = server.make_interface_proxy(
            invoker, ["java.util.concurrent.Callable"])
        result = J.call(interface, "call", "()Ljava/lang/Object;")
        self.assertEqual("Hello", J.to_string(result))
        
    def test_02_04_run_invoker_with_java_result(self):
        class Invoker:
            def call(self):
                return J.make_instance("java/lang/Integer", "(I)V", 2)
        invoker = Invoker()
        server = InterfaceProxyServer()
        interface = server.make_interface_proxy(
            invoker, ["java.util.concurrent.Callable"])
        result = J.call(interface, "call", "()Ljava/lang/Object;")
        self.assertTrue(J.is_instance_of(result, "java/lang/Integer"))
        self.assertEquals(J.call(result, "intValue", "()I"), 2)
        
    def test_02_05_run_invoker_with_python_args(self):
        eout = [None]
        class Invoker:
            def exceptionThrown(self, arg):
                eout[0] = arg
            
        invoker = Invoker()
        server = InterfaceProxyServer()
        interface = server.make_interface_proxy(
            invoker, ["java.beans.ExceptionListener"])
        ein = J.make_instance("java/lang/RuntimeException", "()V")
        result = J.call(interface, "exceptionThrown", 
                        "(Ljava/lang/Exception;)V", ein)
        self.assertTrue(isinstance(eout[0], J.JB_Object))
        self.assertTrue(J.is_instance_of(eout[0], "java/lang/RuntimeException"))
        
    def test_03_01_handle_exception(self):
        class Invoker:
            def run(self):
                raise Exception("Nyaah nyaah")
        invoker = Invoker()
        server = InterfaceProxyServer()
        interface = server.make_interface_proxy(
            invoker, ["java.lang.Runnable"])
        self.assertRaises(J.JavaException, J.call, interface, "run", "()V")
        server.close()
        
    def test_03_02_handle_no_method_found(self):
        class Invoker:
            pass
        invoker = Invoker()
        server = InterfaceProxyServer()
        interface = server.make_interface_proxy(
            invoker, ["java.lang.Runnable"])
        self.assertRaises(J.JavaException, J.call, interface, "run", "()V")
        server.close()

    def test_03_03_handle_close(self):
        class Invoker:
            def run(self):
                raise Exception("Nyaah nyaah")
        invoker = Invoker()
        server = InterfaceProxyServer()
        interface = server.make_interface_proxy(
            invoker, ["java.lang.Runnable"])
        server.close()
        self.assertRaises(J.JavaException, J.call, interface, "run", "()V")

    def test_03_04_handle_lost_reference(self):
        class Invoker:
            def run(self):
                raise Exception("Nyaah nyaah")
        invoker = Invoker()
        server = InterfaceProxyServer()
        interface = server.make_interface_proxy(
            invoker, ["java.lang.Runnable"])
        del invoker
        self.assertRaises(J.JavaException, J.call, interface, "run", "()V")
        server.close()
        