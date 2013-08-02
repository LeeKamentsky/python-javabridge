.. -*- visual-line-mode -*-

Unit testing
============

Unit testing of code that uses the Javabridge requires special care because the JVM can only be run once: after you kill it, it cannot be restarted. Therefore, the JVM cannot be started and stopped in the regular ``setUp()`` and ``tearDown()`` methods.

We provide a plugin to `Nose <https://nose.readthedocs.org/>`_ that takes care of starting and stopping the JVM. The plugin's name is ``javabridge.noseplugin``. To use it with `setuptools <https://pypi.python.org/pypi/setuptools>`_, pass it as an entry point to ``setup()``::

    from setuptools import setup
    
    setup(name='my-project',
          ...
          tests_require='nose',
          entry_points={'nose.plugins.0.10': [
                  'javabridge = javabridge.noseplugin:JavabridgePlugin',
                  ]},
          test_suite='nose.collector')


