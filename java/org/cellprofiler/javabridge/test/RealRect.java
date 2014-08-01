// A class with public fields. This exists only in order to test
// the get_field() and set_field() function in the Javabridge.

package org.cellprofiler.javabridge.test;

public class RealRect {

	// -- Fields --

	public double x;
	public double y;
	public double width;
	public double height;
	public char f_char;
	public byte f_byte;
	public short f_short;
	public int f_int;
	public long f_long;
	public float f_float;
	public double f_double;
	public Object f_object;
	static public char fs_char;
	static public byte fs_byte;
	static public short fs_short;
	static public int fs_int;
	static public long fs_long;
	static public float fs_float;
	static public double fs_double;
	static public Object fs_object;

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
