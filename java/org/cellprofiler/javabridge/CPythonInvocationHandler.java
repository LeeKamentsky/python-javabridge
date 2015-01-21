/* python-javabridge is licensed under the BSD license.  See the
 * accompanying file LICENSE for details.

 * Copyright (c) 2003-2009 Massachusetts Institute of Technology
 * Copyright (c) 2009-2015 Broad Institute
 * All rights reserved.
 */

package org.cellprofiler.javabridge;

import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Method;
import java.util.Hashtable;
import java.util.ArrayList;
import org.cellprofiler.javabridge.CPython;

/**
 * @author Lee Kamentsky
 * 
 * The CPythonInvocationHandler reflects an invocation
 * to a Python object that implements the call interface
 */
public class CPythonInvocationHandler implements InvocationHandler {
	private final String ref_id;
	private final CPython cpython = new CPython();
	/**
	 *  Constructor
	 *  
	 *  @param ref_id the reference to the Python callable, for instance as
	 *                returned by javabridge.create_jref
	 */
	public CPythonInvocationHandler(String ref_id) {
		this.ref_id = ref_id;
	}
	@Override
	public Object invoke(Object proxy, Method method, Object [] args) throws Throwable {
		final String script = 
				"import javabridge\n" +
				String.format("result = javabridge.redeem_jref('%s')(proxy, method, args);\n", ref_id) +
				"javabridge.call(jresult, 'add', '(Ljava/lang/Object;)Z', result)";
		final Hashtable<String, Object> locals = new Hashtable();
		locals.put("proxy", proxy);
		locals.put("method", method);
		if (args == null) {
			args = new Object [0];
		}
		locals.put("args", args);
		ArrayList<Object> result = new ArrayList<Object>();
		locals.put("jresult", result);
		cpython.exec(script, locals, locals);
		return result.get(0);
	}
}