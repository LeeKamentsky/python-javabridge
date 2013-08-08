Unit testing
============

Unit testing of code that uses the Javabridge requires special care because the JVM can only be run once: after you kill it, it cannot be restarted. Therefore, the JVM cannot be started and stopped in the regular ``setUp()`` and ``tearDown()`` methods.

We provide a plugin to `Nose <https://nose.readthedocs.org/>`_ that takes care of starting and stopping the JVM. The plugin's name is ``javabridge.noseplugin``. To use it with `setuptools <https://pypi.python.org/pypi/setuptools>`_, pass it as an entry point to ``setup()`` in your ``setup.py``::

    from setuptools import setup
    
    setup(name='my-project',
          ...
          tests_require='nose',
          entry_points={'nose.plugins.0.10': [
                  'javabridge = javabridge.noseplugin:JavabridgePlugin',
                  ]},
          test_suite='nose.collector')

In the ``[nosetests]`` section of your ``setup.cfg``, add ``with-javabridge = True``. You can also specify a classpath; the jar files required for javabridge to function (:py:data:javabridge.JARS) will be added to this path::

    [nosetests]
    with-javabridge = True
    classpath = my-project/jars/foo.jar
