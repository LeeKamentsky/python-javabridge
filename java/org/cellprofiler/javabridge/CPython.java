/* python-javabridge is licensed under the BSD license.  See the
 * accompanying file LICENSE for details.

 * Copyright (c) 2003-2009 Massachusetts Institute of Technology
 * Copyright (c) 2009-2015 Broad Institute
 * All rights reserved.
 */
 
package org.cellprofiler.javabridge;

import java.io.File;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.logging.Logger;
import java.lang.reflect.Field;

/**
 * @author Lee Kamentsky
 * 
 * The CPython class manages an in-process
 * C Python instance, allowing Java code to execute
 * and evaluate scripts.
 */
public class CPython {
	private static final Logger log = Logger.getLogger(CPython.class.getName());
	/**
	 * A StackFrame records a frame of a Python stack, 
	 * for instance as reported by a WrappedException 
	 */
	public static class StackFrame {
		/**
		 * The path to the Python file holding the code being
		 * executed by the frame
		 */
		public final String fileName;
		/**
		 * The line number being executed
		 */
		public final int lineNumber;
		/**
		 * The name of the function being executed
		 */
		public final String functionName;
		/**
		 * The text of the line of code at the line being executed.
		 */
		public final String codeContext;
		public StackFrame(String fileName, int lineNumber, String functionName, String codeContext) {
			this.fileName = fileName;
			this.lineNumber = lineNumber;
			this.functionName = functionName;
			this.codeContext = codeContext;
		}
	};
	/**
	 * A wrapping of a Python exception, thrown during
	 * evaluation or execution of a Python script.
	 */
	public static class WrappedException extends Exception {
		/**
		 * The CPython type of the exception, for instance as
		 * reported by "type(exception)".
		 */
		public final String type;
		/**
		 * The stack traceback from the point where the exception was raised.
		 * The frames are arranged with the immediate location of the exception
		 * as index zero and calling frames at successively higher indices.
		 */
		public final List<StackFrame> traceback;
		WrappedException(String message, String type, List<StackFrame> traceback) {
           super(message);
           this.type = type;
           this.traceback = Collections.unmodifiableList(traceback);
		}
	}
	static {
		final String pathSeparator = System.getProperty("path.separator");
		final String classPaths = System.getProperty("java.class.path");
		String oldLibraryPath = null;
		
		for (String classPath:classPaths.split(pathSeparator)) {
			if (classPath.toLowerCase().endsWith("cpython.jar")) {
				File file = new File(classPath);
				final String libraryPath = file.getParent(); 
				/*
				 * The following is based on:
				 * 
				 * http://stackoverflow.com/questions/15409223/adding-new-paths-for-native-libraries-at-runtime-in-java
				 */
				try {
					final Field usrPathsField = ClassLoader.class.getDeclaredField("usr_paths");
					usrPathsField.setAccessible(true);
					final String [] paths = (String[])usrPathsField.get(null);
					boolean hasPath = false;
					for (String path:paths) {
						if (path.equalsIgnoreCase(libraryPath)) {
							hasPath = true;
							break;
						}
					}
					if (! hasPath) {
						 final String[] newPaths = Arrays.copyOf(paths, paths.length + 1);
						 newPaths[newPaths.length-1] = libraryPath;
						 usrPathsField.set(null, newPaths);						
					}
				} catch (Exception e) {
					log.warning(e.getMessage());
				}
				System.setProperty("java.library.path", libraryPath);
				break;
			}
		}
		
		System.loadLibrary("java2cpython");
		if (oldLibraryPath != null) {
			System.setProperty("java.library.path", oldLibraryPath);
		}
	}
	/**
	 * Execute a Python script (synonym for CPython.exec needed because
	 * "exec" is a Python keyword.
	 */
	public void execute(String script) throws WrappedException {
		exec(script, null, null);
	}
	/**
	 * Execute a Python script (synonym for CPython.exec needed because
	 * "exec" is a Python keyword.
	 */
	public void execute(String script, Map<String, Object> locals, Map<String, Object> globals) 
		throws WrappedException {
		exec(script, locals, globals);
	}
	/**
	 * Execute a Python script
	 * 
	 * @param script - the Python to be executed
	 */
	public void exec(String script) throws WrappedException {
		exec(script, null, null);
	}
	/**
	 * Execute a Python script, passing a local and global execution context
	 * 
	 *  @param script - the Python script to be executed
	 *  @param locals - the execution context local to the execution frame of the script
	 *  @param globals - the execution context accessible by all frames of the script
	 *  
	 *  You can retrieve values by passing a container as one of the locals, for instance
	 *  
	 *  locals = new HashMap<String, Object>();
	 *  locals.put("answer", new ArrayList<Integer>());
	 *  new CPython().exec("import javabridge; janswer=javabridge.JWrapper(answer);janswer.add(1+1)");
	 *  assert(locals.get("answer").equals(2));
	 */
	public native void exec(String script, Map<String, Object> locals, Map<String, Object> globals)
			throws WrappedException;
 }