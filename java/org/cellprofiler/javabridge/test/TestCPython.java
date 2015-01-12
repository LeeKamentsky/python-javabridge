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
	
}
