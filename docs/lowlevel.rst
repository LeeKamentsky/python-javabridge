The low-level API
=================

This API wraps the Java Native Interface (JNI) at the lowest level. It
provides primitives for creating an environment and making calls on
it.

Java array objects are handled as numpy arrays.

Each thread has its own environment. When you start a thread, you must attach
to the VM to get that thread's environment and access Java from that thread.
You must detach from the VM before the thread exits.

.. autofunction:noindex: javabridge.attach
.. autofunction:noindex: javabridge.detach

In order to get the environment:

.. autofunction:: javabridge.get_env

Examples::
    >>> env = get_env()
    >>> s = env.new_string(u"Hello, world.")
    >>> c = env.get_object_class(s)
    >>> method_id = env.get_method_id(c, "length", "()I")
    >>> method_id
    <Java method with sig=()I at 0xa0a4fd0>
    >>> result = env.call_method(s, method_id)
    >>> result
    13
    
.. autoclass:: javabridge.JB_Env

   .. automethod:: javabridge.JB_Env.get_version()
   
   .. line-block:: **Class discovery**
   
   .. automethod:: javabridge.JB_Env.find_class(name)
   .. automethod:: javabridge.JB_Env.get_object_class(o)
   .. automethod:: javabridge.JB_Env.is_instance_of(o, c)
   
   .. line-block:: **Calling Java object and class (static) methods:**
   
   .. automethod:: javabridge.JB_Env.get_method_id(c, name, sig)
   .. automethod:: javabridge.JB_Env.get_static_method_id(c, name, sig)
   .. automethod:: javabridge.JB_Env.from_reflected_method(method, sig, is_static)
   .. automethod:: javabridge.JB_Env.new_object(c, m, \*args)
   .. automethod:: javabridge.JB_Env.call_method(o, m, \*args)
   .. automethod:: javabridge.JB_Env.call_static_method(c, m, \*args)
   
   .. line-block:: **Accessing Java object and class (static) fields:**
   
   .. automethod:: javabridge.JB_Env.get_field_id(c, name, sig)
   .. automethod:: javabridge.JB_Env.get_static_field_id(c, name, sig)
   .. automethod:: javabridge.JB_Env.get_static_object_field
   .. automethod:: javabridge.JB_Env.get_static_boolean_field
   .. automethod:: javabridge.JB_Env.get_static_byte_field
   .. automethod:: javabridge.JB_Env.get_static_short_field
   .. automethod:: javabridge.JB_Env.get_static_int_field
   .. automethod:: javabridge.JB_Env.get_static_long_field
   .. automethod:: javabridge.JB_Env.get_static_float_field
   .. automethod:: javabridge.JB_Env.get_static_double_field
   .. automethod:: javabridge.JB_Env.set_static_object_field
   .. automethod:: javabridge.JB_Env.set_static_boolean_field
   .. automethod:: javabridge.JB_Env.set_static_byte_field
   .. automethod:: javabridge.JB_Env.set_static_short_field
   .. automethod:: javabridge.JB_Env.set_static_int_field
   .. automethod:: javabridge.JB_Env.set_static_long_field
   .. automethod:: javabridge.JB_Env.set_static_float_field
   .. automethod:: javabridge.JB_Env.set_static_double_field
   .. automethod:: javabridge.JB_Env.get_object_field
   .. automethod:: javabridge.JB_Env.get_boolean_field
   .. automethod:: javabridge.JB_Env.get_byte_field
   .. automethod:: javabridge.JB_Env.get_short_field
   .. automethod:: javabridge.JB_Env.get_int_field
   .. automethod:: javabridge.JB_Env.get_long_field
   .. automethod:: javabridge.JB_Env.get_float_field
   .. automethod:: javabridge.JB_Env.get_double_field
   .. automethod:: javabridge.JB_Env.set_object_field
   .. automethod:: javabridge.JB_Env.set_boolean_field
   .. automethod:: javabridge.JB_Env.set_byte_field
   .. automethod:: javabridge.JB_Env.set_char_field
   .. automethod:: javabridge.JB_Env.set_short_field
   .. automethod:: javabridge.JB_Env.set_long_field
   .. automethod:: javabridge.JB_Env.set_float_field
   .. automethod:: javabridge.JB_Env.set_double_field

   .. line-block:: **String functions**
   
   .. automethod:: javabridge.JB_Env.new_string(u)
   .. automethod:: javabridge.JB_Env.new_string_utf(s)
   .. automethod:: javabridge.JB_Env.get_string(s)
   .. automethod:: javabridge.JB_Env.get_string_utf(s)

   .. line-block:: **Array functions**   
   
   .. automethod:: javabridge.JB_Env.get_array_length(array)
   .. automethod:: javabridge.JB_Env.get_boolean_array_elements(array)
   .. automethod:: javabridge.JB_Env.get_byte_array_elements(array)
   .. automethod:: javabridge.JB_Env.get_short_array_elements(array)
   .. automethod:: javabridge.JB_Env.get_int_array_elements(array)
   .. automethod:: javabridge.JB_Env.get_long_array_elements(array)
   .. automethod:: javabridge.JB_Env.get_float_array_elements(array)
   .. automethod:: javabridge.JB_Env.get_double_array_elements(array)
   .. automethod:: javabridge.JB_Env.get_object_array_elements(array)
   .. automethod:: javabridge.JB_Env.make_boolean_array(array)
   .. automethod:: javabridge.JB_Env.make_byte_array(array)
   .. automethod:: javabridge.JB_Env.make_short_array(array)
   .. automethod:: javabridge.JB_Env.make_int_array(array)
   .. automethod:: javabridge.JB_Env.make_long_array(array)
   .. automethod:: javabridge.JB_Env.make_float_array(array)
   .. automethod:: javabridge.JB_Env.make_double_array(array)
   .. automethod:: javabridge.JB_Env.make_object_array(len, klass)
   .. automethod:: javabridge.JB_Env.set_object_array_element(jbo, index, v)

   .. line-block:: **Exception handling**
   
   .. automethod:: javabridge.JB_Env.exception_occurred()
   .. automethod:: javabridge.JB_Env.exception_describe()
   .. automethod:: javabridge.JB_Env.exception_clear()   
   
.. autoclass:: javabridge.JB_Object
   :members:
   
