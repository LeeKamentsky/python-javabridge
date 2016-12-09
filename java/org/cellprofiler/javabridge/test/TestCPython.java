/** 
 * python-javabridge is licensed under the BSD license.  See the
 * accompanying file LICENSE for details.
 * 
 * Copyright (c) 2003-2009 Massachusetts Institute of Technology
 * Copyright (c) 2009-2015 Broad Institute
 * All rights reserved.
 *
 */

package org.cellprofiler.javabridge.test;

import org.junit.Test;
import static org.junit.Assert.*;
import org.cellprofiler.javabridge.CPython;

public class TestCPython {
	@Test
	public void test_01_01_exec() {
		try {
			new CPython().exec("print 'Hello, world.'\n");
		} catch (CPython.WrappedException e) {
			fail();
		}
	}
	@Test
	public void test_02_01_threading() {
		/*
		 * Regression test for issue #104 - call into Python
		 * from Java, start a Python thread, attach to the Java VM.
		 * VM pointer wasn't being initialized, so it dies.
		 */
		String code = 
				"import javabridge\n" +
				"import threading\n" +
				"print 'yes I did run'\n" +
				"def do_something()\n" +
				"  print 'from inside thread'\n" +
				"  system = javabridge.JClassWrapper('java.lang.System')\n" +
				"  system.setProperty('foo', 'bar')\n" +
				"thread=threading.Thread(target=do_something)\n" +
				"thread.start()\n" +
				"thread.join()\n" +
				"print 'yes I did finish'\n";
		try {
			System.out.print(code);
			new CPython().exec(code);
		} catch (CPython.WrappedException e) {
			fail();
		}
		System.out.println("Yes I did return");
		assertEquals(System.getProperty("foo"), "bar");
	}
	
}
