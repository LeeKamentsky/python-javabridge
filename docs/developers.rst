For Javabridge developers
=========================

Build from git repository
-------------------------

::

    git clone git@github.com:CellProfiler/python-javabridge.git
    cd python-javabridge
    cython *.pyx
    python setup.py build
    python setup.py install

Make source distribution and publish
------------------------------------

::

    git tag -a -m 'A commit message' '1.0.0pr11'
    git push --tags   # Not necessary, but you'll want to do it at some point
    git clean -fdx
    python setup.py develop
    python setup.py sdist upload
    python setup.py build_sphinx
    python setup.py upload_sphinx
