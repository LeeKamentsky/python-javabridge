Installation and testing
========================

Install using pip
-----------------

::
   
    pip install numpy
    pip install javabridge


Install without pip
-------------------

::
   
    # Make sure numpy is installed
    python setup.py install


Dependencies
------------

The Javabridge requires Python 2.6 or above, NumPy, the Java
Development Kit (JDK), and a C compiler.

Linux
^^^^^

On CentOS 6, the dependencies can be installed as follows::

    yum install gcc numpy python-devel java-1.6.0-openjdk-devel
    curl -O https://raw.github.com/pypa/pip/master/contrib/get-pip.py
    python get-pip.py

On Fedora 19, the dependencies can be installed as follows::

    yum install gcc numpy python-devel java-1.7.0-openjdk-devel python-pip openssl

On Ubuntu 13 and Debian 7, the dependencies can be installed as follows::

   apt-get install openjdk-6-jdk python-pip python-numpy python-dev

On Ubuntu 14, the dependencies can be installed as follows::

   apt-get install openjdk-7-jdk python-pip python-numpy python-dev

On Arch Linux, the dependencies can be installed as follows::

   pacman -S jdk7-openjdk python2-pip python2-numpy base-devel

MacOS X
^^^^^^^

1. Install the Xcode command-line tools. There are two ways:

   A. Install Xcode from the Mac App Store. (You can also download it
      from Apple's Mac Dev Center, but that may require membership in
      the Apple Developer Program.) Install the Xcode command-line
      tools by starting Xcode, going to Preferences, click on
      "Downloads" in the toolbar, and click the "Install" button on
      the line "Command Line Tools." For MacOS 10.9 and Xcode 5 and
      above, you may have to install the command-line tools by typing
      ``xcode-select --install`` and following the prompts.

   B. Download the Xcode command-line tools from Apple's Mac Dev
      Center and install. This may require membership in the Apple
      Developer Program.

2. Create and activate a `virtualenv` virtual environment if you don't
   want to clutter up your system-wide python installation with new
   packages.

3. ``pip install numpy``

4. ``pip install javabridge``
   

Windows
^^^^^^^

If you do not have a C compiler installed, you can install Microsoft Visual C++ Build Tools to perform the compile steps. The compiler installation cab be found in https://visualstudio.microsoft.com/visual-cpp-build-tools/.

You should install a Java Development Kit (JDK) appropriate for your
Java project. The Windows build is tested with the Oracle JDK 1.7. You
also need to install the Java Runtime Environment (JRE).  Note that
the bitness needs to match your python: if you use a 32-bit Python,
then you need a 32-bit JDK; if you use a 64-bit Python, then you need
a 64-bit JDK.

The paths to PIP and Python should be in your PATH (``set
PATH=%PATH%;c:\\Python27;c:\\Python27\\scripts`` if Python and PIP
installed to the default locations). The following steps should
perform the install:

1. Run Command Prompt as administrator. Set the path to Python and PIP if needed.
    
2. Issue the command::
    
        pip install javabridge


Running the unit tests
----------------------

Running the unit tests requires Nose. Some of the tests require Python
2.7 or above.

1. Build and install in the source code tree so that the unit tests can run::

    python setup.py develop

2. Run the unit tests::

    nosetests

On Linux and MacOS X, the following should also work::

    python setup.py nosetests
    
You must build the extensions in-place on Windows, then run nosetests
if you use setup to run the tests::

    python setup.py build_ext -i
    python setup.py nosetests

See the section :ref:`unit-testing` for how to run unit tests for your
own projects that use Javabridge.


