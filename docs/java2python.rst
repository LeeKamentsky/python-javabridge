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
            
Maintaing references to Python values
-------------------------------------

You may want to maintain references to Python objects across script executions.
The following functions let a Java caller refer to a Python value (which can
be a base type or an object) via a token which may be exchanged for the value 
at any time.  The Java code is responsible for managing the reference's lifetime.
Example::

    import javabridge
    
    cpython = javabridge.JClassWrapper('org.cellprofiler.javabridge.CPython')()
    d = javabridge.JClassWrapper('java.util.Hashtable')()
    result = javabridge.JClassWrapper('java.util.ArrayList')()
    d.put("result", result)
    cpython.execute(
        'import javabridge\n'
        'x = { "foo":"bar"}\n'
        'ref_id = javabridge.create_and_lock_jref(x)\n'
        'javabridge.JWrapper(result).add(ref_id)', d, d)
    cpython.execute(
        'import javabridge\n'
        'ref_id = javabridge.to_string(javabridge.JWrapper(result).get(0))\n'
        'assert javabridge.redeem_jref(ref_id)["foo"] == "bar"\n'
        'javabridge.unlock_jref(ref_id)', d, d)
        
.. autofunction:: javabridge.create_jref
.. autofunction:: javabridge.create_and_lock_jref
.. autofunction:: javabridge.redeem_jref
.. autofunction:: javabridge.lock_jref
.. autofunction:: javabridge.unlock_jref

    