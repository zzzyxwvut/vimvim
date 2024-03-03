class NumbersTests
{
	static {
		int O = 0;
		int OO = 00;
		int OxO = 0x0;

		int x = 0x12_345_678;
		int y = 0b01_01_01_01_01;
		int z = 0__1__2__3__4__5__6__7;

		// String.format("%a", -1.0)
		double minus_one_d = -0x1.0p0;

		double z_d = -0x.0p0;
		double y_d = 0xap1__0__0;
		double x_d = .0__1__2__3__4__5__6__7__8__9;
		double dot_O = .0;

		// JLS, §3.10.2:
		float max_dec_f = 3.4028235e38f;
		float max_hex_f = 0x1.fffffeP+127f;
		float min_dec_f = 1.4e-45f;
		float min_hex_f_a = 0x0.000002P-126f;
		float min_hex_f_b = 0x1.0P-149f;

		double max_dec_d = 1.7976931348623157e3__0__8;
		double max_hex_d = 0x1.f_ffff_ffff_ffffP+1023;
		double min_dec_d = 4.9e-3__2__4;
		double min_hex_d_a = 0x0.0_0000_0000_0001P-1022;
		double min_hex_d_b = 0x1.0P-1074;

		// JLS, §3.10.1:
		int max_hex = 0x7fff_ffff;
		int max_oct = 0177_7777_7777;
		int max_bin = 0b0111_1111_1111_1111_1111_1111_1111_1111;

		int min_hex = 0x8000_0000;
		int min_oct = 0200_0000_0000;
		int min_bin = 0b1000_0000_0000_0000_0000_0000_0000_0000;

		int minus_one_hex = 0xffff_ffff;
		int minus_one_oct = 0377_7777_7777;
		int minus_one_bin = 0b1111_1111_1111_1111_1111_1111_1111_1111;

		long max_hex_l = 0x7fff_ffff_ffff_ffffL;
		long max_oct_l = 07_7777_7777_7777_7777_7777L;
		long max_bin_l = 0b0111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111L;

		long min_hex_l = 0x8000_0000_0000_0000L;
		long min_oct_l = 010_0000_0000_0000_0000_0000L;
		long min_bin_l = 0b1000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000L;

		long minus_one_hex_l = 0xffff_ffff_ffff_ffffL;
		long minus_one_oct_l = 017_7777_7777_7777_7777_7777L;
		long minus_one_bin_l = 0b1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111L;
	}
}
