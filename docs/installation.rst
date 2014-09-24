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

On Ubuntu 13.10 and Debian 7.0, the dependencies can be installed as follows::

   apt-get install openjdk-6-jdk python-pip python-numpy python-dev

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

If you do not have a C compiler installed, you can install the Windows SDK 7.1
and .Net Framework 4.0 to perform the compile steps. You should install
a JDK appropriate for your Java project - the Windows build is tested with
the Oracle JDK v 1.7. The paths to PIP and Python should be in your PATH 
(``set PATH=%PATH%;c:\\Python27;c:\\Python27\\scripts`` if Python and PIP installed
to the default locations). The following steps should perform the install:

    Open a Windows SDK command prompt (found in the Start menu under 
    Microsoft Windows SDK). Set the path to Python and PIP if needed.
    
    Issue the commands::
    
        set MSSdk=1
        set DISTUTILS_USE_SDK=1
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

See the section :ref:`unit-testing` for how to run unit tests for your
own projects that use Javabridge.


