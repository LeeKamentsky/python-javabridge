import os.path

_jars_dir = os.path.join(os.path.dirname(__file__), 'jars')
JARS = [os.path.realpath(os.path.join(_jars_dir, name + '.jar'))
        for name in ['rhino-1.7R4', 'runnablequeue-1.0.0']]

from .jutil import start_vm, run_script, execute_runnable_in_main_thread, \
    activate_awt, deactivate_awt, kill_vm, attach, detach, \
    get_class_wrapper, execute_callable_in_main_thread, unwrap_javascript, \
    get_field_wrapper, to_string, class_for_name, call, get_static_field, \
    get_env, make_instance, make_new, make_method, static_call, \
    get_dictionary_wrapper, jdictionary_to_string_dictionary, \
    jenumeration_to_string_list, get_enumeration_wrapper
