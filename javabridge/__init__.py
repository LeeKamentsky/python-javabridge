"""__init__.py - the javabridge package

python-javabridge is licensed under the BSD license.  See the
accompanying file LICENSE for details.

Copyright (c) 2003-2009 Massachusetts Institute of Technology
Copyright (c) 2009-2013 Broad Institute
All rights reserved.

"""

import os.path

_jars_dir = os.path.join(os.path.dirname(__file__), 'jars')

#: List of absolute paths to JAR files that are required for the
#: Javabridge to work.
JARS = [os.path.realpath(os.path.join(_jars_dir, name + '.jar'))
        for name in ['rhino-1.7R4', 'runnablequeue']]


from .jutil import start_vm, kill_vm, activate_awt, deactivate_awt

from .jutil import attach, detach, get_env


# JavaScript
from .jutil import run_script


# Operations on Java objects
from .jutil import call, get_static_field, static_call, \
    is_instance_of, make_instance, set_static_field, to_string

# Make Python object that wraps a Java object
from .jutil import make_method, make_new

# Useful collection wrappers
from .jutil import get_dictionary_wrapper, jdictionary_to_string_dictionary, \
    jenumeration_to_string_list, get_enumeration_wrapper, iterate_collection, \
    iterate_java

# Reflection. (These use make_method or make_new internally.)
from .jutil import get_class_wrapper, get_field_wrapper, class_for_name, \
    get_constructor_wrapper, get_method_wrapper

# Ensure that callables, runnables and futures that use AWT run in the
# AWT main thread, which is not accessible from Python.
from .jutil import execute_callable_in_main_thread, \
    execute_runnable_in_main_thread, execute_future_in_main_thread

# Exceptions
from .jutil import JavaError, JavaException, JVMNotFoundError
    
# Don't expose: AtExit, attach_ext_env, get_nice_arg, get_nice_args,
# make_run_dictionary, run_in_main_thread, split_sig, unwrap_javascript,
# print_all_stack_traces


# Low-level API
from ._javabridge import JB_Env, JB_Object
