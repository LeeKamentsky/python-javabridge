Unit testing
============

Unit testing of code that uses the Javabridge requires special care because the JVM can only be run once: after you kill it, it cannot be restarted. Therefore, the JVM cannot be started and stopped in the regular ``setUp()`` and ``tearDown()`` methods.

We provide a plugin to `Nose <https://nose.readthedocs.org/>`_ that
takes care of starting and stopping the JVM. The plugin's name is
``javabridge.noseplugin``. Installing the Javabridge adds the plugin
to Nose.

To use the plugin for your own project, in the ``[nosetests]`` section
to your ``setup.cfg``, add ``with-javabridge = True``. You can also
specify a classpath; the jar files required for javabridge to function
(:py:data:javabridge.JARS) will be added to this path::

    [nosetests]
    with-javabridge = True
    classpath = my-project/jars/foo.jar

You should then be able to run setuptools's nosetests command::

    python setup.py nosetests
