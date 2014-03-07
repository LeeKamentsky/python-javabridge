"""setup.py - build python-javabridge

python-javabridge is licensed under the BSD license.  See the
accompanying file LICENSE for details.

Copyright (c) 2003-2009 Massachusetts Institute of Technology
Copyright (c) 2009-2013 Broad Institute
All rights reserved.

"""

import errno
import glob
import logging
import os
import sys
import subprocess
import traceback
from distutils.core import setup, Extension
from numpy import get_include
from distutils.command.build_ext import build_ext as _build_ext
from Cython.Build import cythonize

sys.path.append(os.path.join(os.path.dirname(__file__), 'javabridge'))
from locate import *

logger = logging.getLogger(__name__)


class JavaNotFoundException(Exception):
    def __init__(self):
        super(JavaNotFoundException, self).__init__("Cannot find Java.")


def ext_modules():
    extensions = []
    extra_link_args = None
    if is_win:
        extra_link_args = ['/MANIFEST']
    java_home = find_javahome()
    if java_home is None:
        raise JavaNotFoundException()
    jdk_home = find_jdk()
    logger.debug("Using jdk_home = %s" % jdk_home)
    include_dirs = [get_include()]
    libraries = None
    library_dirs = None
    javabridge_sources = [ "_javabridge.pyx" ]
    if is_win:
        if jdk_home is not None:
            jdk_include = os.path.join(jdk_home, "include")
            jdk_include_plat = os.path.join(jdk_include, sys.platform)
            include_dirs += [jdk_include, jdk_include_plat]
        if is_mingw:
            #
            # Build libjvm from jvm.dll on Windows.
            # This assumes that we're using mingw32 for build
            #
            cmd = ["dlltool", "--dllname", 
                   os.path.join(jdk_home,"jre\\bin\\client\\jvm.dll"),
                   "--output-lib","libjvm.a",
                   "--input-def","jvm.def",
                   "--kill-at"]
            p = subprocess.Popen(cmd)
            p.communicate()
            library_dirs = [os.path.abspath(".")]
        else:
            #
            # Use the MSVC lib in the JDK
            #
            jdk_lib = os.path.join(jdk_home, "lib")
            library_dirs = [jdk_lib]
            javabridge_sources.append("strtoull.c")

        libraries = ["jvm"]
    elif sys.platform == 'darwin':
        javabridge_sources += [ "mac_javabridge_utils.c" ]
        include_dirs += ['/System/Library/Frameworks/JavaVM.framework/Headers']
        extra_link_args = ['-framework', 'JavaVM']
    elif is_linux:
        include_dirs += [os.path.join(java_home,'include'),
                         os.path.join(java_home,'include','linux')]
        library_dirs = [os.path.join(java_home,'jre','lib', arch, cs)
                        for arch in ['amd64', 'i386']
                        for cs in ['client', 'server']]
        libraries = ["jvm"]
    extension_kwargs = dict(
        name="javabridge._javabridge",
        sources=javabridge_sources,
        libraries=libraries,
        library_dirs=library_dirs,
        include_dirs=include_dirs,
        extra_link_args=extra_link_args)
    if not is_win:
        extension_kwargs["runtime_library_dirs"] =library_dirs

    extensions += cythonize([Extension(**extension_kwargs)])
    return extensions

def needs_compilation(target, *sources):
    try:
        target_date = os.path.getmtime(target)
    except OSError, e:
        if e.errno != errno.ENOENT:
            raise
        return True
    for source in sources:
        source_date = os.path.getmtime(source)
        if source_date > target_date:
            return True
    return False

def package_path(relpath):
    return os.path.normpath(os.path.join(os.path.dirname(__file__), relpath))

def build_jar_from_single_source(jar, source):
    if needs_compilation(jar, source):
        javac_loc = find_javac_cmd()
        javac_command = [javac_loc, package_path(source)]
        print ' '.join(javac_command)
        subprocess.check_call(javac_command)
        if not os.path.exists(os.path.dirname(jar)):
            os.mkdir(os.path.dirname(jar))
        jar_command = [find_jar_cmd(), 'cf', package_path(jar)]
        for klass in glob.glob(source[:source.rindex('.')] + '*.class'):
            jar_command.extend(['-C', package_path('java'), klass[klass.index('/') + 1:]])
        print ' '.join(jar_command)
        subprocess.check_call(jar_command)

def build_runnablequeue():
    jar = 'javabridge/jars/runnablequeue.jar'
    source = 'java/org/cellprofiler/runnablequeue/RunnableQueue.java'
    build_jar_from_single_source(jar, source)

def build_findlibjvm():
    jar = 'javabridge/jars/findlibjvm.jar'
    source = 'java/org/cellprofiler/findlibjvm.java'
    build_jar_from_single_source(jar, source)

def build_test():
    jar = 'javabridge/jars/test.jar'
    source = 'java/org/cellprofiler/javabridge/test/RealRect.java'
    build_jar_from_single_source(jar, source)

def build_java():
    print "running build_java"
    build_runnablequeue()
    build_findlibjvm()
    build_test()

class build_ext(_build_ext):
    def run(self, *args, **kwargs):
        build_java()
        return _build_ext.run(self, *args, **kwargs)


if __name__ == '__main__':
    if '/' in __file__:
        os.chdir(os.path.dirname(__file__))

    setup(name="javabridge",
          version='1.0.0pr6',
          description="Python wrapper for the Java Native Interface",
          long_description='''The python-javabridge package makes it easy to start a Java virtual
machine (JVM) from Python and interact with it. Python code can
interact with the JVM using a low-level API or a more convenient
high-level API. Python-javabridge was developed for and is used by the
cell image analysis software CellProfiler (cellprofiler.org).''',
          url="http://github.com/CellProfiler/python-javabridge/",
          packages=['javabridge'],
          classifiers=['Development Status :: 5 - Production/Stable',
                       'License :: OSI Approved :: BSD License',
                       'Programming Language :: Java',
                       ],
          license='BSD License',
          install_requires=['numpy', 'Cython', 'Pyrex'],
          package_data={"javabridge": ['jars/*.jar']},
          ext_modules=ext_modules(),
          cmdclass={'build_ext': build_ext,})
    

