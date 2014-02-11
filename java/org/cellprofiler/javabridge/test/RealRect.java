// A class with public fields. This exists only in order to test
// the get_field() and set_field() function in the Javabridge.

package org.cellprofiler.javabridge.test;

public class RealRect {

	// -- Fields --

	public double x;
	public double y;
	public double width;
	public double height;

	// -- Constructor --

	public RealRect() {
		// default constructor - allow all instance vars to be initialized to 0
	}

	public RealRect(final double x, final double y, final double width,
		final double height)
	{
		this.x = x;
		this.y = y;
		this.width = width;
		this.height = height;
	}
}
