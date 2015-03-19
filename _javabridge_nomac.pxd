
cdef extern from "jni.h":
    ctypedef long jint
    ctypedef unsigned char jboolean

    ctypedef struct JNIInvokeInterface_

    ctypedef JNIInvokeInterface_ *JavaVM

    struct JavaVMInitArgs:
        jint version
        jint nOptions
        JavaVMOption *options
        jboolean ignoreUnrecognized
    ctypedef JavaVMInitArgs JavaVMInitArgs

    struct JavaVMOption:
        char *optionString
        void *extraInfo
    ctypedef JavaVMOption JavaVMOption

cdef extern int MacStartVM(JavaVM **pvm, JavaVMInitArgs *pVMArgs, char *class_name) nogil

cdef extern void StopVM(JavaVM *vm) nogil

cdef extern int CreateJavaVM(JavaVM **pvm, void **pEnv, void *args) nogil

cdef extern void MacRunLoopInit() nogil

cdef extern void MacRunLoopRun() nogil

cdef extern void MacRunLoopStop() nogil

cdef extern void MacRunLoopReset() nogil

cdef extern int MacIsMainThread() nogil

cdef extern void MacRunLoopRunInMode(double timeout) nogil