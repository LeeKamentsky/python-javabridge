
cdef extern from "jni.h":
    ctypedef long jint
    ctypedef unsigned char jboolean

    ctypedef struct JNIInvokeInterface_

    ctypedef JNIInvokeInterface_ *JavaVM


cdef extern void StopVM(JavaVM *vm)