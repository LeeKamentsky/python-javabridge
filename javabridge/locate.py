"""locate.py - determine architecture and find Java

python-javabridge is licensed under the BSD license.  See the
accompanying file LICENSE for details.

Copyright (c) 2003-2009 Massachusetts Institute of Technology
Copyright (c) 2009-2013 Broad Institute
All rights reserved.lo

"""

from __future__ import absolute_import

import os
import sys
import logging

is_linux = sys.platform.startswith('linux')
is_mac = sys.platform == 'darwin'
is_win = sys.platform.startswith("win")
is_win64 = (is_win and (os.environ["PROCESSOR_ARCHITECTURE"] == "AMD64"))
is_msvc = (is_win and sys.version_info[0] >= 2 and sys.version_info[1] >= 6)
is_mingw = (is_win and not is_msvc)

logger = logging.getLogger(__name__)

def find_javahome():
    """Find JAVA_HOME if it doesn't exist"""
    if hasattr(sys, 'frozen') and is_win:
        #
        # The standard installation of CellProfiler for Windows comes with a JRE
        #
        path = os.path.split(os.path.abspath(sys.argv[0]))[0]
        path = os.path.join(path, "jre")
        for jvm_folder in ("client", "server"):
            jvm_path = os.path.join(path, "bin", jvm_folder, "jvm.dll")
            if os.path.exists(jvm_path):
                # Problem: have seen JAVA_HOME != jvm_path cause DLL load problems
                if "JAVA_HOME" in os.environ:
                    del os.environ["JAVA_HOME"]
                return path
    
    if 'JAVA_HOME' in os.environ:
        return os.environ['JAVA_HOME']
    elif is_mac:
        return "Doesn't matter"
    elif is_linux:
        import subprocess
        def get_out(cmd):
            p = subprocess.Popen(cmd, stdout=subprocess.PIPE)
            o, ignore = p.communicate()
            if p.poll() != 0:
                raise Exception("Error finding javahome on linux: %s" % cmd)
            o = o.strip()
            return o
        java_bin = get_out(["bash", "-c", "type -p java"])
        java_dir = get_out(["readlink", "-f", java_bin])
        jdk_dir = os.path.join(java_dir, "..", "..", "..")
        jdk_dir = os.path.abspath(jdk_dir)
        return jdk_dir
    elif is_win:
        import _winreg
        java_key_path = 'SOFTWARE\\JavaSoft\\Java Runtime Environment'
        looking_for = java_key_path
        try:
            kjava = _winreg.OpenKey(_winreg.HKEY_LOCAL_MACHINE, java_key_path)
            looking_for = java_key_path + "\\CurrentVersion"
            kjava_values = dict([_winreg.EnumValue(kjava, i)[:2]
                                 for i in range(_winreg.QueryInfoKey(kjava)[1])])
            current_version = kjava_values['CurrentVersion']
            looking_for = java_key_path + '\\' + current_version
            kjava_current = _winreg.OpenKey(_winreg.HKEY_LOCAL_MACHINE,
                                            looking_for)
            kjava_current_values = dict([_winreg.EnumValue(kjava_current, i)[:2]
                                         for i in range(_winreg.QueryInfoKey(kjava_current)[1])])
            return kjava_current_values['JavaHome']
        except:
            logger.error("Failed to find registry entry: %s\n" %looking_for,
                         exc_info=True)
            return None


def find_jdk():
    """Find the JDK under Windows"""
    if is_mac:
        return "Doesn't matter"
    if is_win:
        import _winreg
        import exceptions
        try:
            jdk_key_path = 'SOFTWARE\\JavaSoft\\Java Development Kit'
            kjdk = _winreg.OpenKey(_winreg.HKEY_LOCAL_MACHINE, jdk_key_path)
            kjdk_values = dict([_winreg.EnumValue(kjdk, i)[:2]
                                 for i in range(_winreg.QueryInfoKey(kjdk)[1])])
            current_version = kjdk_values['CurrentVersion']
            kjdk_current = _winreg.OpenKey(_winreg.HKEY_LOCAL_MACHINE,
                                           jdk_key_path + '\\' + current_version)
            kjdk_current_values = dict([_winreg.EnumValue(kjdk_current, i)[:2]
                                        for i in range(_winreg.QueryInfoKey(kjdk_current)[1])])
            return kjdk_current_values['JavaHome']
        except exceptions.WindowsError as e:
            if e.errno == 2:
                raise RuntimeError(
                    "Failed to find the Java Development Kit. Please download and install the Oracle JDK 1.6 or later")
            else:
                raise
            
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
