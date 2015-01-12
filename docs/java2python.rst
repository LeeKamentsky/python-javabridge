Calling Python from Java
========================

The Javabridge loads a Java class, org.cellprofiler.javabridge.CPython, that
can be used to execute Python code. The class can be used within Java code
called from the Python interpreter or it can be used within Java to run
Python embedded in Java.

.. js:class:: org.cellprofiler.javascript.CPython
    
    The CPython class binds the Python interpreter to the JVM and provides
    the ability to execute Python scripts.
    
    .. js:function:: exec
    
        :param script: The Python script to execute.
        :param locals: A map of the name of a Java object in the Python
                       execution context to the Java object itself. The objects
                       in the map have local scope. A null value can be used
                       if no locals need to be defined.
        :param globals: A map of the name of a Java object to the Java
                        object itself. The objects in the map have global scope.
                        If a null value is used, ``globals`` defaults to the
                        builtin globals.
                        
        ``exec()`` executes the script passed within the Python interpreter.
        The interpreter adds the builtin globals to the globals passed in,
        then executes the script. The same map may be used for both the
        locals and the globals - this mode may seem more familiar to those
        who regularly script in Python and expect the ``import`` statement
        to have a global effect.
        
        There is no ``eval`` method. You can retrieve values by passing
        a container object such as an array or map as one of the locals and you
        can set elements in the object with values to be returned.
        
        Example::
        
            class MyClass {
                static final CPython cpython = CPython();
                
                public List<String> whereIsWaldo(String root) {
                     ArrayList<String> result = new ArrayList<String>();
                     Hashtable locals = new Hashtable();
                     locals.put("result", result);
                     locals.put("root", root);
                     StringBuilder script = new StringBuilder();
                     script.append("import os\n");
                     script.append("import javabridge\n");
                     script.append("root = javabridge.to_string(root)");
                     script.append("result = javabridge.JWrapper(result)");
                     script.append("for path, dirnames, filenames in os.walk(root):\n");
                     script.append("  if 'waldo' in filenames:");
                     script.append("     result.add(path)");
                     cpython.exec(script.toString(), locals, null);
                     return result;
                } 
            
            }
            
    .. js:function:: execute
    
         ``execute`` is a synonym for ``exec`` which is a Python keyword.
         Use ``execute`` in place of ``exec`` to call Python from a javabridge
         CWrapper for CPython.
            