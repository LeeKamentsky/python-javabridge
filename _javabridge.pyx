# cython: language_level=3
"""_javabridge.pyx - low-level interface to the JVM

python-javabridge is licensed under the BSD license.  See the
accompanying file LICENSE for details.

Copyright (c) 2003-2009 Massachusetts Institute of Technology
Copyright (c) 2009-2013 Broad Institute
All rights reserved.

"""

import numpy as np
import sys
import threading
cimport numpy as np
cimport cython
cimport _javabridge_osspecific
cimport cpython

if sys.version_info >= (3, 0, 0):
    # unchir -> chr in Python 3
    unichr = chr

cdef extern from "Python.h":
    ctypedef int Py_intptr_t
    ctypedef unsigned long Py_ssize_t
    unicode PyUnicode_DecodeUTF16(char *s, Py_ssize_t size, char *errors, int *byteorder)
    bint PyCapsule_CheckExact(object o)
    void *PyCapsule_GetPointer(object o,char *name)

cdef extern from "stdlib.h":
    ctypedef unsigned long size_t
    void free(void *ptr)
    void *malloc(size_t size)

cdef extern from "string.h":
    void *memset(void *, int, int)
    void *memcpy(void *, void *, int)

cdef extern from "numpy/arrayobject.h":
    ctypedef class numpy.ndarray [object PyArrayObject]:
        cdef char *data
        cdef Py_intptr_t *dimensions
        cdef Py_intptr_t *strides
    cdef void import_array()
    cdef int  PyArray_ITEMSIZE(np.ndarray)

import_array()

cdef extern from "jni.h":
    enum:
       JNI_VERSION_1_4
       JNI_COMMIT
       JNI_ABORT
    ctypedef struct _jobject
    ctypedef struct _jmethodID
    ctypedef struct _jfieldID
    
    ctypedef long jint
    ctypedef unsigned char jboolean
    ctypedef unsigned char jbyte
    ctypedef unsigned short jchar
    ctypedef short jshort
    ctypedef long long jlong
    ctypedef float jfloat
    ctypedef double jdouble
    ctypedef jint jsize

    ctypedef _jobject *jobject
    ctypedef jobject jclass
    ctypedef jobject jthrowable
    ctypedef jobject jstring
    ctypedef jobject jarray
    ctypedef jarray jbooleanArray
    ctypedef jarray jbyteArray
    ctypedef jarray jcharArray
    ctypedef jarray jshortArray
    ctypedef jarray jintArray
    ctypedef jarray jlongArray
    ctypedef jarray jfloatArray
    ctypedef jarray jdoubleArray
    ctypedef jarray jobjectArray
    ctypedef union jvalue:
        jboolean z
        jbyte b
        jchar c
        jshort s
        jint i
        jlong j
        jfloat f
        jdouble d
        jobject l
    ctypedef jvalue jvalue
    ctypedef _jmethodID *jmethodID
    ctypedef _jfieldID *jfieldID

    ctypedef struct JNIInvokeInterface_

    ctypedef JNIInvokeInterface_ *JavaVM

    ctypedef struct JNIInvokeInterface_:
         jint (*DestroyJavaVM)(JavaVM *vm) nogil
         jint (*AttachCurrentThread)(JavaVM *vm, void **penv, void *args) nogil
         jint (*DetachCurrentThread)(JavaVM *vm) nogil
         jint (*GetEnv)(JavaVM *vm, void **penv, jint version) nogil
         jint (*AttachCurrentThreadAsDaemon)(JavaVM *vm, void *penv, void *args) nogil

    struct JavaVMOption:
        char *optionString
        void *extraInfo
    ctypedef JavaVMOption JavaVMOption

    struct JavaVMInitArgs:
        jint version
        jint nOptions
        JavaVMOption *options
        jboolean ignoreUnrecognized
    ctypedef JavaVMInitArgs JavaVMInitArgs

    struct JNIEnv_
    struct JNINativeInterface_
    ctypedef JNINativeInterface_ *JNIEnv

    struct JNINativeInterface_:
        jint (* GetVersion)(JNIEnv *env) nogil
        jclass (* FindClass)(JNIEnv *env, char *name) nogil
        jclass (* GetObjectClass)(JNIEnv *env, jobject obj) nogil
        jboolean (* IsInstanceOf)(JNIEnv *env, jobject obj, jclass klass) nogil
        jobject (* NewGlobalRef)(JNIEnv *env, jobject lobj) nogil
        void (* DeleteGlobalRef)(JNIEnv *env, jobject gref) nogil
        void (* DeleteLocalRef)(JNIEnv *env, jobject obj) nogil
        #
        # Exception handling
        #
        jobject (* ExceptionOccurred)(JNIEnv *env) nogil
        void (* ExceptionDescribe)(JNIEnv *env) nogil
        void (* ExceptionClear)(JNIEnv *env) nogil
        #
        # Method IDs
        #
        jmethodID (*GetMethodID)(JNIEnv *env, jclass clazz, char *name, char *sig) nogil
        jmethodID (*GetStaticMethodID)(JNIEnv *env, jclass clazz, char *name, char *sig) nogil
        jmethodID (*FromReflectedMethod)(JNIEnv *env, jobject method) nogil
        jmethodID (*FromReflectedField)(JNIEnv *env, jobject field) nogil
        #
        # New object
        #
        jobject (* NewObjectA)(JNIEnv *env, jclass clazz, jmethodID id, jvalue *args) nogil
        #
        # Methods for object calls
        #
        jboolean (* CallBooleanMethodA)(JNIEnv *env, jobject obj, jmethodID methodID, jvalue *args) nogil
        jbyte (* CallByteMethodA)(JNIEnv *env, jobject obj, jmethodID methodID, jvalue *args) nogil
        jchar (* CallCharMethodA)(JNIEnv *env, jobject obj, jmethodID methodID, jvalue *args) nogil
        jshort (* CallShortMethodA)(JNIEnv *env, jobject obj, jmethodID methodID, jvalue *args) nogil
        jint (* CallIntMethodA)(JNIEnv *env, jobject obj, jmethodID methodID, jvalue *args) nogil
        jlong (* CallLongMethodA)(JNIEnv *env, jobject obj, jmethodID methodID, jvalue *args) nogil
        jfloat (* CallFloatMethodA)(JNIEnv *env, jobject obj, jmethodID methodID, jvalue *args) nogil
        jdouble (* CallDoubleMethodA)(JNIEnv *env, jobject obj, jmethodID methodID, jvalue *args) nogil
        void (* CallVoidMethodA)(JNIEnv *env, jobject obj, jmethodID methodID, jvalue *args) nogil
        jobject (* CallObjectMethodA)(JNIEnv *env, jobject obj, jmethodID methodID, jvalue *args) nogil
        #
        # Methods for static class calls
        #
        jboolean (* CallStaticBooleanMethodA)(JNIEnv *env, jclass clazz, jmethodID methodID, jvalue *args) nogil
        jbyte (* CallStaticByteMethodA)(JNIEnv *env, jclass clazz, jmethodID methodID, jvalue *args) nogil
        jchar (* CallStaticCharMethodA)(JNIEnv *env, jclass clazz, jmethodID methodID, jvalue *args) nogil
        jshort (* CallStaticShortMethodA)(JNIEnv *env, jclass clazz, jmethodID methodID, jvalue *args) nogil
        jint (* CallStaticIntMethodA)(JNIEnv *env, jclass clazz, jmethodID methodID, jvalue *args) nogil
        jlong (* CallStaticLongMethodA)(JNIEnv *env, jclass clazz, jmethodID methodID, jvalue *args) nogil
        jfloat (* CallStaticFloatMethodA)(JNIEnv *env, jclass clazz, jmethodID methodID, jvalue *args) nogil
        jdouble (* CallStaticDoubleMethodA)(JNIEnv *env, jclass clazz, jmethodID methodID, jvalue *args) nogil
        void (* CallStaticVoidMethodA)(JNIEnv *env, jclass clazz, jmethodID methodID, jvalue *args) nogil
        jobject (* CallStaticObjectMethodA)(JNIEnv *env, jclass clazz, jmethodID methodID, jvalue *args) nogil
        #
        # Methods for fields
        #
        jfieldID (* GetFieldID)(JNIEnv *env, jclass clazz, char *name, char *sig) nogil
        jobject (* GetObjectField)(JNIEnv *env, jobject obj, jfieldID fieldID) nogil
        jboolean (* GetBooleanField)(JNIEnv *env, jobject obj, jfieldID fieldID) nogil
        jbyte (* GetByteField)(JNIEnv *env, jobject obj, jfieldID fieldID) nogil
        jchar (* GetCharField)(JNIEnv *env, jobject obj, jfieldID fieldID) nogil
        jshort (* GetShortField)(JNIEnv *env, jobject obj, jfieldID fieldID) nogil
        jint (* GetIntField)(JNIEnv *env, jobject obj, jfieldID fieldID) nogil
        jlong (* GetLongField)(JNIEnv *env, jobject obj, jfieldID fieldID) nogil
        jfloat (*GetFloatField)(JNIEnv *env, jobject obj, jfieldID fieldID) nogil
        jdouble (*GetDoubleField)(JNIEnv *env, jobject obj, jfieldID fieldID) nogil

        void (* SetObjectField)(JNIEnv *env, jobject obj, jfieldID fieldID, jobject val) nogil
        void (* SetBooleanField)(JNIEnv *env, jobject obj, jfieldID fieldID, jboolean val) nogil
        void (* SetByteField)(JNIEnv *env, jobject obj, jfieldID fieldID, jbyte val) nogil
        void (* SetCharField)(JNIEnv *env, jobject obj, jfieldID fieldID, jchar val) nogil
        void (*SetShortField)(JNIEnv *env, jobject obj, jfieldID fieldID, jshort val) nogil
        void (*SetIntField)(JNIEnv *env, jobject obj, jfieldID fieldID, jint val) nogil
        void (*SetLongField)(JNIEnv *env, jobject obj, jfieldID fieldID, jlong val) nogil
        void (*SetFloatField)(JNIEnv *env, jobject obj, jfieldID fieldID, jfloat val) nogil
        void (*SetDoubleField)(JNIEnv *env, jobject obj, jfieldID fieldID, jdouble val) nogil

        jfieldID (*GetStaticFieldID)(JNIEnv *env, jclass clazz, char *name, char *sig) nogil
        jobject (* GetStaticObjectField)(JNIEnv *env, jclass clazz, jfieldID fieldID) nogil
        jboolean (* GetStaticBooleanField)(JNIEnv *env, jclass clazz, jfieldID fieldID) nogil
        jbyte (* GetStaticByteField)(JNIEnv *env, jclass clazz, jfieldID fieldID) nogil
        jchar (* GetStaticCharField)(JNIEnv *env, jclass clazz, jfieldID fieldID) nogil
        jshort (* GetStaticShortField)(JNIEnv *env, jclass clazz, jfieldID fieldID) nogil
        jint (* GetStaticIntField)(JNIEnv *env, jclass clazz, jfieldID fieldID) nogil
        jlong (* GetStaticLongField)(JNIEnv *env, jclass clazz, jfieldID fieldID) nogil
        jfloat (*GetStaticFloatField)(JNIEnv *env, jclass clazz, jfieldID fieldID) nogil
        jdouble (* GetStaticDoubleField)(JNIEnv *env, jclass clazz, jfieldID fieldID) nogil

        void (*SetStaticObjectField)(JNIEnv *env, jclass clazz, jfieldID fieldID, jobject value) nogil
        void (*SetStaticBooleanField)(JNIEnv *env, jclass clazz, jfieldID fieldID, jboolean value) nogil
        void (*SetStaticByteField)(JNIEnv *env, jclass clazz, jfieldID fieldID, jbyte value) nogil
        void (*SetStaticCharField)(JNIEnv *env, jclass clazz, jfieldID fieldID, jchar value) nogil
        void (*SetStaticShortField)(JNIEnv *env, jclass clazz, jfieldID fieldID, jshort value) nogil
        void (*SetStaticIntField)(JNIEnv *env, jclass clazz, jfieldID fieldID, jint value) nogil
        void (*SetStaticLongField)(JNIEnv *env, jclass clazz, jfieldID fieldID, jlong value) nogil
        void (*SetStaticFloatField)(JNIEnv *env, jclass clazz, jfieldID fieldID, jfloat value) nogil
        void (*SetStaticDoubleField)(JNIEnv *env, jclass clazz, jfieldID fieldID, jdouble value) nogil
        #
        # Methods for handling strings
        #
        jobject (* NewStringUTF)(JNIEnv *env, char *utf) nogil
        jobject (* NewString)(JNIEnv *env, jchar *unicode, jsize len) nogil
        char *(* GetStringUTFChars)(JNIEnv *env, jobject str, jboolean *is_copy) nogil
        void (* ReleaseStringUTFChars)(JNIEnv *env, jobject str, char *chars) nogil
        jsize (* GetStringLength)(JNIEnv *env, jobject str) nogil
        jchar *(* GetStringChars)(JNIEnv *env, jobject str, jboolean *isCopy) nogil
        void (* ReleaseStringChars)(JNIEnv *env, jobject str, jchar *chars) nogil
        #
        # Methods for making arrays (which I am not distinguishing from jobjects here) nogil
        #
        jsize (* GetArrayLength)(JNIEnv *env, jobject array) nogil
        jobject (* NewObjectArray)(JNIEnv *env, jsize len, jclass clazz, jobject init) nogil
        jobject (* GetObjectArrayElement)(JNIEnv *env, jobject array, jsize index) nogil
        void (* SetObjectArrayElement)(JNIEnv *env, jobject array, jsize index, jobject val) nogil

        jobject (* NewBooleanArray)(JNIEnv *env, jsize len) nogil
        jobject (* NewByteArray)(JNIEnv *env, jsize len) nogil
        jobject (* NewCharArray)(JNIEnv *env, jsize len) nogil
        jobject (* NewShortArray)(JNIEnv *env, jsize len) nogil
        jobject (* NewIntArray)(JNIEnv *env, jsize len) nogil
        jobject (*NewLongArray)(JNIEnv *env, jsize len) nogil
        jobject (* NewFloatArray)(JNIEnv *env, jsize len) nogil
        jobject (* NewDoubleArray)(JNIEnv *env, jsize len) nogil

        jboolean * (* GetBooleanArrayElements)(JNIEnv *env, jobject array, jboolean *isCopy) nogil
        jbyte * (* GetByteArrayElements)(JNIEnv *env, jobject array, jboolean *isCopy) nogil
        jchar * (*GetCharArrayElements)(JNIEnv *env, jobject array, jboolean *isCopy) nogil
        jshort * (*GetShortArrayElements)(JNIEnv *env, jobject array, jboolean *isCopy) nogil
        jint * (* GetIntArrayElements)(JNIEnv *env, jobject array, jboolean *isCopy) nogil
        jlong * (* GetLongArrayElements)(JNIEnv *env, jobject array, jboolean *isCopy) nogil
        jfloat * (* GetFloatArrayElements)(JNIEnv *env, jobject array, jboolean *isCopy) nogil
        jdouble * (* GetDoubleArrayElements)(JNIEnv *env, jobject array, jboolean *isCopy) nogil

        void (*ReleaseBooleanArrayElements)(JNIEnv *env, jobject array, jboolean *elems, jint mode) nogil
        void (*ReleaseByteArrayElements)(JNIEnv *env, jobject array, jbyte *elems, jint mode) nogil
        void (*ReleaseCharArrayElements)(JNIEnv *env, jobject array, jchar *elems, jint mode) nogil
        void (*ReleaseShortArrayElements)(JNIEnv *env, jobject array, jshort *elems, jint mode) nogil
        void (*ReleaseIntArrayElements)(JNIEnv *env, jobject array, jint *elems, jint mode) nogil
        void (*ReleaseLongArrayElements)(JNIEnv *env, jobject array, jlong *elems, jint mode) nogil
        void (*ReleaseFloatArrayElements)(JNIEnv *env, jobject array, jfloat *elems, jint mode) nogil
        void (*ReleaseDoubleArrayElements)(JNIEnv *env, jobject array, jdouble *elems, jint mode) nogil

        void (* GetBooleanArrayRegion)(JNIEnv *env, jobject array, jsize start, 
                                       jsize l, jboolean *buf) nogil
        void (* GetByteArrayRegion)(JNIEnv *env, jobject array, jsize start, 
                                    jsize len, jbyte *buf) nogil
        void (*GetCharArrayRegion)(JNIEnv *env, jobject array, jsize start, 
                                   jsize len, jchar *buf) nogil
        void (* GetShortArrayRegion)(JNIEnv *env, jobject array, jsize start,
                                     jsize len, jshort *buf) nogil
        void (* GetIntArrayRegion)(JNIEnv *env, jobject array, jsize start,
                                   jsize len, jint *buf) nogil
        void (* GetLongArrayRegion)(JNIEnv *env, jobject array, jsize start,
                                    jsize len, jlong *buf) nogil
        void (* GetFloatArrayRegion)(JNIEnv *env, jobject array, jsize start,
                                     jsize len, jfloat *buf) nogil
        void (* GetDoubleArrayRegion)(JNIEnv *env, jobject array, jsize start,
                                      jsize len, jdouble *buf) nogil

        void (*SetBooleanArrayRegion)(JNIEnv *env, jobject array, jsize start, 
                                      jsize l, jboolean *buf) nogil
        void (*SetByteArrayRegion)(JNIEnv *env, jobject array, jsize start,
                                   jsize len, jbyte *buf) nogil
        void (*SetCharArrayRegion)(JNIEnv *env, jobject array, jsize start, jsize len,
                                   char *buf) nogil
        void (*SetShortArrayRegion)(JNIEnv *env, jobject array, jsize start, jsize len,
                                    jshort *buf) nogil
        void (*SetIntArrayRegion)(JNIEnv *env, jobject array, jsize start, jsize len,
                                  jint *buf) nogil
        void (*SetLongArrayRegion)(JNIEnv *env, jobject array, jsize start, jsize len,
                                   jlong *buf) nogil
        void (*SetFloatArrayRegion)(JNIEnv *env, jobject array, jsize start, jsize len,
                                    jfloat *buf) nogil
        void (*SetDoubleArrayRegion)(JNIEnv *env, jobject array, jsize start, jsize len,
                                     jdouble *buf) nogil

cdef extern from "mac_javabridge_utils.h":
    int MacStartVM(JavaVM **, JavaVMInitArgs *pVMArgs, char *class_name, 
                   char *path_to_libjvm, char *path_to_libjli) nogil
    void MacStopVM() nogil
    void MacRunLoopInit() nogil
    void MacRunLoopRun() nogil
    void MacRunLoopStop() nogil
    void MacRunLoopReset() nogil
    int MacIsMainThread() nogil
    void MacRunLoopRunInMode(double) nogil

# NOTE: its required to have a 'from *' after the 'extern' declaration
#       here, in order to avoid problems with cython on Cywin and MSYS
#       Windows environments. The 'from *' will make cython think the
#       declaration is from some header, so it avoids the __imp_ prefix
#       on the symbols. Otherwise linking will fail. For more details see
#       https://trac.sagemath.org/ticket/19868
cdef extern from *:
    void StopVM(JavaVM *vm) nogil
    int CreateJavaVM(JavaVM **pvm, void **pEnv, void *args) nogil

def mac_run_loop_init():
    MacRunLoopInit()

def mac_reset_run_loop():
    '''Reset the run loop's internal state so that it's ready to run
    '''
    with nogil:
        MacRunLoopReset()
        
def mac_enter_run_loop():
    '''Enter the run loop and stay there until mac_stop_run_loop is called
    
    This enters the main run loop in the main thread and stays in the
    run loop until some other thread calls MacStopRunLoop.
    '''
    with nogil:
        MacRunLoopRun()

def mac_poll_run_loop(timeout):
    MacRunLoopRunInMode(timeout)
    
def mac_stop_run_loop():
    '''Signal the run loop to stop
    
    Wait for the main thread to enter the run loop, if necessary, then
    signal the run loop to stop.
    '''
    with nogil:
        MacRunLoopStop()

def mac_is_main_thread():
    '''Return True if the current thread runs the main OS/X run loop
    
    '''
    return MacIsMainThread() != 0
    
#####################################################
#
# Threading
#
# Java environments are thread-specific and the Java
# VM is global. This section helps maintain each thread's
# Java environment as a thread-local variable shared with
# the Cython code and maintains the VM singleton.
# 
# In addition, there's a wakeup event that's used to
# communicate with the thread that's in charge of garbage-
# collection objects deleted on a thread without an environment.
#
#######################################################

__vm = None
__thread_local_env = threading.local()
__dead_objects = []
__wake_event = threading.Event()

def wait_for_wake_event():
    '''Wait for dead objects to be enqueued or other event on monitor thread'''
    __wake_event.wait()
    __wake_event.clear()
    
def set_wake_event():
    '''Wake up the monitor thread'''
    __wake_event.set()

def get_vm():
    global __vm
    if __vm is None:
        __vm = JB_VM()
    return __vm
    
def get_thread_local(key, default=None):
    if not hasattr(__thread_local_env, key):
        setattr(__thread_local_env, key, default)
    return getattr(__thread_local_env, key)
    
def set_thread_local(key, value):
    setattr(__thread_local_env, key, value)
    
def get_env():
    '''Get the environment for this thread'''
    return get_thread_local("env")
    
def jb_attach():
    '''Attach to this thread's environment'''
    assert __vm is not None
    assert get_env() is None
    assert __vm.is_active()
    set_thread_local("env", __vm.attach_as_daemon())
    return get_env()
    
def jb_detach():
    '''Detach from this thread's environment'''
    assert __vm is not None
    assert get_env() is not None
    set_thread_local("env", None)
    __vm.detach()
    
def jni_enter(env):
    '''Enter Python from Java
    
    :param env: pointer to JNIEnv wrapped in a PyCapsule
    
    Set this thread's environment to the one passed in through
    a JNI native call.
    '''
    env_stack = get_thread_local("envstack", None)
    if env_stack is None:
        env_stack = []
        set_thread_local("envstack", env_stack)
    old_env = get_env()
    if old_env is not None:
        env_stack.append(old_env)
    new_env = JB_Env()
    new_env.set_env(env)
    set_thread_local("env", new_env)

def jni_exit():
    '''Exit the JNI from Python'''
    env_stack = get_thread_local("envstack")
    if len(env_stack) == 0:
        set_thread_local("env", None)
    else:
        set_thread_local("env", env_stack.pop())

def jvm_enter(vm):
    '''Initialize the JVM on entry into Python
    
    :param vm: pointer to JavaVM wrapped in a PyCapsule
    
    Set the global Java VM.
    '''
    get_vm().set_vm(vm)
    
def reap():
    '''Reap all of the garbage-collected Java objects on the dead_objects list'''
    if len(__dead_objects) > 0:
        env = get_env()
        assert env is not None
        try:
            while True:
                to_die = __dead_objects.pop()
                env.dealloc_jobject(to_die)
        except IndexError:
            pass

cdef class JB_Object:
    '''Represents a Java object.'''
    cdef:
        jobject o
        gc_collect
    def __cinit__(self):
        self.o = NULL
        self.gc_collect = False
    def __repr__(self):
        return "<Java object at 0x%x>"%<int>(self.o)
        
    def __dealloc__(self):
        cdef:
            JB_Object alternate
        if not self.gc_collect:
            return
        env = get_env()
        if env is None:
            alternate = JB_Object()
            alternate.o = self.o
            __dead_objects.append(alternate)
            set_wake_event()
        else:
            env.dealloc_jobject(self)

    def addr(self):
        '''Return the address of the Java object as a string'''
        return str(<int>(self.o))
        
cdef class JB_Class:
    '''A Java class'''
    cdef:
        jclass c
    def __cinit__(self):
        self.c = NULL
    def __repr__(self):
        return "<Java class at 0x%x>"%<int>(self.c)

    def as_class_object(self):
        result = JB_Object()
        result.o = self.c
        return result

cdef class __JB_MethodID:
    '''A method ID as returned by get_method_id'''
    cdef:
        jmethodID id
        sig
        is_static
    def __cinit__(self):
        self.id = NULL
        self.sig = ''
        self.is_static = False

    def __repr__(self):
        return "<Java method with sig=%s at 0x%x>"%(self.sig,<int>(self.id))
        
cdef class __JB_FieldID:
    '''A field ID as returned by get_field_id'''
    cdef:
        jfieldID id
        sig
        is_static
    def __cinit__(self):
        self.id = NULL
        self.sig = ''
        self.is_static = False
    
    def __repr__(self):
        return "<Java field with sig=%s at 0x%x>"%(self.sig, <int>(self.id))

cdef fill_values(orig_sig, args, jvalue **pvalues):
    cdef:
        jvalue *values
        int i
        JB_Object jbobject
        JB_Class jbclass
        Py_UNICODE *usz

    sig = orig_sig
    values = <jvalue *>malloc(sizeof(jvalue)*len(args))
    pvalues[0] = values
    for i,arg in enumerate(args):
        if len(sig) == 0:
            free(<void *>values)
            return ValueError("# of arguments (%d) in call did not match signature (%s)"%
                              (len(args), orig_sig))
        if sig[0] == 'Z': #boolean
            values[i].z = 1 if arg else 0
            sig = sig[1:]
        elif sig[0] == 'B': #byte
            values[i].b = int(arg)
            sig = sig[1:]
        elif sig[0] == 'C': #char
            values[i].c = ord(arg[0])
            sig = sig[1:]
        elif sig[0] == 'S': #short
            values[i].s = int(arg)
            sig = sig[1:]
        elif sig[0] == 'I': #int
            values[i].i = int(arg) 
            sig = sig[1:]
        elif sig[0] == 'J': #long
            values[i].j = int(arg)
            sig = sig[1:]
        elif sig[0] == 'F': #float
            values[i].f = float(arg)
            sig = sig[1:]
        elif sig[0] == 'D': #double
            values[i].d = float(arg)
            sig = sig[1:]
        elif sig[0] == 'L' or sig[0] == '[': #object
            if isinstance(arg, JB_Object):
                 jbobject = arg
                 values[i].l = jbobject.o
            elif isinstance(arg, JB_Class):
                 jbclass = arg
                 values[i].l = jbclass.c
            elif arg is None:
                 values[i].l = NULL
            else:
                 free(<void *>values)
                 return ValueError("%s is not a Java object"%str(arg))
            if sig[0] == '[':
                 if len(sig) == 1:
                      raise ValueError("Bad signature: %s"%orig_sig)
                 non_bracket_ind = 1
                 try:
                      while sig[non_bracket_ind] == '[':
                           non_bracket_ind += 1
                 except IndexError:
                      raise ValueError("Bad signature: %s"%orig_sig)
                 if sig[non_bracket_ind] != 'L':
                     # An array of primitive type:
                     sig = sig[(non_bracket_ind+1):]
                     continue
            sig = sig[sig.find(';')+1:]
        else:
            return ValueError("Unhandled signature: %s"%orig_sig)
    if len(sig) > 0:
        return ValueError("Too few arguments (%d) for signature (%s)"%
                         (len(args), orig_sig))

cdef class JB_VM:
    '''Represents the Java virtual machine'''
    cdef JavaVM *vm
    
    def set_vm(self, capsule):
        '''Set the pointer to the JavaVM
        
        This is here to handle the case where Java is the boss and Python
        is being started from Java, e.g. from 
        org.cellprofiler.javabridge.CPython.
        
        :param capsule: an encapsulated pointer to the JavaVM
        '''
        if not PyCapsule_CheckExact(capsule):
            raise ValueError(
            "set_vm called with something other than a wrapped environment")
        self.vm = <JavaVM *>PyCapsule_GetPointer(capsule, NULL)
        if not self.vm:
            raise ValueError(
            "set_vm called with non-environment capsule")
        
    def is_active(self):
        '''Return True if JVM has been started, but not killed'''
        return self.vm != NULL
        
    def create(self, options):
        '''Create the Java VM'''
        cdef:
            JavaVMInitArgs args
            JNIEnv *env
            JB_Env jenv

        args.version = JNI_VERSION_1_4
        args.nOptions = len(options)
        args.options = <JavaVMOption *>malloc(sizeof(JavaVMOption)*args.nOptions)
        if args.options == NULL:
            raise MemoryError("Failed to allocate JavaVMInitArgs")
        options = [str(option) for option in options]
        optionutf8=[] # list for temporarily storing utf-8 copies of strings
        for i, option in enumerate(options):
            optionutf8.append(option.encode('utf-8'))
            args.options[i].optionString = optionutf8[-1]
        result = CreateJavaVM(&self.vm, <void **>&env, &args)
        free(args.options)
        if result != 0:
            raise RuntimeError("Failed to create Java VM. Return code = %d"%result)
        jenv = JB_Env()
        jenv.env = env
        set_thread_local("env", jenv)
        return jenv

    def create_mac(self, options, class_name, path_to_libjvm, path_to_libjli):
        '''Create the Java VM on OS/X in a different thread
        
        On the Mac, (assuming this works), you need to start a PThread 
        and do so in a very particular manner if you ever want to run UI
        code in Java and Python. This creates that thread and it then runs
        a runnable.
        
        org.cellprofiler.runnablequeue.RunnableQueue is a class that uses
        a queue to ferry runnables to this main thread. You can use that
        and then call RunnableQueue's static methods to run things on the
        main thread.
        
        You should run this on its own thread since it will not return until
        after the JVM exits.
        
        options - the option strings
        
        class_name - the name of the Runnable to run on the Java main thread
        
        path_to_libjvm - path to libjvm.dylib
        
        path_to_libjli - path to libjli.dylib
        '''
        class_name = str(class_name).encode("utf-8")
        path_to_libjvm = str(path_to_libjvm).encode("utf-8")
        path_to_libjli = str(path_to_libjli).encode("utf-8")
        cdef:
            JavaVMInitArgs args
            JNIEnv *env
            JB_Env jenv
            int result
            char *pclass_name = class_name
            char *ppath_to_libjvm = path_to_libjvm
            char *ppath_to_libjli = path_to_libjli
            JavaVM **pvm = &self.vm

        args.version = JNI_VERSION_1_4
        args.nOptions = len(options)
        args.options = <JavaVMOption *>malloc(sizeof(JavaVMOption)*args.nOptions)
        if args.options == NULL:
            raise MemoryError("Failed to allocate JavaVMInitArgs")
        options = [str(option).encode("utf-8") for option in options]
        for i, option in enumerate(options):
            args.options[i].optionString = option
        with nogil:
            result = MacStartVM(pvm, &args, pclass_name, ppath_to_libjvm, ppath_to_libjli)
        free(args.options)
        if result != 0:
            raise RuntimeError("Failed to create Java VM. Return code = %d"%result)
            
    def attach(self):
        '''Attach this thread to the VM returning an environment'''
        cdef:
            JNIEnv *env
            JB_Env jenv
        result = self.vm[0].AttachCurrentThread(self.vm, <void **>&env, NULL)
        if result != 0:
            raise RuntimeError("Failed to attach to current thread. Return code = %d"%result)
        jenv = JB_Env()
        jenv.env = env
        return jenv
        
    def attach_as_daemon(self):
        '''Attach this thread as a daemon thread'''
        cdef:
            JNIEnv *env
            JB_Env jenv
        result = self.vm[0].AttachCurrentThreadAsDaemon(self.vm, <void *>&env, NULL)
        if result != 0:
            raise RuntimeError("Failed to attach to current thread. Return code = %d"%result)
        jenv = JB_Env()
        jenv.env = env
        return jenv
        
    def detach(self):
        '''Detach this thread from the VM'''
        self.vm[0].DetachCurrentThread(self.vm)
    
    def destroy(self):
        if self.vm != NULL:
            StopVM(self.vm)
            self.vm = NULL
    
cdef class JB_Env:
    '''
    Represents the Java VM and the Java execution environment as
    returned by JNI_CreateJavaVM.

    '''
    cdef:
        JNIEnv *env

    def __init__(self):
        self.env = NULL
        
    def __repr__(self):
        return "<JB_Env at 0x%x>"%(<size_t>(self.env))
    
    def set_env(self, capsule):
        '''Set the JNIEnv to a memory address
        
        address - address as an integer representation of a string
        '''
        if not PyCapsule_CheckExact(capsule):
            raise ValueError(
            "set_env called with something other than a wrapped environment")
        self.env = <JNIEnv *>PyCapsule_GetPointer(capsule, NULL)
        if not self.env:
            raise ValueError(
            "set_env called with non-environment capsule")
        
    def __dealloc__(self):
        self.env = NULL
        
    def dealloc_jobject(self, JB_Object jbo):
        '''Deallocate an object as it goes out of scope
        
        DON'T call this externally.
        '''
        self.env[0].DeleteGlobalRef(self.env, jbo.o)
        jbo.gc_collect = False

    def get_version(self):
        '''Return the version number as a major / minor version tuple'''
        cdef:
            int version
        version = self.env[0].GetVersion(self.env)
        return (int(version / 65536), version % 65536)

    def find_class(self, name):
        '''Find a Java class by name

        :param name: the class name with "/" as the path separator, e.g. "java/lang/String"
        :return: a Java class object suitable for calls such as :py:meth:`.get_method_id`
        '''
        cdef:
            jclass c
            JB_Class result
        utf8name = name.encode('utf-8')
        c = self.env[0].FindClass(self.env, utf8name)
        if c == NULL:
            print("Failed to get class "+name)
            return
        cref = self.env[0].NewGlobalRef(self.env, c)
        if cref == NULL:
            return (None, MemoryError("Failed to make new global reference"))
        self.env[0].DeleteLocalRef(self.env, c)
        result = JB_Class()
        result.c = cref
        return result

    def get_object_class(self, JB_Object o):
        '''Return the class for an object
        
        :param o: a Java object
        :return: a Java class object suitable for calls such as :py:meth:`.get_method_id`
        '''
        cdef:
            jclass c
            JB_Class result
        c = self.env[0].GetObjectClass(self.env, o.o)
        result = JB_Class()
        result.c = c
        return result
        
    def is_instance_of(self, JB_Object o, JB_Class c):
        '''Return True if object is instance of class
        
        :param o: a Java object
        :param c: a Java class
        :return: True if o is an instance of c otherwise False
        '''
        result = self.env[0].IsInstanceOf(self.env, o.o, c.c)
        return result != 0

    def exception_occurred(self):
        '''Return a throwable if an exception occurred or None'''
        cdef:
            jobject t
        t = self.env[0].ExceptionOccurred(self.env)
        if t == NULL:
            return
        o, e = make_jb_object(self, t)
        if e is not None:
            raise e
        return o

    def exception_describe(self):
        '''Print a stack trace of the last exception to stderr'''
        self.env[0].ExceptionDescribe(self.env)

    def exception_clear(self):
        '''Clear the current exception'''
        self.env[0].ExceptionClear(self.env)

    def get_method_id(self, JB_Class c, name, sig):
        '''Find the method ID for a method on a class

        :param c: a class retrieved by find_class or get_object_class
        :param name: the method name
        :param sig: the calling signature,
                    e.g. "(ILjava/lang/String;)D" is a function that
                    returns a double and takes an integer, a long and
                    a string as arguments.

        '''
        cdef:
            jmethodID id
            __JB_MethodID result
        utf8name = name.encode('utf-8')
        utf8sig = sig.encode('utf-8')
        if c is None:
            raise ValueError("Class = None on call to get_method_id")
        id = self.env[0].GetMethodID(self.env, c.c, utf8name, utf8sig)
        if id == NULL:
            return
        result = __JB_MethodID()
        result.id = id
        result.sig = sig
        result.is_static = False
        return result

    def get_static_method_id(self, JB_Class c, name, sig):
        '''Find the method ID for a static method on a class

        :param c: a class retrieved by find_class or get_object_class
        :param name: the method name
        :param sig: the calling signature,
                    e.g. "(ILjava/lang/String;)D" is a function that
                    returns a double and takes an integer, a long and
                    a string as arguments.

        '''
        cdef:
            jmethodID id
            __JB_MethodID result
        utf8name = name.encode('utf-8')
        utf8sig = sig.encode('utf-8')
        id = self.env[0].GetStaticMethodID(self.env, c.c, utf8name, utf8sig)
        if id == NULL:
            return
        result = __JB_MethodID()
        result.id = id
        result.sig = sig
        result.is_static = True
        return result

    def from_reflected_method(self, JB_Object method, char *sig, is_static):
        '''Get a method_id given an instance of java.lang.reflect.Method
        
        :param method: a method, e.g. as retrieved from getDeclaredMethods
        :param sig: signature of method
        :param is_static: true if this is a static method
        '''
        cdef:
            jmethodID id
            __JB_MethodID result
        id = self.env[0].FromReflectedMethod(self.env, method.o)
        if id == NULL:
            return
        result = __JB_MethodID()
        result.id = id
        result.sig = sig
        result.is_static = is_static
        return result
        
    def call_method(self, JB_Object o, __JB_MethodID m, *args):
        '''Call a method on an object with arguments

        :param o: object in question
        :param m: the method ID from :py:meth:`.get_method_id`
        :param \\*args: the arguments to the method call. Arguments
                      should appear in the same order as the
                      signature. Arguments will be coerced into the
                      type of the signature.

        '''
        cdef:
            jvalue *values
            jobject this = o.o
            JNIEnv *jnienv = self.env
            jboolean zresult
            jbyte bresult
            jchar cresult
            jshort sresult
            jint iresult
            jlong jresult
            jfloat fresult
            jdouble dresult
            jobject oresult
            jmethodID m_id = m.id
        
        if m is None:
            raise ValueError("Method ID is None - check your method ID call")
        if m.is_static:
            raise ValueError("call_method called with a static method. Use"
                             " call_static_method instead")
        sig = m.sig  # m.sig should be unicode already, no need to decode
        if sig[0] != '(':
            raise ValueError("Bad function signature: %s"%m.sig)
        arg_end = sig.find(')')
        if arg_end == -1:
            raise ValueError("Bad function signature: %s"%m.sig)
        arg_sig = sig[1:arg_end]
        error = fill_values(arg_sig, args, &values)
        if error is not None:
            raise error
        sig = sig[arg_end+1:]
        #
        # Dispatch based on return code at end of sig
        #
        if sig == 'Z':
            with nogil:
                zresult = jnienv[0].CallBooleanMethodA(
                    jnienv, this, m_id, values)
            result = zresult != 0
        elif sig == 'B':
            with nogil:
                bresult = jnienv[0].CallByteMethodA(jnienv, this, m_id, values)
            result = bresult
        elif sig == 'C':
            with nogil:
                cresult = jnienv[0].CallCharMethodA(jnienv, this, m_id, values)
            result = unichr(cresult)
        elif sig == 'S':
            with nogil:
                sresult = jnienv[0].CallShortMethodA(jnienv, this, m_id, values)
            result = sresult
        elif sig == 'I':
            with nogil:
                iresult = jnienv[0].CallIntMethodA(jnienv, this, m_id, values)
            result = iresult
        elif sig == 'J':
            with nogil:
                jresult = jnienv[0].CallLongMethodA(jnienv, this, m_id, values)
            result = jresult
        elif sig == 'F':
            with nogil:
                fresult = jnienv[0].CallFloatMethodA(jnienv, this, m_id, values)
            result = fresult
        elif sig == 'D':
            with nogil:
                dresult = jnienv[0].CallDoubleMethodA(jnienv, this, m_id, values)
            result = dresult
        elif sig[0] == 'L' or sig[0] == '[':
            with nogil:
                oresult = jnienv[0].CallObjectMethodA(jnienv, this, m_id, values)
            if oresult == NULL:
                result = None
            else:
                result, e = make_jb_object(self, oresult)
                if e is not None:
                    raise e
        elif sig == 'V':
            with nogil:
                jnienv[0].CallVoidMethodA(jnienv, this, m_id, values)
            result = None
        else:
            free(<void *>values)
            raise ValueError("Unhandled return type. Signature = %s"%m.sig)
        free(<void *>values)
        return result

    def call_static_method(self, JB_Class c, __JB_MethodID m, *args):
        '''Call a static method on a class with arguments

        :param c: class holding the method (e.g. from :py:meth:`.find_class`)
        :param m: the method ID from :py:meth:`.get_static_method_id`
        :param args: the arguments to the method call. Arguments
                      should appear in the same order as the
                      signature. Arguments will be coerced into the
                      type of the signature.

        '''
        cdef:
            jvalue *values
            JNIEnv *jnienv = self.env
            jclass klass = c.c
            jboolean zresult
            jbyte bresult
            jchar cresult
            jshort sresult
            jint iresult
            jlong jresult
            jfloat fresult
            jdouble dresult
            jobject oresult
            jmethodID m_id = m.id
        
        if m is None:
            raise ValueError("Method ID is None - check your method ID call")
        if not m.is_static:
            raise ValueError("static_call_method called with an object method. Use call_method instead")
        sig = m.sig
        if sig[0] != '(':
            raise ValueError("Bad function signature: %s"%m.sig)
        arg_end = sig.find(')')
        if arg_end == -1:
            raise ValueError("Bad function signature: %s"%m.sig)
        arg_sig = sig[1:arg_end]
        error = fill_values(arg_sig, args, &values)
        if error is not None:
            raise error
        sig = sig[arg_end+1:]
        #
        # Dispatch based on return code at end of sig
        #
        if sig == 'Z':
            with nogil:
                zresult = jnienv[0].CallStaticBooleanMethodA(
                    jnienv, klass, m_id, values)
            result = zresult != 0
        elif sig == 'B':
            with nogil:
                bresult = jnienv[0].CallStaticByteMethodA(
                    jnienv, klass, m_id, values)
            result = bresult
        elif sig == 'C':
            with nogil:
                cresult = jnienv[0].CallStaticCharMethodA(
                    jnienv, klass, m_id, values)
            result = unichr(cresult)
        elif sig == 'S':
            with nogil:
                sresult = jnienv[0].CallShortMethodA(jnienv, klass, m_id, values)
            result = sresult
        elif sig == 'I':
            with nogil:
                iresult = jnienv[0].CallIntMethodA(jnienv, klass, m_id, values)
            result = iresult
        elif sig == 'J':
            with nogil:
                jresult = jnienv[0].CallLongMethodA(jnienv, klass, m_id, values)
            result = jresult
        elif sig == 'F':
            with nogil:
                fresult = jnienv[0].CallFloatMethodA(jnienv, klass, m_id, values)
            result = fresult
        elif sig == 'D':
            with nogil:
                dresult = jnienv[0].CallDoubleMethodA(jnienv, klass, m_id, values)
            result = dresult
        elif sig[0] == 'L' or sig[0] == '[':
            with nogil:
                oresult = jnienv[0].CallObjectMethodA(jnienv, klass, m_id, values)
            if oresult == NULL:
                result = None
            else:
                result, e = make_jb_object(self, oresult)
                if e is not None:
                    raise e
        elif sig == 'V':
            self.env[0].CallVoidMethodA(self.env, c.c, m.id, values)
            result = None
        else:
            free(<void *>values)
            raise ValueError("Unhandled return type. Signature = %s"%m.sig)
        free(<void *>values)
        return result

    def get_field_id(self, JB_Class c, name, sig):
        '''Get a field ID for a class
        
        :param c: class (from :py:meth:`.find_class` or similar)
        :param name: name of field
        :param sig: signature of field (e.g. Ljava/lang/String;)
        '''
        cdef:
            jfieldID id
            __JB_FieldID jbid
        
        utf8name = name.encode('utf-8')
        utf8sig = sig.encode('utf-8')

        id = self.env[0].GetFieldID(self.env, c.c, utf8name, utf8sig)
        if id == NULL:
            return None
        jbid = __JB_FieldID()
        jbid.id = id
        jbid.sig = sig
        jbid.is_static = False
        return jbid
        
    def get_object_field(self, JB_Object o, __JB_FieldID field):
        '''Return an object field

        :param o: the Java object to be accessed
        :param field: the field to be fetched (from :py:meth:`.get_field_id`)
        
        :return: the Java object or None if the field's value is null
        '''
        cdef:
            jobject subo
        subo = self.env[0].GetObjectField(self.env, o.o, field.id)
        if subo == NULL:
            return
        result, e = make_jb_object(self, subo)
        if e is not None:
            raise e
        return result
        
    def get_boolean_field(self, JB_Object o, __JB_FieldID field):
        '''Return a boolean field's value
        
        :param o: the Java object to be accessed
        :param field: the field to be fetched (from :py:meth:`.get_field_id`)
        
        :return: the field's value
        :rtype: bool
        '''
        return self.env[0].GetBooleanField(self.env, o.o, field.id) != 0
        
    def get_byte_field(self, JB_Object o, __JB_FieldID field):
        '''Return a byte field's value
        
        :param o: the Java object to be accessed
        :param field: the field to be fetched (from :py:meth:`.get_field_id`)
        
        :return: the field's value
        :rtype: int
        '''
        return self.env[0].GetByteField(self.env, o.o, field.id)
        
    def get_char_field(self, JB_Object o, __JB_FieldID field):
        '''Return a char field's value
        
        :param o: the Java object to be accessed
        :param field: the field to be fetched (from :py:meth:`.get_field_id`)
        
        :return: the char value stored in the class's field
        :rtype: unichr
        '''
        return unichr(self.env[0].GetCharField(self.env, o.o, field.id))

    def get_short_field(self, JB_Object o, __JB_FieldID field):
        '''Return a short field's value
        
        :param o: the Java object to be accessed
        :param field: the field to be fetched (from :py:meth:`.get_field_id`)
        
        :return: the field's value
        :rtype:  int
        '''
        return self.env[0].GetShortField(self.env, o.o, field.id)
        
    def get_int_field(self, JB_Object o, __JB_FieldID field):
        '''Return an int field's value
        
        :param o: the Java object to be accessed
        :param field: the field to be fetched (from :py:meth:`.get_field_id`)
        
        :return: the field's value
        :rtype:  int
        '''
        return self.env[0].GetIntField(self.env, o.o, field.id)
        
    def get_long_field(self, JB_Object o, __JB_FieldID field):
        '''Return a long field's value
        
        :param o: the Java object to be accessed
        :param field: the field to be fetched (from :py:meth:`.get_field_id`)
        
        :return: the field's value
        :rtype:  long
        '''
        return self.env[0].GetLongField(self.env, o.o, field.id)
        
    def get_float_field(self, JB_Object o, __JB_FieldID field):
        '''Return a float field's value
        
        :param o: the Java object to be accessed
        :param field: the field to be fetched (from :py:meth:`.get_field_id`)
        
        :return: the field's value
        :rtype:  float
        '''
        return self.env[0].GetFloatField(self.env, o.o, field.id)
        
    def get_double_field(self, JB_Object o, __JB_FieldID field):
        '''Return a double field's value
        
        :param o: the Java object to be accessed
        :param field: the field to be fetched (from :py:meth:`.get_field_id`)
        
        :return: the field's value
        :rtype:  float
        '''
        return self.env[0].GetDoubleField(self.env, o.o, field.id)
        
    def set_object_field(self, JB_Object o, __JB_FieldID field, JB_Object value):
        '''Set one of a Java object's object fields
        
        :param o: the Java object in question
        :param field: a field id retrieved from :py:meth:`.get_field_id`
        :param value: the Java object that will become the field's new value
        '''
        cdef:
            jobject jvalue = NULL if value is None else value.o
        self.env[0].SetObjectField(self.env, o.o, field.id, jvalue)
        
    def set_boolean_field(self, JB_Object o, __JB_FieldID field, value):
        '''Set one of a Java object's boolean fields
        
        :param o: the Java object in question
        :param field: a field id retrieved from :py:meth:`.get_field_id`
        :param value: the truth value (True or False)
        '''
        cdef:
            jboolean jvalue = 1 if value else 0
        self.env[0].SetBooleanField(self.env, o.o, field.id, jvalue)
        
    def set_byte_field(self, JB_Object o, __JB_FieldID field, value):
        '''Set one of a Java object's byte fields
        
        :param o: the Java object in question
        :param field: a field id retrieved from :py:meth:`.get_field_id`
        :param value: the field's new int value 
        '''
        cdef:
            jbyte jvalue = int(value)
        self.env[0].SetByteField(self.env, o.o, field.id, jvalue)
        
    def set_char_field(self, JB_Object o, __JB_FieldID field, value):
        '''Set one of a Java object's char fields
        
        :param o: the Java object in question
        :param field: a field id retrieved from :py:meth:`.get_field_id`
        :param value: should be convertible to unicode and at least 1 char long
        '''
        cdef:
            jchar jvalue = ord(value[0])
        self.env[0].SetCharField(self.env, o.o, field.id, jvalue)
        
    def set_short_field(self, JB_Object o, __JB_FieldID field, value):
        '''Set one of a Java object's short fields
        
        :param o: the Java object in question
        :param field: a field id retrieved from :py:meth:`.get_field_id`
        :param value: the value to set, should be castable using int()
        '''
        cdef:
            jshort jvalue = int(value)
        self.env[0].SetShortField(self.env, o.o, field.id, jvalue)
        
    def set_int_field(self, JB_Object o, __JB_FieldID field, value):
        '''Set one of a Java object's byte fields
        
        :param o: the Java object in question
        :param field: a field id retrieved from :py:meth:`.get_field_id`
        :param value: the value to set, should be castable using int()
        '''
        cdef:
            jint jvalue = int(value)
        self.env[0].SetIntField(self.env, o.o, field.id, jvalue)
        
    def set_long_field(self, JB_Object o, __JB_FieldID field, value):
        '''Set one of a Java object's long fields
        
        :param o: the Java object in question
        :param field: a field id retrieved from :py:meth:`.get_field_id`
        :param value: the value to set, should be castable using int()
        '''
        cdef:
            jlong jvalue = int(value)
        self.env[0].SetLongField(self.env, o.o, field.id, jvalue)
        
    def set_float_field(self, JB_Object o, __JB_FieldID field, value):
        '''Set one of a Java object's byte fields
        
        :param o: the Java object in question
        :param field: a field id retrieved from :py:meth:`.get_field_id`
        :param value: the value to set, should be castable using float()
        '''
        cdef:
            jfloat jvalue = float(value)
        self.env[0].SetFloatField(self.env, o.o, field.id, jvalue)
        
    def set_double_field(self, JB_Object o, __JB_FieldID field, value):
        '''Set one of a Java object's float fields
        
        :param o: the Java object in question
        :param field: a field id retrieved from :py:meth:`.get_field_id`
        :param value: the value to set, should be castable using float()
        '''
        cdef:
            jdouble jvalue = float(value)
        self.env[0].SetDoubleField(self.env, o.o, field.id, jvalue)

    def get_static_field_id(self, JB_Class c, name, sig):
        '''Look up a static field ID on a class

        :param c: the object's class (e.g. as retrieved from :py:meth:`.find_class`)
        :param name: the field's name
        :param sig: the signature of the field (e.g. "java/lang/String")
        
        :return: a field ID that can be used in calls to get and get static fields
        '''
        cdef:
            jfieldID id
            __JB_FieldID jbid
        
        utf8name = name.encode('utf-8')
        utf8sig = sig.encode('utf-8')
        id = self.env[0].GetStaticFieldID(self.env, c.c, utf8name, utf8sig)
        if id == NULL:
            return None
        jbid = __JB_FieldID()
        jbid.id = id
        jbid.sig = sig
        jbid.is_static = False
        return jbid
        
    def get_static_object_field(self, JB_Class c, __JB_FieldID field):
        '''Return an object field on a class
        
        :param c: the class (e.g. as retrieved from :py:meth:`.find_class`)
        :param field: a field ID retrieved from :py:meth:`.get_static_field_id`
        
        :return: the object stored in the class's static field
        :rtype: JB_Object
        '''
        cdef:
            jobject o
        o = self.env[0].GetStaticObjectField(self.env, c.c, field.id)
        if o == NULL:
            return
        result, e = make_jb_object(self, o)
        if e is not None:
            raise e
        return result
        
    def get_static_boolean_field(self, JB_Class c, __JB_FieldID field):
        '''Return a boolean static field's value
        
        :param c: the class (e.g. as retrieved from :py:meth:`.find_class`)
        :param field: a field ID retrieved from :py:meth:`.get_static_field_id`
        
        :return: the boolean value stored in the class's static field
        :rtype: bool
        '''
        return self.env[0].GetStaticBooleanField(self.env, c.c, field.id) != 0
        
    def get_static_char_field(self, JB_Class c, __JB_FieldID field):
        '''Return a char static field's value
        
        :param c: the class (e.g. as returieved from :py:meth:`.find_class`)
        :param field: a field ID retrieved from :py:meth:`.get_static_field_id`
        
        :return: the char value stored in the class's static field
        :rtype: unichr
        '''
        return unichr(self.env[0].GetStaticCharField(self.env, c.c, field.id))
        
    def get_static_byte_field(self, JB_Class c, __JB_FieldID field):
        '''Return a byte static field's value
        
        :param c: the class (e.g. as retrieved from :py:meth:`.find_class`)
        :param field: a field ID retrieved from :py:meth:`.get_static_field_id`
        
        :return: the byte value stored in the class's static field
        :rtype: int
        '''
        return self.env[0].GetStaticByteField(self.env, c.c, field.id)
        
    def get_static_short_field(self, JB_Class c, __JB_FieldID field):
        '''Return a short static field's value
        
        :param c: the class (e.g. as retrieved from :py:meth:`.find_class`)
        :param field: a field ID retrieved from :py:meth:`.get_static_field_id`
        
        :return: the short stored in the class's static field
        :rtype: JB_Object
        '''
        return self.env[0].GetStaticShortField(self.env, c.c, field.id)
        
    def get_static_int_field(self, JB_Class c, __JB_FieldID field):
        '''Return an int field's value
        
        :param c: the class (e.g. as retrieved from :py:meth:`.find_class`)
        :param field: a field ID retrieved from :py:meth:`.get_static_field_id`
        
        :return: the integer value stored in the class's static field
        :rtype: int
        '''
        return self.env[0].GetStaticIntField(self.env, c.c, field.id)
        
    def get_static_long_field(self, JB_Class c, __JB_FieldID field):
        '''Return a long field's value
        
        :param c: the class (e.g. as retrieved from :py:meth:`.find_class`)
        :param field: a field ID retrieved from :py:meth:`.get_static_field_id`
        
        :return: the long value stored in the class's static field
        :rtype: long
        '''
        return self.env[0].GetStaticLongField(self.env, c.c, field.id)
        
    def get_static_float_field(self, JB_Class c, __JB_FieldID field):
        '''Return a float field's value
        
        :param c: the class (e.g. as retrieved from :py:meth:`.find_class`)
        :param field: a field ID retrieved from :py:meth:`.get_static_field_id`
        
        :return: the float value stored in the class's static field
        :rtype: float
        '''
        return self.env[0].GetStaticFloatField(self.env, c.c, field.id)
        
    def get_static_double_field(self, JB_Class c, __JB_FieldID field):
        '''Return a double field's value
        
        :param c: the class (e.g. as retrieved from :py:meth:`.find_class`)
        :param field: a field ID retrieved from :py:meth:`.get_static_field_id`
        
        :return: the double value stored in the class's static field
        :rtype: float
        '''
        return self.env[0].GetStaticDoubleField(self.env, c.c, field.id)
        
    def set_static_object_field(self, JB_Class c, __JB_FieldID field, JB_Object o):
        '''Set a static object field in a class
        
        :param c: the class in question, e.g. as retrieved from :py:meth:`.find_class`
        :param field: a field id retrieved from :py:meth:'.get_static_field_id`
        :param o: the object that will become the field's new value
        '''
        cdef:
            jobject jvalue = NULL if o is None else o.o
        self.env[0].SetStaticObjectField(self.env, c.c, field.id, jvalue)
        
    def set_static_boolean_field(self, JB_Class c, __JB_FieldID field, value):
        '''Set a static boolean field in a class
        
        :param c: the class in question, e.g. as retrieved from :py:meth:`.find_class`
        :param field: a field id retrieved from :py:meth:'.get_static_field_id`
        :param value: a value that will be cast to bool and assigned to the field
        '''
        cdef:
            jboolean jvalue = 1 if value else 0
        self.env[0].SetStaticBooleanField(self.env, c.c, field.id, jvalue)
        
    def set_static_char_field(self, JB_Class c, __JB_FieldID field, value):
        '''Set a static char field in a class

        :param c: the class in question, e.g. as retrieved from :py:meth:`.find_class`
        :param field: a field id retrieved from :py:meth:'.get_static_field_id`
        :param value: a value that will be cast to a short and assigned to the field
        '''
        cdef:
            jchar jvalue = ord(value[0])
        self.env[0].SetStaticCharField(self.env, c.c, field.id, jvalue)
        
    def set_static_byte_field(self, JB_Class c, __JB_FieldID field, value):
        '''Set a static byte field in a class
        
        :param c: the class in question, e.g. as retrieved from :py:meth:`.find_class`
        :param field: a field id retrieved from :py:meth:'.get_static_field_id`
        :param value: a value that will be assigned to the field
        '''
        cdef:
            jbyte jvalue = int(value)
        self.env[0].SetStaticByteField(self.env, c.c, field.id, jvalue)
        
    def set_static_char_field(self, JB_Class c, __JB_FieldID field, value):
        '''Set a static char field in a class
        
        :param c: the class in question, e.g. as retrieved from :py:meth:`.find_class`
        :param field: a field id retrieved from :py:meth:'.get_static_field_id`
        :param value: a value that will be assigned to the field
        '''
        cdef:
            jchar jvalue = ord(value[0])
        self.env[0].SetStaticCharField(self.env, c.c, field.id, jvalue)
        
    def set_static_short_field(self, JB_Class c, __JB_FieldID field, value):
        '''Set a static short field in a class
        
        :param c: the class in question, e.g. as retrieved from :py:meth:`.find_class`
        :param field: a field id retrieved from :py:meth:'.get_static_field_id`
        :param value: a value that will be assigned to the field
        '''
        cdef:
            jshort jvalue = int(value)
        self.env[0].SetStaticShortField(self.env, c.c, field.id, jvalue)
        
    def set_static_int_field(self, JB_Class c, __JB_FieldID field, value):
        '''Set a static int field in a class
        
        :param c: the class in question, e.g. as retrieved from :py:meth:`.find_class`
        :param field: a field id retrieved from :py:meth:'.get_static_field_id`
        :param value: a value that will be assigned to the field
        '''
        cdef:
            jint jvalue = int(value)
        self.env[0].SetStaticIntField(self.env, c.c, field.id, jvalue)
        
    def set_static_long_field(self, JB_Class c, __JB_FieldID field, value):
        '''Set a static long field in a class
        
        :param c: the class in question, e.g. as retrieved from :py:meth:`.find_class`
        :param field: a field id retrieved from :py:meth:'.get_static_field_id`
        :param value: a value that will be assigned to the field
        '''
        cdef:
            jlong jvalue = int(value)
        self.env[0].SetStaticLongField(self.env, c.c, field.id, jvalue)
        
    def set_static_float_field(self, JB_Class c, __JB_FieldID field, value):
        '''Set a static float field in a class
        
        :param c: the class in question, e.g. as retrieved from :py:meth:`.find_class`
        :param field: a field id retrieved from :py:meth:'.get_static_field_id`
        :param value: a value that will be assigned to the field
        '''
        cdef:
            jfloat jvalue = float(value)
        self.env[0].SetStaticFloatField(self.env, c.c, field.id, jvalue)
        
    def set_static_double_field(self, JB_Class c, __JB_FieldID field, value):
        '''Set a static double field in a class
        
        :param c: the class in question, e.g. as retrieved from :py:meth:`.find_class`
        :param field: a field id retrieved from :py:meth:'.get_static_field_id`
        :param value: a value that will be assigned to the field
        '''
        cdef:
            jdouble jvalue = float(value)
        self.env[0].SetStaticDoubleField(self.env, c.c, field.id, jvalue)

    def new_object(self, JB_Class c, __JB_MethodID m, *args):
        '''Call a class constructor with arguments

        :param c: class in question
        :param m: the method ID. You can get this by calling
                  get_method_id with a name of "<init>" and a return
                  type of V
        :param args: the arguments to the method call. Arguments
                      should appear in the same order as the
                      signature. Arguments will be coerced into the
                      type of the signature.

        '''
        cdef:
            jvalue *values
            jobject oresult
            jclass klass = c.c
            jmethodID m_id = m.id
            JNIEnv *jnienv = self.env

        sig = m.sig
        if sig[0] != '(':
            raise ValueError("Bad function signature: %s"%m.sig)
        arg_end = sig.find(')')
        if arg_end == -1:
            raise ValueError("Bad function signature: %s"%m.sig)
        arg_sig = sig[1:arg_end]
        error = fill_values(arg_sig, args, &values)
        if error is not None:
            raise error
        with nogil:
            oresult = jnienv[0].NewObjectA(jnienv, klass, m_id, values)
        free(values)
        if oresult == NULL:
            return
        result, e = make_jb_object(self, oresult)
        if e is not None:
            raise e
        return result

    def new_string(self, u):
        '''Turn a unicode string into a Java string object
        
        :param u: a unicode string (ideally) or a string that can be
                  encoded in utf-16 like this: u.encode("utf-16")
                  
        :return: a Java string object
        :rtype: JB_Object
        '''
        cdef:
            char *s
            jsize nchars
            jobject o
        u16 = u.encode("utf-16")
        nchars = len(u16) // 2 - 1
        s = u16
        o = self.env[0].NewString(self.env, <jchar *>s+1, nchars)
        if o == NULL:
            raise MemoryError("Failed to allocate string")
        jbo, e = make_jb_object(self, o)
        if e is not None:
             raise e
        return jbo
        
    def new_string_utf(self, s):
        '''Turn a Python string into a Java string object
        
        :param s: a Python string or unicode object
        :return: a Java string object
        :rtype: JB_Object
        '''
        cdef:
            jobject o
        o = self.env[0].NewStringUTF(self.env, s.encode('utf-8'))
        if o == NULL:
            raise MemoryError("Failed to allocate string")
        jbo, e = make_jb_object(self, o)
        if e is not None:
             raise e
        return jbo

    def get_string(self, JB_Object s):
        '''Turn a Java string object into a Python unicode string
        
        :param s: a Java object
        :return: the unicode string representation of the object
        :rtype: unicode
        '''
        cdef:
            jsize nchars = self.env[0].GetStringLength(self.env, s.o)
            const jchar *chars
            int byteorder = 0
        if <int>s.o == 0:
            return None
        chars = self.env[0].GetStringChars(self.env, s.o, NULL)
        result = PyUnicode_DecodeUTF16(
            <const char *>chars, nchars*2, "ignore", &byteorder)
        self.env[0].ReleaseStringChars(self.env, s.o, chars)
        return result

    def get_string_utf(self, JB_Object s):
        '''Turn a Java string object into a Python string

        :param s: a Java object
        :return: a string (Python 3) or unicode (Python 2) representation of s
        :rtype: str
        '''
        cdef:
           const char *chars 
        if <int> s.o == 0:
           return None
        chars = self.env[0].GetStringUTFChars(self.env, s.o, NULL)
        result = chars.decode('utf-8')
        self.env[0].ReleaseStringUTFChars(self.env, s.o, chars)
        return result

    def get_array_length(self, JB_Object array):
        '''Return the length of an array
        
        :param array: a Java array
        :return: the number of elements in the array
        '''
        return self.env[0].GetArrayLength(self.env, array.o)
        
    def get_boolean_array_elements(self, JB_Object array):
        '''Return the contents of a Java boolean array as a numpy array
        
        :param array: a Java boolean array
        '''
        cdef:
            np.ndarray[dtype=np.uint8_t, ndim=1, negative_indices=False, mode='c'] result
            char *data
            jsize alen = self.env[0].GetArrayLength(self.env, array.o)

        result = np.zeros(shape=(alen,),dtype=np.uint8)
        data = result.data
        self.env[0].GetBooleanArrayRegion(self.env, array.o, 0, alen, <jboolean *>data)
        return result.astype(np.bool8)
        
    def get_byte_array_elements(self, JB_Object array):
        '''Return the contents of a Java byte array as a numpy array

        array - a Java "byte []" array
        returns a 1-d numpy array of np.uint8s
        '''
        cdef:
            np.ndarray[dtype=np.uint8_t, ndim=1, negative_indices=False, mode='c'] result
            char *data
            jsize alen = self.env[0].GetArrayLength(self.env, array.o)

        result = np.zeros(shape=(alen,),dtype=np.uint8)
        data = result.data
        self.env[0].GetByteArrayRegion(self.env, array.o, 0, alen, <jbyte *>data)
        return result
        
    def get_short_array_elements(self, JB_Object array):
        '''Return the contents of a Java short array as a numpy array
        
        array - a Java "short []" array
        returns a 1-d numpy array of np.int16s
        '''
        cdef:
            np.ndarray[dtype=np.int16_t, ndim=1, negative_indices=False, mode='c'] result
            char *data
            jsize alen = self.env[0].GetArrayLength(self.env, array.o)

        result = np.zeros(shape=(alen,),dtype=np.int16)
        data = result.data
        self.env[0].GetShortArrayRegion(self.env, array.o, 0, alen, <jshort *>data)
        return result

    def get_int_array_elements(self, JB_Object array):
        '''Return the contents of a Java byte array as a numpy array
        
        array - a Java "int []" array
        returns a 1-d numpy array of np.int32s
        '''
        cdef:
            np.ndarray[dtype=np.int32_t, ndim=1, negative_indices=False, mode='c'] result
            char *data
            jsize alen = self.env[0].GetArrayLength(self.env, array.o)

        result = np.zeros(shape=(alen,),dtype=np.int32)
        data = result.data
        self.env[0].GetIntArrayRegion(self.env, array.o, 0, alen, <jint *>data)
        return result
    
    def get_long_array_elements(self, JB_Object array):
        '''Return the contents of a Java long array as a numpy array
        
        array - a Java "long []" array
        returns a 1-d numpy array of np.int64s
        '''
        cdef:
            np.ndarray[dtype=np.int64_t, ndim=1, negative_indices=False, mode='c'] result
            char *data
            jsize alen = self.env[0].GetArrayLength(self.env, array.o)

        result = np.zeros(shape=(alen,),dtype=np.int64)
        data = result.data
        self.env[0].GetLongArrayRegion(self.env, array.o, 0, alen, <jlong *>data)
        return result
        
    def get_float_array_elements(self, JB_Object array):
        '''Return the contents of a Java float array as a numpy array
        
        array - a Java "float []" array
        returns a 1-d numpy array of np.int32s
        '''
        cdef:
            np.ndarray[dtype=np.float32_t, ndim=1, negative_indices=False, mode='c'] result
            char *data
            jsize alen = self.env[0].GetArrayLength(self.env, array.o)

        result = np.zeros(shape=(alen,),dtype=np.float32)
        data = result.data
        self.env[0].GetFloatArrayRegion(self.env, array.o, 0, alen, <jfloat *>data)
        return result
        
    def get_double_array_elements(self, JB_Object array):
        '''Return the contents of a Java double array as a numpy array
        
        array - a Java "int []" array
        returns a 1-d numpy array of np.int32s
        '''
        cdef:
            np.ndarray[dtype=np.float64_t, ndim=1, negative_indices=False, mode='c'] result
            char *data
            jsize alen = self.env[0].GetArrayLength(self.env, array.o)

        result = np.zeros(shape=(alen,),dtype=np.float64)
        data = result.data
        self.env[0].GetDoubleArrayRegion(self.env, array.o, 0, alen, <jdouble *>data)
        return result
        
    def get_object_array_elements(self, JB_Object array):
        '''Return the contents of a Java object array as a list of wrapped objects'''
        cdef:
            jobject o
            jsize nobjects = self.env[0].GetArrayLength(self.env, array.o)
            int i
        result = []
        for i in range(nobjects):
            o = self.env[0].GetObjectArrayElement(self.env, array.o, i)
            if o == NULL:
                result.append(None)
            else:
                sub, e = make_jb_object(self, o)
                if e is not None:
                    raise e
                result.append(sub)
        return result
        
    def make_boolean_array(self, array):
        '''Create a java boolean [] array from the contents of a numpy array'''
        cdef:
            np.ndarray[dtype=np.uint8_t, ndim=1, negative_indices=False, mode='c'] barray = array.astype(np.bool8).astype(np.uint8)
            jobject o
            jsize alen = barray.shape[0]
            jboolean *data = <jboolean *>(barray.data)
        
        o = self.env[0].NewBooleanArray(self.env, alen)
        if o == NULL:
            raise MemoryError("Failed to allocate byte array of size %d"%alen)
        self.env[0].SetBooleanArrayRegion(self.env, o, 0, alen, data)
        result, e = make_jb_object(self, o)
        if e is not None:
            raise e
        return result
        
    def make_byte_array(self, np.ndarray[dtype=np.uint8_t, ndim=1, negative_indices=False, mode='c'] array):
        '''Create a java byte [] array from the contents of a numpy array'''
        cdef:
            jobject o
            jsize alen = array.shape[0]
            jbyte *data = <jbyte *>(array.data)
        
        o = self.env[0].NewByteArray(self.env, alen)
        if o == NULL:
            raise MemoryError("Failed to allocate byte array of size %d"%alen)
        self.env[0].SetByteArrayRegion(self.env, o, 0, alen, data)
        result, e = make_jb_object(self, o)
        if e is not None:
            raise e
        return result
        
    def make_short_array(self, np.ndarray[dtype=np.int16_t, ndim=1, negative_indices=False, mode='c'] array):
        '''Create a java short [] array from the contents of a numpy array'''
        cdef:
            jobject o
            jsize alen = array.shape[0]
            jshort *data = <jshort *>(array.data)
        
        o = self.env[0].NewShortArray(self.env, alen)
        if o == NULL:
            raise MemoryError("Failed to allocate short array of size %d"%alen)
        self.env[0].SetShortArrayRegion(self.env, o, 0, alen, data)
        result, e = make_jb_object(self, o)
        if e is not None:
            raise e
        return result
    
    def make_int_array(self, np.ndarray[dtype=np.int32_t, ndim=1, negative_indices=False, mode='c'] array):
        '''Create a java int [] array from the contents of a numpy array'''
        cdef:
            jobject o
            jsize alen = array.shape[0]
            jint *data = <jint *>(array.data)
        
        o = self.env[0].NewIntArray(self.env, alen)
        if o == NULL:
            raise MemoryError("Failed to allocate int array of size %d"%alen)
        self.env[0].SetIntArrayRegion(self.env, o, 0, alen, data)
        result, e = make_jb_object(self, o)
        if e is not None:
            raise e
        return result
        
    def make_long_array(self, np.ndarray[dtype=np.int64_t, ndim=1, negative_indices=False, mode='c'] array):
        '''Create a java long [] array from the contents of a numpy array'''
        cdef:
            jobject o
            jsize alen = array.shape[0]
            jlong *data = <jlong *>(array.data)
        
        o = self.env[0].NewLongArray(self.env, alen)
        if o == NULL:
            raise MemoryError("Failed to allocate long array of size %d"%alen)
        self.env[0].SetLongArrayRegion(self.env, o, 0, alen, data)
        result, e = make_jb_object(self, o)
        if e is not None:
            raise e
        return result
        
    def make_float_array(self, np.ndarray[dtype=np.float32_t, ndim=1, negative_indices=False, mode='c'] array):
        '''Create a java float [] array from the contents of a numpy array'''
        cdef:
            jobject o
            jsize alen = array.shape[0]
            jfloat *data = <jfloat *>(array.data)
        
        o = self.env[0].NewFloatArray(self.env, alen)
        if o == NULL:
            raise MemoryError("Failed to allocate float array of size %d"%alen)
        self.env[0].SetFloatArrayRegion(self.env, o, 0, alen, data)
        result, e = make_jb_object(self, o)
        if e is not None:
            raise e
        return result
        
    def make_double_array(self, np.ndarray[dtype=np.float64_t, ndim=1, negative_indices=False, mode='c'] array):
        '''Create a java double [] array from the contents of a numpy array'''
        cdef:
            jobject o
            jsize alen = array.shape[0]
            jdouble *data = <jdouble *>(array.data)
        
        o = self.env[0].NewDoubleArray(self.env, alen)
        if o == NULL:
            raise MemoryError("Failed to allocate double array of size %d"%alen)
        self.env[0].SetDoubleArrayRegion(self.env, o, 0, alen, data)
        result, e = make_jb_object(self, o)
        if e is not None:
            raise e
        return result
        
    def make_object_array(self, int len, JB_Class klass):
        '''Create a java object [] array filled with all nulls
        
        len - # of elements in array
        klass - class of objects that will be stored
        '''
        cdef:
            jobject o
        o = self.env[0].NewObjectArray(self.env, len, klass.c, NULL)
        if o == NULL:
            raise MemoryError("Failed to allocate object array of size %d" % len)
        result, e = make_jb_object(self, o)
        if e is not None:
            raise e
        return result
        
    def set_object_array_element(self, JB_Object jbo, int index, JB_Object v):
        '''Set an element within an object array
        
        jbo - the object array
        index - the zero-based index of the element to set
        v - the value to be inserted
        '''
        if v is None:
            self.env[0].SetObjectArrayElement(self.env, jbo.o, index, NULL)
        else:
            self.env[0].SetObjectArrayElement(self.env, jbo.o, index, v.o)
        
    def make_jb_object(self, pCapsule):
        '''Wrap a java object in a javabridge object
        
        address - integer representation of the memory address, as a string
        '''
        cdef:
            jobject jobj
            JB_Object jbo
        if not PyCapsule_CheckExact(pCapsule):
            raise ValueError("Argument must be a jobject in a capsule")
        jobj = <jobject>PyCapsule_GetPointer(pCapsule, NULL)
        if not jobj:
            raise ValueError("Capsule did not contain a jobject")
        jbo = JB_Object()
        jbo.o = jobj
        jbo.gc_collect = False
        return jbo
        
cdef make_jb_object(JB_Env env, jobject o):
    '''Wrap a Java object in a JB_Object with appropriate reference handling
    
    The idea here is to take a temporary reference on the current local
    frame, get a global reference that will persist and can be accessed
    across threads, and then delete the local reference.
    '''
    cdef:
        jobject oref
        JB_Object jbo
    
    oref = env.env[0].NewGlobalRef(env.env, o)
    if oref == NULL:
        return (None, MemoryError("Failed to make new global reference"))
    env.env[0].DeleteLocalRef(env.env, o)
    jbo = JB_Object()
    jbo.o = oref
    jbo.gc_collect = True
    return (jbo, None)
