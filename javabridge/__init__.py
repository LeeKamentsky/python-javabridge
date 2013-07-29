import os.path

_jars_dir = os.path.join(os.path.dirname(__file__), 'jars')
JARS = [os.path.realpath(os.path.join(_jars_dir, name + '.jar'))
        for name in ['rhino-1.7R4', 'runnablequeue-1.0.0']]

from .jutil import start_vm, run_script, execute_runnable_in_main_thread, \
    activate_awt, deactivate_awt, kill_vm
