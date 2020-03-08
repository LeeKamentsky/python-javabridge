"""setup.py - build python-javabridge

python-javabridge is licensed under the BSD license.  See the
accompanying file LICENSE for details.

Copyright (c) 2003-2009 Massachusetts Institute of Technology
Copyright (c) 2009-2013 Broad Institute
All rights reserved.

"""
from __future__ import print_function

import errno
import glob
import os
import re
import sys
try:
    import sysconfig
except:
    import distutils.sysconfig as sysconfig
import subprocess
import traceback
import distutils.log
from distutils.errors import DistutilsSetupError, DistutilsExecError, LinkError
from setuptools import setup, Extension
from setuptools.command.build_ext import build_ext as _build_ext
from distutils.command.build_clib import build_clib
from distutils.ccompiler import CCompiler


# Hack to avoid importing the javabridge package
sys.path.append(os.path.join(os.path.dirname(__file__), 'javabridge'))
from locate import *

def in_cwd(basename):
    return os.path.join(os.path.dirname(__file__), basename)

def build_cython():
    """Compile the pyx files if we have them.

    The git repository has the .pyx files but not the .c files, and
    the source distributions that are uploaded to PyPI have the .c
    files and not the .pyx files. (The reason for the latter is that
    some versions of pip discovers the .pyx files and implicitly adds
    a dependency on Cython.) Therefore, if we have the .pyx files,
    compile them.

    """
    stems = ['_javabridge', '_javabridge_mac', '_javabridge_nomac']
    pyx_filenames = [in_cwd(s + '.pyx') for s in stems]
    c_filenames = [in_cwd(s + '.c') for s in stems]
    nc_pyx_filenames = [
        pyx for pyx, c in zip(pyx_filenames, c_filenames)
        if os.path.exists(pyx) and needs_compilation(c, pyx)]
    if len(nc_pyx_filenames) > 0:
        cython_cmd = [sys.executable, '-m', 'cython', "-3"]
        cmd = cython_cmd + nc_pyx_filenames
        env = dict(os.environ)
        env['PYTHONPATH'] = os.pathsep.join(sys.path)
        try:
            subprocess.check_call(cmd, env=env)
        except FileNotFoundError:
            raise RuntimeError("Failed to find Cython: {}".format(cython_cmd))

def get_jvm_include_dirs():
    '''Return a sequence of paths to include directories for JVM defs'''
    jdk_home = find_jdk()
    java_home = find_javahome()
    include_dirs = []
    if is_win:
        if jdk_home is not None:
            jdk_include = os.path.join(jdk_home, "include")
            jdk_include_plat = os.path.join(jdk_include, sys.platform)
            include_dirs += [jdk_include, jdk_include_plat]
    elif is_mac:
        where_jni_h_is_post_6 = os.path.join(java_home, 'include')
        if os.path.isfile(os.path.join(where_jni_h_is_post_6, "jni.h")):

            include_dirs += [where_jni_h_is_post_6,
                             os.path.join(java_home, 'include', 'darwin')]
        else:
            include_dirs += ["/System/Library/Frameworks/JavaVM.Framework/Headers"]
    elif is_linux:
        include_dirs += [os.path.join(jdk_home,'include'),
                         os.path.join(jdk_home,'include','linux'),
                         os.path.join(jdk_home,'default-java','include'),
                         os.path.join(jdk_home,'default-java','include','linux')
                         ]

    return include_dirs

def ext_modules():
    extensions = []
    extra_link_args = None
    java_home = find_javahome()
    if java_home is None:
        raise Exception("JVM not found")
    jdk_home = find_jdk()
    include_dirs = get_jvm_include_dirs()
    libraries = None
    library_dirs = None
    javabridge_sources = ['_javabridge.c']
    _, jvm_so = find_jre_bin_jdk_so()
    if is_mac:
        javabridge_sources += ['_javabridge_mac.c']
        extra_link_args = ['-framework', 'CoreFoundation']
    else:
        javabridge_sources += ['_javabridge_nomac.c']
    if is_win:
        jdk_lib = os.path.join(jdk_home, "lib")
        if is_mingw:
            #
            # Build libjvm from jvm.dll on Windows.
            # This assumes that we're using mingw32 for build
            #
	    # generate the jvm.def file matching to the jvm.dll
            cmd = ["gendef", os.path.join(jdk_home,"jre\\bin\\server\\jvm.dll")]
            p = subprocess.Popen(cmd)
            p.communicate()
            cmd = ["dlltool", "--dllname",
                   jvm_so,
                   "--output-lib","libjvm.a",
                   "--input-def","jvm.def",
                   "--kill-at"]
            p = subprocess.Popen(cmd)
            p.communicate()
            library_dirs = [os.path.abspath("."), jdk_lib]
        else:
            #
            # Use the MSVC lib in the JDK
            #
            extra_link_args = ['/MANIFEST']
            library_dirs = [jdk_lib]
            javabridge_sources.append("strtoull.c")

        libraries = ["jvm"]
    elif is_mac:
        javabridge_sources += [ "mac_javabridge_utils.c" ]
    elif is_linux:
        library_dirs = [os.path.dirname(jvm_so)]
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

    extensions += [Extension(**extension_kwargs)]
    return extensions

SO = ".dll" if sys.platform == 'win32' \
    else ".jnilib" if sys.platform == 'darwin'\
    else ".so"

def needs_compilation(target, *sources):
    try:
        target_date = os.path.getmtime(target)
    except OSError as e:
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

class build_ext(_build_ext):
    java2cpython_sources = ["java/org_cellprofiler_javabridge_CPython.c"]

    def initialize_options(self):
        from numpy import get_include
        _build_ext.initialize_options(self)
        if self.include_dirs is None:
            self.include_dirs = get_include()
        else:
            self.include_dirs += get_include()

    def run(self, *args, **kwargs):
        self.build_java()
        result = build_cython()
        if self.inplace:
            dirty = False
            for source in self.get_source_files():
                source_mtime = os.stat(source).st_mtime
                for output in self.get_outputs():
                    if not os.path.isfile(output) or \
                       os.stat(output).st_mtime < source_mtime:
                        dirty = True
                        break
            output_dir = os.path.splitext(
                self.get_ext_fullpath("javabridge.jars"))[0]
            java2cpython_lib = os.path.join(
                output_dir, self.get_java2cpython_libdest()[1])
            if (not os.path.exists(java2cpython_lib)) or \
               any([os.stat(src).st_mtime > os.stat(java2cpython_lib).st_mtime
                    for src in self.java2cpython_sources]):
                dirty = True
        else:
            dirty = True
        if dirty:
            result = _build_ext.run(self, *args, **kwargs)
            self.build_java2cpython()
        return result

    def build_jar_from_sources(self, jar, sources):
        if sys.platform == 'win32':
            sources = [source.replace("/", os.path.sep) for source in sources]
        jar_filename = jar.rsplit(".", 1)[1] + ".jar"
        jar_dir = os.path.dirname(self.get_ext_fullpath(jar))
        jar = os.path.join(jar_dir, jar_filename)
        jar_command = [find_jar_cmd(), 'cf', package_path(jar)]

        javac_loc = find_javac_cmd()
        dirty_jar = False
        javac_command = [javac_loc]
        for source in sources:
            javac_command.append(package_path(source))
            if needs_compilation(jar, source):
                dirty_jar = True

        self.spawn(javac_command)
        if dirty_jar:
            if not os.path.exists(os.path.dirname(jar)):
                os.mkdir(os.path.dirname(jar))
            for source in sources:
                for klass in glob.glob(source[:source.rindex('.')] + '*.class'):
                    java_klass_path = klass[klass.index(os.path.sep) + 1:].replace(os.path.sep, "/")
                    jar_command.extend(['-C', package_path('java'), java_klass_path])
            self.spawn(jar_command)

    def build_java2cpython(self):
        sources = self.java2cpython_sources
        distutils.log.info("building java2cpython library")


        # First, compile the source code to object files in the library
        # directory.  (This should probably change to putting object
        # files in a temporary build directory.)
        include_dirs = \
            [sysconfig.get_config_var("INCLUDEPY"), "java"] +\
            get_jvm_include_dirs()
        python_lib_dir, lib_name = self.get_java2cpython_libdest()
        library_dirs = [python_lib_dir]
        output_dir = os.path.join(os.path.dirname(
            self.get_ext_fullpath("javabridge.jars")), "jars")
        export_symbols = ['Java_org_cellprofiler_javabridge_CPython_exec']
        objects = self.compiler.compile(sources,
                                        output_dir=self.build_temp,
                                        include_dirs=include_dirs,
                                        debug=self.debug)
        ver = sys.version_info
        needs_manifest = sys.platform == 'win32' and ver.major == 2 and not is_mingw
        extra_postargs = ["/MANIFEST"] if needs_manifest else None
        libraries = ["python{}{}".format(ver.major, ver.minor)] if is_mingw else None
        self.compiler.link(
            CCompiler.SHARED_OBJECT,
            objects, lib_name,
            output_dir=output_dir,
            debug=self.debug,
            library_dirs=library_dirs,
	    libraries=libraries,
            export_symbols=export_symbols,
            extra_postargs=extra_postargs)
        if needs_manifest:
            temp_dir = os.path.dirname(objects[0])
            manifest_name = lib_name +".manifest"
            lib_path = os.path.join(output_dir, lib_name)
            manifest_file = os.path.join(temp_dir, manifest_name)
            lib_path = os.path.abspath(lib_path)
            manifest_file = os.path.abspath(manifest_file)
            out_arg = '-outputresource:%s;2' % lib_path
            try:
                self.compiler.spawn([
                    'mt.exe', '-nologo', '-manifest', manifest_file,
                    out_arg])
            except DistutilsExecError as msg:
                raise LinkError(msg)

    def get_java2cpython_libdest(self):
        if is_win:
            python_lib_dir = os.path.join(
                sysconfig.get_config_var('platbase'),
                'LIBS')
            lib_name = "java2cpython" + SO
        else:
            python_lib_dir = sysconfig.get_config_var('LIBDIR')
            lib_name = "libjava2cpython" + SO
        return python_lib_dir, lib_name


    def build_jar_from_single_source(self, jar, source):
        self.build_jar_from_sources(jar, [source])

    def build_runnablequeue(self):
        jar = 'javabridge.jars.runnablequeue'
        source = 'java/org/cellprofiler/runnablequeue/RunnableQueue.java'
        self.build_jar_from_single_source(jar, source)

    def build_cpython(self):
        jar = 'javabridge.jars.cpython'
        sources = [
            'java/org/cellprofiler/javabridge/CPython.java',
            'java/org/cellprofiler/javabridge/CPythonInvocationHandler.java']
        self.build_jar_from_sources(jar, sources)

    def build_test(self):
        jar = 'javabridge.jars.test'
        source = 'java/org/cellprofiler/javabridge/test/RealRect.java'
        self.build_jar_from_single_source(jar, source)

    def build_java(self):
        self.build_runnablequeue()
        self.build_test()
        self.build_cpython()


def pep440_compliant(ver):
    if ver is None:
        return ver
    m = re.match(r"^(?P<version>(\d[\d\.]*))$", ver)
    if m:
        return ver
    m = re.match(r"^(?P<version>(\d[\d\.]*))-(?P<count>\d+)-(?P<sha>.*)$", ver)
    if m:
        res = m.group('version') + '.post' + m.group('count') + '+' + m.group('sha')
        return res
    return ver


def get_version():
    """Get version from git or file system.

    If this is a git repository, try to get the version number by
    running ``git describe``, then store it in
    javabridge/_version.py. Otherwise, try to load the version number
    from that file. If both methods fail, quietly return None.

    """
    git_version = None
    if os.path.exists(os.path.join(os.path.dirname(__file__), '.git')):
        import subprocess
        try:
            git_version = subprocess.Popen(['git', 'describe'],
                                           stdout=subprocess.PIPE).communicate()[0].strip().decode('utf-8')
        except:
            pass

    version_file = os.path.join(os.path.dirname(__file__), 'javabridge',
                                '_version.py')
    if os.path.exists(version_file):
        with open(version_file) as f:
            cached_version_line = f.read().strip()
        try:
            # From http://stackoverflow.com/a/3619714/17498
            cached_version = re.search(r"^__version__ = ['\"]([^'\"]*)['\"]",
                                       cached_version_line, re.M).group(1)
        except:
            raise RuntimeError("Unable to find version in %s" % version_file)
    else:
        cached_version = None

    if git_version and git_version != cached_version:
        with open(version_file, 'w') as f:
            print('__version__ = "%s"' % git_version, file=f)

    return pep440_compliant(git_version or cached_version)


if __name__ == '__main__':
    if '/' in __file__:
        os.chdir(os.path.dirname(__file__))

    setup(name="javabridge",
          version=get_version(),
          description="Python wrapper for the Java Native Interface",
          long_description='''The python-javabridge package makes it easy to start a Java virtual
machine (JVM) from Python and interact with it. Python code can
interact with the JVM using a low-level API or a more convenient
high-level API. Python-javabridge was developed for and is used by the
cell image analysis software CellProfiler (cellprofiler.org).''',
          url="http://github.com/CellProfiler/python-javabridge/",
          packages=['javabridge', 'javabridge.tests'],
          classifiers=['Development Status :: 5 - Production/Stable',
                       'License :: OSI Approved :: BSD License',
                       'Programming Language :: Java',
                       'Programming Language :: Python :: 2',
                       'Programming Language :: Python :: 3'
                       ],
          license='BSD License',
          setup_requires=['cython', 'numpy'],
          install_requires=['numpy'],
          tests_require="nose",
          entry_points={'nose.plugins.0.10': [
                'javabridge = javabridge.noseplugin:JavabridgePlugin'
                ]},
          test_suite="nose.collector",
          ext_modules=ext_modules(),
          package_data={"javabridge": [
              'jars/*.jar', 'jars/*%s' % SO, 'VERSION']},
          cmdclass={'build_ext': build_ext})
