cdef extern from "jni.h":
    ctypedef long jint
    ctypedef unsigned char jboolean

    ctypedef struct JNIInvokeInterface_

    ctypedef JNIInvokeInterface_ *JavaVM

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


cdef extern from "mac_javabridge_utils.h":
    int MacStartVM(JavaVM **, JavaVMInitArgs *pVMArgs, char *class_name) nogil
    void MacStopVM() nogil
    void MacRunLoopInit() nogil
    void MacRunLoopRun() nogil
    void MacRunLoopStop() nogil
    void MacRunLoopReset() nogil
    int MacIsMainThread() nogil
    void MacRunLoopRunInMode(double) nogil

cdef extern void StopVM(JavaVM *vm)
cdef extern int CreateJavaVM(JavaVM **pvm, void **pEnv, void *args)
