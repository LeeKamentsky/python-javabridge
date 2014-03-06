Executing JavaScript on the JVM
===============================

As you will see in subsequent sections, navigating and manipulating
the JVM's class and object structure can result in verbose and
cumbersome Python code. Therefore, Javabridge ships with the
JavaScript interpreter Rhino, which runs on the JVM. In many cases,
the most convienient way to interact with the JVM is to execute a
piece of JavaScript.

.. autofunction:: javabridge.run_script

For more information on using Rhino with the JVM see
https://developer.mozilla.org/en-US/docs/Rhino/Scripting_Java

Examples:

    >>> javabridge.run_script("2 + 2")
    4

    >>> javabridge.run_script("a + b", bindings_in={"a": 2, "b": 3})
    5

    >>> outputs = {"result": None}
    >>> javabridge.run_script("var result = 2 + 2;", bindings_out=outputs)
    >>> outputs["result"]
    4
    
    >>> javabridge.run_script("java.lang.Math.abs(v)", bindings_in=dict(v=-1.5))
    1.5

A conversion is necessary when converting from Python primitives and objects
to Java and JavaScript primitives and objects. Python primitives are boxed into
Java objects - Javascript will automatically unbox them when calling a
method that takes primitive arguments (e.g. the call to Math.abs(double) as
in the above example. The following is a table
of bidirectional translations from Python to Java / Javascript and vice-versa:

+-------------------------+------------------------+----------------------+
| Python                  | Java - boxed           | Java-primitive       |
+=========================+========================+======================+
| bool                    | java.lang.Boolean      | boolean              |
+-------------------------+------------------------+----------------------+
| int                     | java.lang.Integer      | int                  |
+-------------------------+------------------------+----------------------+
| long                    | java.lang.Long         | long                 |
+-------------------------+------------------------+----------------------+
| float                   | java.lang.Double       | double               |
+-------------------------+------------------------+----------------------+
| unicode                 | java.lang.String       | N/A                  |
+-------------------------+------------------------+----------------------+
| str (Python->java only) | java.lang.String       | N/A                  |
+-------------------------+------------------------+----------------------+
| None                    | null                   | N/A                  |
+-------------------------+------------------------+----------------------+
