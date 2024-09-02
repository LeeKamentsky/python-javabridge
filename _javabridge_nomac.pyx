import _javabridge_osspecific

cdef extern from "jni.h":
    ctypedef long jint
    ctypedef unsigned char jboolean

    ctypedef struct JNIInvokeInterface_

    ctypedef JNIInvokeInterface_ *JavaVM

    ctypedef struct JNIInvokeInterface_:
         jint (*DestroyJavaVM)(JavaVM *vm) noexcept nogil
         jint (*AttachCurrentThread)(JavaVM *vm, void **penv, void *args) noexcept nogil
         jint (*DetachCurrentThread)(JavaVM *vm) noexcept nogil
         jint (*GetEnv)(JavaVM *vm, void **penv, jint version) noexcept nogil
         jint (*AttachCurrentThreadAsDaemon)(JavaVM *vm, void *penv, void *args) noexcept nogil
    jint JNI_CreateJavaVM(JavaVM **pvm, void **penv, void *args) noexcept nogil

cdef int MacStartVM(JavaVM **pvm, JavaVMInitArgs *pVMArgs, char *class_name) noexcept nogil:
    return -1

cdef void StopVM(JavaVM *vm) noexcept nogil:
    vm[0].DestroyJavaVM(vm)

cdef void MacRunLoopInit() noexcept nogil:
    pass

cdef void MacRunLoopRun() noexcept nogil:
    pass

cdef void MacRunLoopStop() noexcept nogil:
    pass

cdef void MacRunLoopReset() noexcept nogil:
    pass

cdef int MacIsMainThread() noexcept nogil:
    return 0

cdef void MacRunLoopRunInMode(double timeout) noexcept nogil:
    pass

cdef int CreateJavaVM(JavaVM **pvm, void **pEnv, void *args) noexcept nogil:
    return JNI_CreateJavaVM(pvm, pEnv, args)

