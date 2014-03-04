.. -*- visual-line-mode -*-

High-level API
===============

This API is high level only in comparison to :doc:`the low-level API<lowlevel>`: the resulting code can still be cumbersome and verbose because of the need to handle signatures when navigating the JVM's object structure. It is often more convenient to interact with a piece of :doc:`JavaScript running on the JVM<javascript>`.

Signatures
----------

The signature syntax is described in `JNI Types and Data Structures <http://docs.oracle.com/javase/1.5.0/docs/guide/jni/spec/types.html>`_. An example: “(ILjava/lang/String;)[I” takes an integer and string as parameters and returns an array of integers. 

Cheat sheet: 

Z
   boolean
B
   byte
C
   char
S
   short
I
   int
J
   long
F
   float
D
   double
L
   class (e.g., Lmy/class;)
\[
   array of (e.g., [B = byte array)


The signatures are difficult, but you can cheat: the JDK has a
Java class file disassembler called ``javap`` that prints out the
signatures of everything in a class.


Operations on Java objects
--------------------------
.. autofunction:: javabridge.call
.. autofunction:: javabridge.make_call
.. autofunction:: javabridge.get_field
.. autofunction:: javabridge.set_field
.. autofunction:: javabridge.get_static_field
.. autofunction:: javabridge.static_call
.. autofunction:: javabridge.make_static_call
.. autofunction:: javabridge.is_instance_of
.. autofunction:: javabridge.make_instance
.. autofunction:: javabridge.set_static_field
.. autofunction:: javabridge.to_string
.. autofunction:: javabridge.get_nice_arg

Make Python objects that wrap Java objects
------------------------------------------
The functions ``make_new`` and ``make_method`` create Python methods that wrap Java constructors and methods, respectively. The function can be used to create Python wrapper classes for Java classes. Example::

    >>> class Integer:
            new_fn = javabridge.make_new("java/lang/Integer", "(I)V")
            def __init__(self, i):
                self.new_fn(i)
            intValue = javabridge.make_method("intValue", "()I", "Retrieve the integer value")
    >>> i = Integer(435)
    >>> i.intValue()
    435

.. autofunction:: javabridge.make_new
.. autofunction:: javabridge.make_method

Useful collection wrappers
--------------------------
.. autofunction:: javabridge.get_collection_wrapper
.. autofunction:: javabridge.get_dictionary_wrapper
.. autofunction:: javabridge.get_enumeration_wrapper
.. autofunction:: javabridge.jdictionary_to_string_dictionary
.. autofunction:: javabridge.jenumeration_to_string_list
.. autofunction:: javabridge.iterate_collection
.. autofunction:: javabridge.iterate_java
.. autofunction:: javabridge.make_list
.. autofunction:: javabridge.get_map_wrapper
.. autofunction:: javabridge.make_map

Reflection
----------
These functions make class wrappers suitable for introspection. These wrappers are examples of the kinds of wrappers that you can build yourself using ``make_method`` and ``make_new``.

.. autofunction:: javabridge.get_class_wrapper
.. autofunction:: javabridge.get_field_wrapper
.. autofunction:: javabridge.class_for_name
.. autofunction:: javabridge.get_constructor_wrapper
.. autofunction:: javabridge.get_method_wrapper

Executing in the correct thread
-------------------------------
Ensure that callables, runniables and futures that use AWT run in
the AWT main thread, which is not accessible from Python.

.. autofunction:: javabridge.make_future_task
.. autofunction:: javabridge.execute_runnable_in_main_thread
.. autofunction:: javabridge.execute_future_in_main_thread
.. autofunction:: javabridge.execute_callable_in_main_thread
.. autofunction:: javabridge.get_future_wrapper

Exceptions
----------

.. autoexception:: javabridge.JavaError
.. autoexception:: javabridge.JavaException
.. autoexception:: javabridge.JVMNotFoundError
