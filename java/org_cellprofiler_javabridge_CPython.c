/*
python-javabridge is licensed under the BSD license.  See the
accompanying file LICENSE for details.

Copyright (c) 2003-2009 Massachusetts Institute of Technology
Copyright (c) 2009-2013 Broad Institute
All rights reserved.
*/

#include <jni.h>
#include <stdio.h>
#include <Python.h>
#ifdef __linux__
#include <stdlib.h>
#include <dlfcn.h>
#endif
#include "org_cellprofiler_javabridge_CPython.h"

int initialized = 0;
static void check_init(void);

#ifdef __linux__
/*
 * On Linux, it appears that Python's symbols cannot be found by other
 * native libraries if we let the JVM load libpython... so we have to load it
 * explicitly, with the correct flag (RTLD_GLOBAL).
 */

static char *get_property(JavaVM *vm, const char *key)
{
	JNIEnv *pEnv;
	jclass system;
	jmethodID get;
	jstring string;
	const char *characters;
	char *result;

	if ((*vm)->GetEnv(vm, (void **)&pEnv, JNI_VERSION_1_2) != JNI_OK) {
		fprintf(stderr, "Could not obtain JNI environment\n");
		return NULL;
	}

	if (!(system = (*pEnv)->FindClass(pEnv, "java/lang/System"))) {
		fprintf(stderr, "Could not access System class\n");
		return NULL;
	}

	if (!(get = (*pEnv)->GetStaticMethodID(pEnv, system, "getProperty",
			"(Ljava/lang/String;)Ljava/lang/String;"))) {
		fprintf(stderr, "Could not find getProperty method\n");
		return NULL;
	}

	if (!(string = (jstring)(*pEnv)->CallStaticObjectMethod(pEnv, system,
			get, (*pEnv)->NewStringUTF(pEnv, key))))
		return NULL;

	characters = (*pEnv)->GetStringUTFChars(pEnv, string, NULL);
	result = strdup(characters);
	(*pEnv)->ReleaseStringUTFChars(pEnv, string, characters);

	(*vm)->DetachCurrentThread(vm);

	return result;
}
#endif
JavaVM *pVM;

jint JNI_OnLoad(JavaVM *vm, void *reserved)
{
#ifdef __linux__
    char buf[1024];
    char *python_location = get_property(vm, "python.location");
    const char *command = "python -c \"import sysconfig; from os.path import join; print join(sysconfig.get_config_var('LIBDIR'), sysconfig.get_config_var('multiarchsubdir')[1:], sysconfig.get_config_var('LDLIBRARY'))\"";

    if (!python_location) {
	size_t len=1024;
	FILE *stream = popen(command, "r");
	python_location = buf;
	getline(&python_location, &len, stream);
	python_location[strlen(python_location)-1] = 0;
	pclose(stream);
    }
    if (!dlopen(python_location, RTLD_LAZY | RTLD_GLOBAL))
	    fprintf(stderr, "Warning: Error loading %s\n", python_location);
#endif
    pVM = vm;
    return JNI_VERSION_1_2;
}
    /*
     * Run some code here to encapsulate a pointer to the VM and call
     * import javabridge
     * javabridge.jvm_enter(capsule)
     *
     */
static int set_vm(void)
{
    PyObject *pPyVM;
    PyObject *pJavabridge;
    PyObject *pJVMEnter;
    PyObject *pArgs;
    PyObject *pResult;
    
    pPyVM = PyCapsule_New((void *)pVM, NULL, NULL);
    if (PyErr_Occurred()) {
        fprintf(stderr, "Unable to encapsulate VM for Python.\n");
        return -1;
    }
    pJavabridge = PyImport_ImportModule("javabridge");
    if (PyErr_Occurred()) {
	fprintf(stderr, "Failed to import javabridge.\n");
        Py_DECREF(pPyVM);
        return -1;
    }
    pJVMEnter = PyObject_GetAttrString(pJavabridge, "jvm_enter");
    if (PyErr_Occurred()) {
        fprintf(stderr, "Failed to find function, javabridge.jvm_enter\n");
        Py_DECREF(pJavabridge);
        Py_DECREF(pPyVM);
        return -1;
    }
    pArgs = PyTuple_Pack(1, pPyVM);
    if (! pArgs) {
        fprintf(stderr, "Failed to create the arguments for jvm_enter\n");
        Py_DECREF(pJVMEnter);
        Py_DECREF(pJavabridge);
        Py_DECREF(pPyVM);
        return -1;
    }
    pResult = PyObject_CallObject(pJVMEnter, pArgs);
    if (! pResult) {
	fprintf(stderr, "Caught exception in jvm_enter.\n");
        Py_DECREF(pArgs);
        Py_DECREF(pJVMEnter);
        Py_DECREF(pJavabridge);
        Py_DECREF(pPyVM);
        return -1;
    }
    Py_DECREF(pResult);
    Py_DECREF(pArgs);
    Py_DECREF(pJVMEnter);
    Py_DECREF(pJavabridge);
    Py_DECREF(pPyVM);
    return 0;
}

#ifdef _WIN32
/*
 * If MSVC90.dll is on the path, we will perish horribly in Windows
 * with an R6034 exception on loading it from some of the numerous
 * pyd files that include it.
 */
const char *pCleanPath = "import os;os.environ['path']=';'.join([path for path in os.environ['path'].split(';') if 'msvcr90.dll' not in map((lambda x:x.lower()), os.listdir(path))])";
#endif
static void check_init(void) {
    if ((initialized == 0) && ! Py_IsInitialized()) {
        Py_Initialize();
        #ifdef _WIN32
        PyRun_SimpleString(pCleanPath);
        #endif
	set_vm();
        initialized = 1;
    }
}

/*
   throwError
   
   Throw an error that indicates a problem beyond what would be caused
   by the evaluation or execution of Python code
   
   pEnv - JNI environment
   message - message to report
*/
static void throwError(JNIEnv *pEnv, char *message) {
    jclass exClass;
    char *className = "java/lang/Error";

    exClass = (*pEnv)->FindClass(pEnv, className);
    if (exClass == NULL) {
        return;
    }
    (*pEnv)->ThrowNew(pEnv, exClass, message);
    PyErr_Clear();
}

/*
    throwWrappedError
    
    Throw an exception that reflects the current Python exception into
    Java.
*/
static void throwWrappedError(JNIEnv *pEnv, int linenumber)
{
    char buffer[1000];
    /* TODO: implement*/
    PyErr_Print();
    snprintf(buffer, sizeof(buffer), 
             "Python exception at %s:%d", __FILE__, linenumber);
    throwError(pEnv, buffer);
}
/*
   attach_env
   
   Attach the supplied environment to the javabridge thread-local context.
   
   pEnv - the environment passed via the JNI call
   
   Prerequisites: The GIL must be taken.
   
   Returns: 0 if successful, negative value on failure indicating that a
            Java exception has been thrown.
*/
static int attach_env(JNIEnv *pEnv){
    PyObject *pPyEnv;
    PyObject *pJavabridge;
    PyObject *pJNIEnter;
    PyObject *pArgs;
    PyObject *pResult;
    /*
    Equivalent to:
    import javabridge
    javabridge.jni_enter(env)
    */
    
    pPyEnv = PyCapsule_New((void *)pEnv, NULL, NULL);
    if (PyErr_Occurred()) {
        throwWrappedError(pEnv, __LINE__);
        return -1;
    }
    pJavabridge = PyImport_ImportModule("javabridge");
    if (PyErr_Occurred()) {
        throwWrappedError(pEnv, __LINE__);
        Py_DECREF(pPyEnv);
        return -1;
    }
    pJNIEnter = PyObject_GetAttrString(pJavabridge, "jni_enter");
    if (PyErr_Occurred()) {
        throwWrappedError(pEnv, __LINE__);
        Py_DECREF(pJavabridge);
        Py_DECREF(pPyEnv);
        return -1;
    }
    pArgs = PyTuple_Pack(1, pPyEnv);
    if (! pArgs) {
        throwWrappedError(pEnv, __LINE__);
        Py_DECREF(pJNIEnter);
        Py_DECREF(pJavabridge);
        Py_DECREF(pPyEnv);
        return -1;
    }
    pResult = PyObject_CallObject(pJNIEnter, pArgs);
    if (! pResult) {
        throwWrappedError(pEnv, __LINE__);
        Py_DECREF(pArgs);
        Py_DECREF(pJNIEnter);
        Py_DECREF(pJavabridge);
        Py_DECREF(pPyEnv);
        return -1;
    }
    Py_DECREF(pResult);
    Py_DECREF(pArgs);
    Py_DECREF(pJNIEnter);
    Py_DECREF(pJavabridge);
    Py_DECREF(pPyEnv);
    return 0;    
}

/*
     detach_env
     
     Detach an environment previously attached using attach_env
*/
static int detach_env(JNIEnv *pEnv) {
    PyObject *pJavabridge;
    PyObject *pJNIExit;
    PyObject *pArgs;
    PyObject *pResult;

    pJavabridge = PyImport_ImportModule("javabridge");
    if (! pJavabridge) {
        throwWrappedError(pEnv, __LINE__);
        return -1;
    }
    pJNIExit = PyObject_GetAttrString(pJavabridge, "jni_exit");
    if (! pJNIExit) {
        throwWrappedError(pEnv, __LINE__);
        Py_DECREF(pJavabridge);
        return -1;
    }
    pArgs = PyTuple_New(0);
    if (! pArgs) {
        throwWrappedError(pEnv, __LINE__);
        Py_DECREF(pJNIExit);
        Py_DECREF(pJavabridge);
    }
    pResult = PyObject_CallObject(pJNIExit, pArgs);
    if (! pResult) {
        throwWrappedError(pEnv, __LINE__);
        Py_DECREF(pArgs);
        Py_DECREF(pJNIExit);
        Py_DECREF(pJavabridge);
        return -1;
    }
    Py_DECREF(pResult);
    Py_DECREF(pArgs);   
    Py_DECREF(pJNIExit);
    Py_DECREF(pJavabridge);
    return 0;
}

static PyObject *wrapJObject(JNIEnv *pEnv, jobject j) {
    PyObject *pJavabridge;
    PyObject *pGetEnv;
    PyObject *pTheEnv;
    PyObject *pCapsule;
    PyObject *pResult;
    
    if (! j) {
        Py_RETURN_NONE;
    }
    pJavabridge = PyImport_ImportModule("javabridge");
    if (! pJavabridge) {
        throwWrappedError(pEnv, __LINE__);
        return NULL;
    }
    pGetEnv = PyObject_GetAttrString(pJavabridge, "get_env");
    if (! pGetEnv) {
        throwWrappedError(pEnv, __LINE__);
        Py_DECREF(pJavabridge);
        return NULL;
    }
    pTheEnv = PyObject_CallObject(pGetEnv, NULL);
    if (! pTheEnv) {
        throwWrappedError(pEnv, __LINE__);
        Py_DECREF(pGetEnv);
        Py_DECREF(pJavabridge);
        return NULL;
    }
    pCapsule = PyCapsule_New((void *)j, NULL, NULL);
    if (! pCapsule) {
        throwWrappedError(pEnv, __LINE__);
        Py_DECREF(pTheEnv);
        Py_DECREF(pGetEnv);
        Py_DECREF(pJavabridge);
        return NULL;
    }
    pResult = PyObject_CallMethod(pTheEnv, "make_jb_object", "O", pCapsule);
    if (! pResult) {
        throwWrappedError(pEnv, __LINE__);
    }
    Py_DECREF(pCapsule);
    Py_DECREF(pTheEnv);
    Py_DECREF(pGetEnv);
    Py_DECREF(pJavabridge);
    return pResult;    
}

static PyObject *mapToDictionary(JNIEnv *pEnv, jobject map) {
    PyObject *pMap;
    PyObject *pJavabridge;
    PyObject *pFn;
    PyObject *pArgs;
    PyObject *pResult;
    
    if (! map) {
        pResult = PyDict_New();
        if (! pResult) {
            throwWrappedError(pEnv, __LINE__);
        }
        return pResult;
    }
    pMap = wrapJObject(pEnv, map);
    if (! pMap) {
        return NULL;
    }
    pJavabridge = PyImport_ImportModule("javabridge.jutil");
    if (! pJavabridge) {
        throwWrappedError(pEnv, __LINE__);
        Py_DECREF(pMap);
        return NULL;
    }
    pFn = PyObject_GetAttrString(pJavabridge, "make_run_dictionary");
    Py_DECREF(pJavabridge);
    if (! pFn) {
        throwWrappedError(pEnv, __LINE__);
        Py_DECREF(pMap);
        return NULL;
    }
    pArgs = PyTuple_Pack(1, pMap);
    Py_DECREF(pMap);
    if (! pArgs) {
        throwWrappedError(pEnv, __LINE__);
        Py_DECREF(pFn);
        return NULL;
    }
    pResult = PyObject_CallObject(pFn, pArgs);
    Py_DECREF(pFn);
    Py_DECREF(pArgs);
    if (! pResult){
        throwWrappedError(pEnv, __LINE__);
        return NULL;
    }
    return pResult;
}

/*
 * Add globals from __main__ to a dictionary of them.
 */
static int add_globals(JNIEnv *pEnv, PyObject *pGlobals) {
    PyObject *pMain;
    PyObject *pMainDict;
    int result;
    pMain = PyImport_AddModule("__main__");
    if (! pMain) {
        throwWrappedError(pEnv, __LINE__);
        return -1;
    }
    pMainDict = PyModule_GetDict(pMain);
    result = PyDict_Merge(pGlobals, pMainDict, 0);
    if (result) {
        throwWrappedError(pEnv, __LINE__);
    }
    return result;
}

JNIEXPORT void JNICALL Java_org_cellprofiler_javabridge_CPython_exec
  (JNIEnv *pEnv, jobject thiss, jstring script, jobject locals, jobject globals) {
    PyGILState_STATE state;
    PyObject *pLocals;
    PyObject *pGlobals;
    const char *pScript;
    PyObject *pResult;
    
    if (! pEnv) {
        throwError(pEnv, "JNIEnv was null.");
        return;
    }
    if (! script) {
        throwError(pEnv, "Script was null.");
        return;
    }
    check_init();
    state = PyGILState_Ensure();
    if (attach_env(pEnv) == 0) {
        pLocals = mapToDictionary(pEnv, locals);
        if (pLocals) {
            if ((locals != NULL) && 
                ((*pEnv)->IsSameObject(pEnv, locals, globals))) {
                pGlobals = pLocals;
                Py_INCREF(pGlobals);
            } else {
                pGlobals = mapToDictionary(pEnv, globals);
            }
            if (pGlobals) {
                if (! add_globals(pEnv, pGlobals)) {
                    pScript = (*pEnv)->GetStringUTFChars(pEnv, script, NULL);
                    pResult = PyRun_String(
                        pScript, Py_file_input, pGlobals, pLocals);
                    (*pEnv)->ReleaseStringUTFChars(pEnv, script, NULL);
                    if (pResult) {
                        Py_DECREF(pResult);
                    } else {
                        throwWrappedError(pEnv, __LINE__);
                    }
                }
                Py_DECREF(pGlobals);
            }
            Py_DECREF(pLocals);
        }
    }
    detach_env(pEnv);
    PyGILState_Release(state);
}
