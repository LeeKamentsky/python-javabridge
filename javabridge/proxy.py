# -*- Encoding: utf-8 -*-
'''proxy.py - mechanism for creating a proxy 

python-javabridge is licensed under the BSD license.  See the
accompanying file LICENSE for details.

Copyright (c) 2003-2009 Massachusetts Institute of Technology
Copyright (c) 2009-2013 Broad Institute
All rights reserved.

java.lang.reflect.Proxy and java.lang.reflect.
'''
import logging
logger = logging.getLogger(__name__)
import javabridge as J
from .wrappers import sig
import threading
import weakref

class InterfaceProxyServer(object):
    '''The interface proxy server manages Python proxies of Java interfaces
    
    The interface proxy server supplies the infrastructure that's needed
    to write Python code that implements Java interfaces. The server
    manages a thread that runs the Python methods that implement the interface
    and that thread communicates with a proxy for the interface you request.
    
    The InterfaceProxyServer does require some lifetime management - you need
    to close it before exiting your application in order to terminate
    its worker thread.
    '''
    def __init__(self):
        self.start_event = threading.Event()
        self.managed_objects = weakref.WeakValueDictionary()
        self.invocation_queue = J.JClassWrapper(
            "org.cellprofiler.runnablequeue.InvocationQueue")()
        self.worker = threading.Thread(target=self.run_worker)
        self.worker.setDaemon(True)
        self.worker.start()
        self.start_event.wait()
        self.proxy_class = J.JClassWrapper("java.lang.reflect.Proxy")
        
    def run_worker(self):
        '''The worker loop that processes invocation requests'''
        J.attach()
        self.start_event.set()
        try:
            while True:
                try:
                    request = self.invocation_queue.takeRequest()
                except J.JavaException, e:
                    if J.is_instance_of(
                        e.throwable, 
                        "org/cellprofiler/runnablequeue/InvocationQueue$InvocationQueueClosedException"):
                        break
                    logger.exception(
                        "Unexpected exception caught while waiting for request")
                    continue
                try:
                    proxy = request.getProxy()
                    invocation_handler = \
                        self.proxy_class.getInvocationHandler(proxy)
                    key = invocation_handler.getUUID().toString()
                    invoker = self.managed_objects.get(key)
                    if invoker is None:
                        request.respondWithException(
                            J.make_instance(
                                "java/lang/IllegalStateException",
                                "(Ljava/lang/String;)V",
                                "Could not find Python handler for proxy"))
                    method = request.getMethod()
                    method_name = method.getName()
                    invoker_method = getattr(invoker, method_name)
                    if invoker_method is None:
                        request.respondWithException(
                            J.make_instance(
                                "java/lang/NoSuchMethodException",
                                "(Ljava/lang/String;)V",
                                "Python handler is missing method, \"%s\"" %
                                method_name))
                    args = [request.getArg(i).o
                            for i in range(request.getArgCount())]
                    result = invoker_method(*args)
                    rsig = sig(method.getReturnType().o)
                    jresult = J.get_nice_arg(result, rsig)
                    request.respond(jresult)
                except J.JavaException as e:
                    if J.is_instance_of(
                        e.throwable, 
                        "org/cellprofiler/runnablequeue/InvocationQueue$InvocationQueueClosedException"):
                        break
                    logger.debug(
                        "Caught Java exception while invoking method %s on proxy interface" %
                        method_name)
                    request.respondWithException(e.throwable)
                except Exception as e:
                    logger.exception(
                        "Caught exception while invoking method %s on proxy interface" %
                        method_name)
                    request.respondWithException(J.make_instance(
                            "java/lang/RuntimeException",
                            "(Ljava/lang/String;)V", str(e)))
        finally:
            J.detach()
    def close(self):
        '''Close the server and join to its thread'''
        self.invocation_queue.close()
        self.worker.join()
        
    def make_interface_proxy(self, invoker, interfaces,
                             class_loader = None):
        '''Make a Java proxy that implements the given interfaces
        
        :param invoker: an object with method names for each method in each of
                  the interfaces. The methods will be called with appropriate
                  arguments as JB_Objects. It is up to the method to translate
                  these into Python types and to disambiguate between overloaded
                  method names.
                  It is the caller's responsibility to maintain a Python
                  reference to the invoker - the server will stop serving
                  the invoker and all method calls will result in Java
                  exceptions after the last reference is lost.
                  
        :param interfaces: a list of either Java classes (e.g. from 
                  class_for_name) or class names in dotted form.
                  
        :param class_loader: define the proxy on this class loader. Default
                  is the system class loader.
                  
        Example:
        class MyFocusListener(object):
            def focusGained(self, event):
                print "Got focus"
            def focusLost(self, event):
                print "Lost focus"
                
        server = InterfaceProxyServer()
        focus_listener = MyFocusListener()
        jfocus_listener = server.make_interface_proxy(focus_listener,
            ["java.awt.event.FocusListener"])
        w.addFocusListener(jfocus_listener)
        ... run the application ...
        server.close()
        '''
        env = J.get_env()
        if class_loader is None:
            class_loader = J.static_call(
                "java/lang/ClassLoader", "getSystemClassLoader",
                "()Ljava/lang/ClassLoader;")
        jinterfaces = J.make_object_array(
            "java.lang.Class",
            [J.class_for_name(x) if isinstance(x, basestring) else x
             for x in interfaces])
        proxy = self.invocation_queue.newInstance(
            class_loader, jinterfaces)
        handler = self.proxy_class.getInvocationHandler(proxy)
        key = handler.getUUID()
        self.managed_objects[J.to_string(key)] = invoker
        return proxy.o