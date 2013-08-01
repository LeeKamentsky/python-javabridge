Executing JavaScript on the JVM
===============================

As you will see in subsequent sections, navigating and manipulating
the JVM's class and object structure can result in verbose and
cumbersome Python code. Therefore, Javabridge ships with the
JavaScript interpreter Rhino, which runs on the JVM. In many cases,
the most convienient way to interact with the JVM is to execute a
piece of JavaScript.

.. autofunction:: javabridge.run_script

Examples:

    >>> javabridge.run_script("2 + 2")
    4

    >>> javabridge.run_script("a + b", bindings_in={"a": 2, "b": 3})
    5

    >>> outputs = {"result": None}
    >>> javabridge.run_script("var result = 2 + 2;", bindings_out=outputs)
    >>> outputs["result"]
    4

TODO: Strings, numbers, etc converted; other things not.
