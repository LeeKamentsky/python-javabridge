Installation and testing
========================

Install using pip
-----------------

    pip install javabridge


Install without pip
-------------------

    python setup.py install


Dependencies
------------

The Javabridge requires Python 2.6 or above, Numpy, the Java
Development Kit (JDK), and a C compiler.

On CentOS 6, the dependencies can be installed as follows::

    yum install gcc numpy python-devel java-1.6.0-openjdk-devel
    curl -O https://raw.github.com/pypa/pip/master/contrib/get-pip.py
    python get-pip.py

On Fedora 19, the dependencies can be installed as follows::

    yum install gcc numpy python-devel java-1.7.0-openjdk-devel python-pip openssl

On Ubuntu 13.10 and Debian 7.0, the dependencies can be installed as follows::

   apt-get install openjdk-6-jdk python-pip python-numpy python-dev




Running the unit tests
----------------------

Running the unit tests requires Nose. Some of the tests require Python
2.7 or above.

1. Build and install in the source code tree so that the unit tests can run::

    python setup.py build_ext --inplace

2. Run the unit tests::

    nosetests

On some installations, the following will also work::

    python setup.py nosetests




