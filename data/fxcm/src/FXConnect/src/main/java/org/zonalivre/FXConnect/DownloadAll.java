package org.zonalivre.FXConnect;
import java.text.ParseException;

public class DownloadAll {
	public static void main(String[] args) throws TimeoutException, ParseException {
		String username = args[0];
		String password = args[1];
		String server = args[2];
        String fxcmTimeframe = args[3];
        int numItemsToDownload = Integer.valueOf(args[4]);

    	FXLoadHistoricalData d = new FXLoadHistoricalData(username, password, server);
        d.setTimeframe(fxcmTimeframe);
        for (int i=5; i<args.length; i++) {
	    	d.getData(args[i], numItemsToDownload);
        }
    	//d.disconnect(); Disconnect sometimes fails and doesn't return due to ForexConnect API bug
	}
}
