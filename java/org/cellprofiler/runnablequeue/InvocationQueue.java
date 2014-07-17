/** 
 * python-javabridge is licensed under the BSD license.  See the
 * accompanying file LICENSE for details.
 * 
 * Copyright (c) 2003-2009 Massachusetts Institute of Technology
 * Copyright (c) 2009-2013 Broad Institute
 * All rights reserved.
 *
 */

package org.cellprofiler.runnablequeue;
import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Method;
import java.lang.reflect.Proxy;
import java.util.ArrayList;
import java.util.UUID;
import java.util.concurrent.SynchronousQueue;

/**
 *
 * @author Lee Kamentsky
 *
 * This class provides a bridge between Java and Python for
 * handling the invocations made on a java.lang.reflect.Proxy.
 * The javabridge's InvocationHandlerService and Proxy can be used
 * to talk to the InvocationQueue to implement a proxy for an interface
 * that can be used as an argument for any method that requires
 * the interface. The invocation is passed as a message to the
 * service which then dispatches it to the registered handler of
 * that service.
 *
 * All of this is done with threads and queues. The result is not performant
 * and is not designed to be performant, but it's completely appropriate
 * for events that occur infrequently, like user interface interactions.
 *
 * A proxy providing the service of using this class would run a
 * loop like this:
 *
 *    try {
 *        while true {
 *            InvocationQueue.InvocationRequest req = iq.takeRequest();
 *            try {
 *                ... do something
 *                req.respond(response);
 *            } catch (InvocationQueueClosedException eiq) {
 *                break;
 *            } catch (InterruptedException eie) {
 *                throw eie;
 *            } catch (Throwable e) {
 *                try {
 *                    req.respondWithException(e);
 *                } catch(InvocationQueueClosedException(eiq2) {
 *                    break;
 *                }
 *            }
 *        }
 *    }
 *
 */
 public class InvocationQueue {
     private final SynchronousQueue<InvocationRequest> requestQueue =
         new SynchronousQueue<InvocationRequest>();
     private final SynchronousQueue<InvocationResponse> responseQueue =
         new SynchronousQueue<InvocationResponse>();
     private boolean isClosed = false;
     private final ArrayList<Thread> waitingThreads = new ArrayList<Thread>();
     /**
      *
      * An InvocationRequest is a message placed on a queue, representing
      * a request for an invocation of the given method on a proxy
      * for the interface using the supplied arguments
      */
     public class InvocationRequest {
         private final Object proxy;
         private final Method method;
         private final Object [] args;
         InvocationRequest(Object proxy, Method method, Object [] args) {
             this.proxy = proxy;
             this.method = method;
             this.args = args;
         }
         /**
          * @returns the object that is the target for the invocation.
          */
         public Object getProxy() { return proxy; }
         /**
          * @returns the method that should be invoked on the target.
          */
         public Method getMethod() { return method; }
         /**
          * @returns the number of arguments supplied
          */
         public int getArgCount() { return ( args == null)?0:args.length; }
         /**
          * Get one of the arguments supplied to the invocation.
          *
          * @param index the index of the argument to be fetched
          * @returns the indexed argument
          */
         public Object getArg(int index) { return args[index]; }
         
         /**
          * Send the result of a successful invocation of the request
          * @param response - the response resulting from the invocation
          * @throws InterruptedException if this thread was interrupted
          *         before the response was taken from the response queue
          *         by the invoking thread.
          * @throws InvocationQueueClosedException if the invocation queue
          *         was closed before the requester could take the response.
          */
         public void respond(Object response) 
         throws InterruptedException, InvocationQueueClosedException {
             InvocationQueue.this.putResponse(
                 InvocationResponse.makeResultResponse(this, response));
         }
         /**
          * Send an exception to be thrown as a result of the invocation
          *
          * @param throwable the exception to be thrown
          * @throws InterruptedException if this thread was interrupted
          *         before the response was taken from the response queue
          *         by the invoking thread.
          */
         public void respondWithException(Throwable exception) 
         throws InterruptedException, InvocationQueueClosedException {
             InvocationQueue.this.putResponse(
             InvocationResponse.makeExceptionResponse(this, exception));
         }
     };
     /**
      *
      * An InvocationResponse is a message placed on a queue, representing
      * a response for the invocation of a method.
      */
     static class InvocationResponse {
         private final InvocationRequest request;
         private final Object result;
         private final Throwable exception;
         protected InvocationResponse(
             InvocationRequest request, Object result, Throwable exception) {
             this.request = request;
             this.result = result;
             this.exception = exception;
         }
         /**
          * Create a response representing a successful invocation.
          * @param request the request representing the invocation that
          *        resulted in this response.
          * @param result the result of the invocation.
          */
         static InvocationResponse makeResultResponse(
             InvocationRequest request, Object result) {
             return new InvocationResponse(request, result, null);
         }
         /**
          * Create a response representing an invocation that resulted
          * in an exception being thrown.
          *
          * @param request the request representing the invocation that
          *        resulted in this response.
          * @param throwable the exception that was thrown by the invocation
          *        of the invocation request.
          */
         static InvocationResponse makeExceptionResponse(
             InvocationRequest request, Throwable throwable) {
             return new InvocationResponse(request, null, throwable);
         }
         /**
          * Get the request that resulted in this response
          *
          * @return the request that was invoked.
          */
         public InvocationRequest getRequest() {
             return request;
         }
         /**
          * Get the result of the invocation
          *
          * @return the result of invoking the request.
          * @throws Throwable the exception that was thrown in the course of invoking
          *         the request.
          */
         public Object getResult() throws Throwable {
             if (exception != null) throw exception;
             return result;
         }
     }
     /**
      * The ManagedInvocationHandler processes invocations by
      * placing them on the invocation queue to be handled by
      * whoever services that queue
      */
     public class ManagedInvocationHandler implements InvocationHandler {
         private final UUID identifier = UUID.randomUUID(); 
         public Object invoke(Object proxy, Method method, Object [] args) 
             throws Throwable {
             return InvocationQueue.this.doInvoke(proxy, method, args);
        }
        /**
         * Get the UUID that uniquely identifies the invocation
         * handler for the interface proxy.
         */
        public UUID getUUID() {
            return identifier;
        }
     }
         
     
     /**
      * An exception that is thrown if the InvocationQueue is used after
      * it has been closed.
      */
     public static class InvocationQueueClosedException extends Exception {
         InvocationQueueClosedException(String message) {
             super(message);
         }
     }
     
     public Object newInstance(ClassLoader loader,
                               Class<?> [] interfaces) 
         throws IllegalArgumentException {
         return Proxy.newProxyInstance(loader, interfaces, 
             new ManagedInvocationHandler());
     }
         
     Object doInvoke(Object proxy, Method method, Object [] args) 
     throws Throwable {
         synchronized(this) {
             if (isClosed) throw new InvocationQueueClosedException(
                  "The InvocationQueue was closed before processing the invocation");
             waitingThreads.add(Thread.currentThread());
         }
         try {
             requestQueue.put(new InvocationRequest(proxy, method, args));
             return responseQueue.take().getResult();
         } catch (InterruptedException e) {
             if (isClosed) {
                 throw new InvocationQueueClosedException(
                     "The InvocationQueue was closed before the response was received");
             } else {
                 throw e;
             }
         } finally {
             synchronized(this) {
                 if (! isClosed)
                    waitingThreads.remove(Thread.currentThread());
             }
         }
     }
     
     /**
      * Put an invocation response on the response queue
      *
      * @param response the response (either with the result or with an
      *        exception to be thrown) to the invocation request.
      * @throws InterruptedException if the thread is interrupted before
      *         the request is taken by the invoking thread.
      * @throws InvocationQueueClosedException if the queue is closed
      *         before making this call.
      */
     void putResponse(InvocationResponse response) 
     throws InterruptedException, InvocationQueueClosedException {
         /*
          * Atomic operation: either throw an exception to indicate
          * that the queue was closed or put the thread on the list
          * of responding threads so it can be interrupted with the
          * bad news.
          */
         boolean needToRemove = false;
         synchronized(this) {
            if (isClosed) throw new InvocationQueueClosedException(
                "InvocationQueue had been closed before putting response");
             waitingThreads.add(Thread.currentThread());
             needToRemove = true;
         }
         try {
             responseQueue.put(response);
         } catch (InterruptedException e) {
             synchronized(this) {
                 needToRemove = false;
                 if (isClosed) throw new InvocationQueueClosedException(
                     "InvocationQueue was closed while waiting for response to be taken");
                 waitingThreads.remove(Thread.currentThread());
             }
             throw e;
         } finally {
             if (needToRemove) {
                synchronized(this) {
                    if (! isClosed)
                        waitingThreads.remove(Thread.currentThread());
                }
             }
         }
     }
     /**
      * Take an invocation request from the request queue
      *
      * @return an invocation request
      * @throws InterruptedException if the thread is interrupted
      *         before receiving a request
      * @throws InvocationQueueClosedException if the queue was closed
      *         before a request was received.
      */
      public InvocationRequest takeRequest()
          throws InterruptedException, InvocationQueueClosedException {
         /*
          * Atomic operation: either throw an exception to indicate
          * that the queue was closed or put the thread on the list
          * of responding threads so it can be interrupted with the
          * bad news.
          */
         boolean needToRemove = false;
         synchronized(this) {
            if (isClosed) throw new InvocationQueueClosedException(
                "InvocationQueue had been closed before taking request");
             waitingThreads.add(Thread.currentThread());
             needToRemove = true;
         }
         try {
             return requestQueue.take();
         } catch (InterruptedException e) {
             synchronized(this) {
                 needToRemove = false;
                 if (isClosed) throw new InvocationQueueClosedException(
                     "InvocationQueue was closed while waiting for request");
                 waitingThreads.remove(Thread.currentThread());
             }
             throw e;
         } finally {
             if (needToRemove) {
                synchronized(this) {
                    if (! isClosed)
                        waitingThreads.remove(Thread.currentThread());
                }
             }
         }
      }
      /**
       * Close the queue.
       *
       * Any threads waiting for requests or responses will be interrupted,
       * triggering an InvocationQueueClosedException from the interface call
       * to put or take a request or response.
       * 
       * @throws InvocationQueueClosedException if the queue was closed
       *         prior to entering this call.
       */
      synchronized public void close()
          throws InvocationQueueClosedException {
          if (isClosed) throw new InvocationQueueClosedException(
              "The InvocationQueue is already closed");
          isClosed = true;
          for (Thread thread:waitingThreads) {
              try {
                  thread.interrupt();
              } catch (SecurityException e) {
                  /*
                   * Eat failures of this type silently...
                   */
              }
          }
          waitingThreads.clear();
      }
 }