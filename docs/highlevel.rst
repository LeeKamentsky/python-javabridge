.. -*- visual-line-mode -*-

High-level API
===============

This API is high level only in comparison to :doc:`the low-level API<lowlevel>`: the resulting code can still be cumbersome and verbose because of the need to handle signatures when navigating the JVM's object structure. It is often more convenient to interact with a piece of :doc:`JavaScript running on the JVM<javascript>`.

Operations on Java objects
--------------------------
.. autofunction:: javabridge.call
.. autofunction:: javabridge.get_static_field
.. autofunction:: javabridge.static_call
.. autofunction:: javabridge.is_instance_of
.. autofunction:: javabridge.make_instance
.. autofunction:: javabridge.set_static_field
.. autofunction:: javabridge.to_string

Make Python objects that wrap Java objects
------------------------------------------
.. autofunction:: javabridge.make_method
.. autofunction:: javabridge.make_new

Useful collection wrappers
--------------------------
.. autofunction:: javabridge.get_dictionary_wrapper
.. autofunction:: javabridge.jdictionary_to_string_dictionary
.. autofunction:: javabridge.jenumeration_to_string_list
.. autofunction:: javabridge.get_enumeration_wrapper
.. autofunction:: javabridge.iterate_collection
.. autofunction:: javabridge.iterate_java

Reflection
----------
These functions make use of ``make_method`` or ``make_new`` internally.

.. autofunction:: javabridge.get_class_wrapper
.. autofunction:: javabridge.get_field_wrapper
.. autofunction:: javabridge.class_for_name
.. autofunction:: javabridge.get_constructor_wrapper
.. autofunction:: javabridge.get_method_wrapper
.. autofunction:: javabridge.get_modifier_flags

Executing in the correct thread
-------------------------------
Ensure that callables, runniables and futures that use AWT run in
the AWT main thread, which is not accessible from Python.

.. autofunction:: javabridge.execute_runnable_in_main_thread
.. autofunction:: javabridge.execute_future_in_main_thread
.. autofunction:: javabridge.execute_callable_in_main_thread
.. autofunction:: javabridge.run_in_main_thread

Exceptions
----------

.. autoexception:: javabridge.JavaError
.. autoexception:: javabridge.JavaException

