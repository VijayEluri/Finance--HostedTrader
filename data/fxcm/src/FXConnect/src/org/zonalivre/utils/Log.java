package org.zonalivre.utils;


public class Log {

	public static void log(String s) {
		System.err.println("[" + DateUtils.now() + "]" + s);
	}
}
