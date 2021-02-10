"""locate.py - determine architecture and find Java

python-javabridge is licensed under the BSD license.  See the
accompanying file LICENSE for details.

Copyright (c) 2003-2009 Massachusetts Institute of Technology
Copyright (c) 2009-2013 Broad Institute
All rights reserved.lo

"""

import ctypes
import os
import sys
import logging
import subprocess
import re

# Note: if a matching gcc is available from the shell on Windows, its
#       probably safe to assume the user is in an MINGW or MSYS or Cygwin
#       environment, in which case he/she wants to compile with gcc for
#       Windows, in which case the correct compiler flags will be triggered
#       by is_mingw. This method is not great, improve it if you know a
#       better way to discriminate between compilers on Windows.
def is_mingw():
    # currently this check detects mingw only on Windows. Extend for other
    # platforms if required:
    if (os.name != "nt"):
        return False

    # if the user defines DISTUTILS_USE_SDK or MSSdk, we expect they want
    # to use Microsoft's compiler (as described here:
    # https://github.com/cython/cython/wiki/CythonExtensionsOnWindows):
    if (os.getenv("DISTUTILS_USE_SDK") != None or os.getenv("MSSdk") != None):
        return False

    mingw32 = ""
    mingw64 = ""
    if (os.getenv("MINGW32_PREFIX")):
        mingw32 = os.getenv("MINGW32_PREFIX")
    if (os.getenv("MINGW64_PREFIX")):
        mingw64 = os.getenv("MINGW64_PREFIX")

    # if any invocation of gcc works, then we assume the user wants mingw:
    test = "gcc --version > NUL 2>&1"
    if (os.system(test) == 0 or os.system(mingw32+test) == 0 or os.system(mingw64+test) == 0):
        return True

    return False



is_linux = sys.platform.startswith('linux')
is_mac = sys.platform == 'darwin'
is_win = sys.platform.startswith("win")
is_win64 = (is_win and (os.environ["PROCESSOR_ARCHITECTURE"] == "AMD64"))
is_msvc = (is_win and
           ((sys.version_info.major == 2 and sys.version_info.minor >= 6) or
            (sys.version_info.major == 3)))
is_mingw = is_mingw()

if is_win:
    if sys.version_info.major == 2:
        import _winreg as winreg
        from exceptions import WindowsError
    else:
        import winreg

logger = logging.getLogger(__name__)

def find_javahome():
    """Find JAVA_HOME if it doesn't exist"""
    if is_win and hasattr(sys, "frozen"):
        # If we're frozen we probably have a packaged java environment.
        app_path = os.path.dirname(sys.executable)
        java_path = os.path.join(app_path, 'java')
        if os.path.exists(java_path):
            return java_path
        else:
            # Can use env from CP_JAVA_HOME or JAVA_HOME by removing the CellProfiler/java folder.
            print("Packaged java environment not found, searching for java elsewhere.")
    if 'CP_JAVA_HOME' in os.environ:
        # Prefer CellProfiler's JAVA_HOME if it's set.
        return os.environ['CP_JAVA_HOME']
    elif 'JAVA_HOME' in os.environ:
        return os.environ['JAVA_HOME']
    elif is_mac:
        # Use the "java_home" executable to find the location
        # see "man java_home"
        libc = ctypes.CDLL("/usr/lib/libc.dylib")
        if sys.maxsize <= 2**32:
            arch = "i386"
        else:
            arch = "x86_64"
        try:
            result = subprocess.check_output(["/usr/libexec/java_home", "--arch", arch])
            path = result.strip().decode("utf-8")
            for place_to_look in (
                os.path.join(os.path.dirname(path), "Libraries"),
                os.path.join(path, "jre", "lib", "server")):
                # In "Java for OS X 2015-001" libjvm.dylib is a symlink to libclient.dylib
                # which is i686 only, whereas libserver.dylib contains both architectures.
                for file_to_look in ('libjvm.dylib',
                                     'libclient.dylib',
                                     'libserver.dylib'):
                    lib = os.path.join(place_to_look, file_to_look)
                    #
                    # dlopen_preflight checks to make sure the dylib
                    # can be loaded in the current architecture
                    #
                    if os.path.exists(lib) and \
                       libc.dlopen_preflight(lib.encode('utf-8')) != 0:
                        return path
            else:
                logger.error("Could not find Java JRE compatible with %s architecture" % arch)
                if arch == "i386":
                    logger.error(
                        "Please visit https://support.apple.com/kb/DL1572 for help\n"
                        "installing Apple legacy Java 1.6 for 32 bit support.")
                return None
        except:
            logger.error("Failed to run /usr/libexec/java_home, defaulting to best guess for Java", exc_info=1)
        return "/System/Library/Frameworks/JavaVM.framework/Home"
    elif is_linux:
        def get_out(cmd):
            p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
            o, ignore = p.communicate()
            if p.poll() != 0:
                raise Exception("Error finding javahome on linux: %s" % cmd)
            o = o.strip().decode('utf-8')
            return o
        java_bin = get_out(["bash", "-c", "type -p java"])
        java_dir = get_out(["readlink", "-f", java_bin])
        java_version_string = get_out(["bash", "-c", "java -version"])
        if re.search('^openjdk', java_version_string, re.MULTILINE) is not None:
            jdk_dir = os.path.join(java_dir, "..", "..", "..")
        elif re.search('^java', java_version_string, re.MULTILINE) is not None:
            jdk_dir = os.path.join(java_dir, "..", "..")
        else:
            raise RuntimeError(
                "Failed to determine JDK vendor. "
                "OpenJDK and Oracle JDK are supported."
            )
        jdk_dir = os.path.abspath(jdk_dir)
        return jdk_dir
    elif is_win:
        # Registry keys changed in 1.9
        # https://docs.oracle.com/javase/9/migrate/toc.htm#GUID-EEED398E-AE37-4D12-AB10-49F82F720027
        java_key_paths = (
            'SOFTWARE\\JavaSoft\\JRE',
            'SOFTWARE\\JavaSoft\\Java Runtime Environment',
            'SOFTWARE\\JavaSoft\\JDK'
        )
        for java_key_path in java_key_paths:
            looking_for = java_key_path
            try:
                kjava = winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, java_key_path)
                looking_for = java_key_path + "\\CurrentVersion"
                kjava_values = dict([winreg.EnumValue(kjava, i)[:2]
                                     for i in range(winreg.QueryInfoKey(kjava)[1])])
                current_version = kjava_values['CurrentVersion']
                looking_for = java_key_path + '\\' + current_version
                kjava_current = winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE,
                                                looking_for)
                kjava_current_values = dict([winreg.EnumValue(kjava_current, i)[:2]
                                             for i in range(winreg.QueryInfoKey(kjava_current)[1])])
                return kjava_current_values['JavaHome']
            except WindowsError as e:
                if e.errno == 2:
                    continue
                else:
                    raise
        if hasattr(sys, "frozen"):
            print(
                "CellProfiler Startup ERROR: Could not find path to Java environment directory.\n"
                "Please set the CP_JAVA_HOME system environment variable.\n"
                "Visit http://broad.io/cpjava for instructions."
            )
            os.system("pause")  # Keep console window open until keypress.
            os._exit(1)
        raise RuntimeError(
            "Failed to find the Java Runtime Environment. "
            "Please download and install the Oracle JRE 1.6 or later"
        )


def find_jdk():
    """Find the JDK under Windows"""
    if 'JDK_HOME' in os.environ:
        return os.environ['JDK_HOME']
    if is_linux:
        jdk_home = find_javahome()
        if jdk_home.endswith("jre") or jdk_home.endswith("jre/"):
            jdk_home = jdk_home[:jdk_home.rfind("jre")]
        return jdk_home
    if is_mac:
        return find_javahome()
    if is_win:
        # Registry keys changed in 1.9
        # https://docs.oracle.com/javase/9/migrate/toc.htm#GUID-EEED398E-AE37-4D12-AB10-49F82F720027
        jdk_key_paths = (
            'SOFTWARE\\JavaSoft\\JDK',
            'SOFTWARE\\JavaSoft\\Java Development Kit',
        )
        for jdk_key_path in jdk_key_paths:
            try:
                kjdk = winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, jdk_key_path)
                kjdk_values = dict([winreg.EnumValue(kjdk, i)[:2]
                                     for i in range(winreg.QueryInfoKey(kjdk)[1])])
                current_version = kjdk_values['CurrentVersion']
                kjdk_current = winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE,
                                               jdk_key_path + '\\' + current_version)
                kjdk_current_values = dict([winreg.EnumValue(kjdk_current, i)[:2]
                                            for i in range(winreg.QueryInfoKey(kjdk_current)[1])])
                return kjdk_current_values['JavaHome']
            except WindowsError as e:
                if e.errno == 2:
                    continue
                else:
                    raise

        raise RuntimeError(
            "Failed to find the Java Development Kit. "
            "Please download and install the Oracle JDK 1.6 or later"
        )

def find_javac_cmd():
    """Find the javac executable"""
    if is_win:
        jdk_base = find_jdk()
        javac = os.path.join(jdk_base, "bin", "javac.exe")
        if os.path.isfile(javac):
            return javac
        raise RuntimeError("Failed to find javac.exe in its usual location under the JDK (%s)" % javac)
    else:
        # will be along path for other platforms
        return "javac"

def find_jar_cmd():
    """Find the javac executable"""
    if is_win:
        jdk_base = find_jdk()
        javac = os.path.join(jdk_base, "bin", "jar.exe")
        if os.path.isfile(javac):
            return javac
        raise RuntimeError("Failed to find jar.exe in its usual location under the JDK (%s)" % javac)
    else:
        # will be along path for other platforms
        return "jar"


def find_jre_bin_jdk_so():
    """Finds the jre bin dir and the jdk shared library file"""
    jvm_dir = None
    java_home = find_javahome()
    if java_home is not None:
        found_jvm = False
        for jre_home in (java_home, os.path.join(java_home, "jre"), os.path.join(java_home, 'default-java')):
            jre_bin = os.path.join(jre_home, 'bin')
            jre_libexec = os.path.join(jre_home, 'bin' if is_win else 'lib')
            arches = ('amd64', 'i386', '') if is_linux else ('',)
            lib_prefix = '' if is_win else 'lib'
            lib_suffix = '.dll' if is_win else ('.dylib' if is_mac else '.so')
            for arch in arches:
                for place_to_look in ('client','server'):
                    jvm_dir = os.path.join(jre_libexec, arch, place_to_look)
                    jvm_so = os.path.join(jvm_dir, lib_prefix + "jvm" + lib_suffix)
                    if os.path.isfile(jvm_so):
                        return (jre_bin, jvm_so)
    return (jre_bin, None)
