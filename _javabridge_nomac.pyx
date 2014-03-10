import _javabridge_osspecific

cdef extern from "jni.h":
    ctypedef long jint
    ctypedef unsigned char jboolean

    ctypedef struct JNIInvokeInterface_

    ctypedef JNIInvokeInterface_ *JavaVM

    ctypedef struct JNIInvokeInterface_:
         jint (*DestroyJavaVM)(JavaVM *vm) nogil
         jint (*AttachCurrentThread)(JavaVM *vm, void **penv, void *args) nogil
         jint (*DetachCurrentThread)(JavaVM *vm) nogil
         jint (*GetEnv)(JavaVM *vm, void **penv, jint version) nogil
         jint (*AttachCurrentThreadAsDaemon)(JavaVM *vm, void *penv, void *args) nogil

cdef int MacStartVM(JavaVM **pvm, JavaVMInitArgs *pVMArgs, char *class_name) nogil:
    return -1
	
cdef void StopVM(JavaVM *vm) nogil:
    vm[0].DestroyJavaVM(vm)
	
cdef void MacRunLoopInit() nogil:
    pass
    
cdef void MacRunLoopRun() nogil:
    pass
	
cdef void MacRunLoopStop() nogil:
    pass
    
cdef void MacRunLoopReset() nogil:
    pass
    
cdef int MacIsMainThread() nogil:
    return 0
    
cdef void MacRunLoopRunInMode(double timeout) nogil:
    pass
