The low-level API
=================

This API wraps the Java Native Interface (JNI) at the lowest level. It
provides primitives for creating an environment and making calls on
it.

Java array objects are handled as numpy arrays.

In order to get the environment:

.. autofunction:: javabridge.get_env


.. autoclass:: javabridge.JB_Env
   :members:

.. autoclass:: javabridge.JB_Object
   :members:

