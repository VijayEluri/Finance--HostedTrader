package org.zonalivre;
import java.io.BufferedWriter;
import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintWriter;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Calendar;

import org.zonalivre.utils.DateUtils;

import com.fxcore2.O2GMarketDataSnapshotResponseReader;
import com.fxcore2.O2GRequest;
import com.fxcore2.O2GRequestFactory;
import com.fxcore2.O2GResponse;
import com.fxcore2.O2GResponseReaderFactory;
import com.fxcore2.O2GTimeframe;
import com.fxcore2.O2GTimeframeCollection;

public class FXLoadHistoricalData {
	private int timeframe;
	final private int iMaxItemsPerRequest = 300;
	
	private ForexConnect tradeStation;
	private O2GRequestFactory requestFactory ;
	private O2GResponseReaderFactory responseReaderFactory;
	private O2GTimeframeCollection timeFrames;
	O2GTimeframe timeFrame;
	

	public static void main(String[] args) throws TimeoutException, ParseException {
		//("GBD82697001", "8593", "Demo");
		//("7510107448", "4^Real", "Real");

		String username = args[0];
		String password = args[1];
		String server = args[2];
        String symbol = args[3];
        String fxcmTimeframe = args[4];
        int numItemsToDownload = Integer.valueOf(args[5]);

		FXLoadHistoricalData d = new FXLoadHistoricalData(username, password, server);
        d.setTimeframe(fxcmTimeframe);
		//d.getData("XAU/USD", "2011-08-21 00:00:00", "2011-08-23 00:00:00");
		d.getData(symbol, numItemsToDownload);
		d.disconnect();
	}
	
	public void setTimeframe(String timeframeFXCM) {
		if (timeframeFXCM.equals("m1")) {
			timeframe = 60;
		} else if (timeframeFXCM.equals("m5")) {
			timeframe = 300;
		} else if (timeframeFXCM.equals("H1")) {
			timeframe = 3600;
		} else if (timeframeFXCM.equals("D1")) {
			timeframe = 86400;
		} else if (timeframeFXCM.equals("W1")) {
			timeframe = 604800;
		} else {
			System.out.println("Dont know about FXCM timeframe: " + timeframeFXCM);
			System.exit(1);
		}
		
		timeFrame = timeFrames.get(timeframeFXCM);
	}

	public FXLoadHistoricalData(String username, String password, String server) throws TimeoutException {	
		tradeStation = new ForexConnect(username, password, server);
		requestFactory = tradeStation.getRequestFactory();
		
		responseReaderFactory = tradeStation.getResponseReaderFactory();
		timeFrames = requestFactory.getTimeFrameCollection();
		
		this.setTimeframe("m5");
	}
	
	public void disconnect() throws TimeoutException {
		tradeStation.logout();
	}
	
	public void getData(String instrument, String startDateStr, String endDateStr) throws ParseException, TimeoutException {
		Calendar startDate = DateUtils.strToCalendar(startDateStr);
		Calendar beginDate = (Calendar) startDate.clone();
		Calendar endDate = DateUtils.strToCalendar(endDateStr);
		boolean hasMoreDates = true;
		
        String FileName = instrument.replace("/", "") + "_" + timeframe;
        BufferedWriter outFile = null;
        
        try {
			outFile = new BufferedWriter(new FileWriter(FileName));
		} catch (IOException e) {
			e.printStackTrace();
			System.exit(5);
		}
        PrintWriter out = new PrintWriter(outFile);

        while(hasMoreDates) {
			O2GRequest marketDataRequest = requestFactory.createMarketDataSnapshotRequestInstrument(instrument, timeFrame, iMaxItemsPerRequest);
			requestFactory.fillMarketDataSnapshotRequestTime(marketDataRequest, beginDate, endDate, false);
			O2GResponse response = null;
			try {
				response = tradeStation.sendRequest(marketDataRequest);
			} catch (Exception e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
				System.exit(1);
			}
			
	        O2GMarketDataSnapshotResponseReader marketSnapshotReader = responseReaderFactory.createMarketDataSnapshotReader(response);
	        
	        SimpleDateFormat dateFormatter = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
	        Calendar date;
	        for (int i = marketSnapshotReader.size() - 1; i>=0 ; i--) {
	            date = marketSnapshotReader.getDate(i);
	            //date = converter.convert(date, O2GTimeConverterTimeZone.EST);
	            out.println(dateFormatter.format(
	            		date.getTime()) + "\t" +
	                    marketSnapshotReader.getAskOpen(i) + "\t" +
	                    marketSnapshotReader.getAskHigh(i) + "\t" +
	                    marketSnapshotReader.getAskLow(i) + "\t" +
	                    marketSnapshotReader.getAskClose(i));
	        }
	        
	        Calendar firstDate = DateUtils.strToCalendar(dateFormatter.format(marketSnapshotReader.getDate(0).getTime()));
	        if (marketSnapshotReader.size() >= iMaxItemsPerRequest && startDate.compareTo(firstDate) < 0) {
	        	endDate = (Calendar) firstDate.clone();
	        } else {
	        	hasMoreDates = false;
	        }
		}
        out.close();
	}
	
	
	public void getData(String instrument, int totalItemsToDownload) throws ParseException, TimeoutException {
        String FileName = instrument.replace("/", "") + "_" + timeframe;
        BufferedWriter outFile = null;
        Calendar beginDate = DateUtils.strToCalendar("1950-01-01 00:00:00");
        Calendar endDate = null;
        
        try {
			outFile = new BufferedWriter(new FileWriter(FileName));
		} catch (IOException e) {
			e.printStackTrace();
			System.exit(5);
		}
        PrintWriter out = new PrintWriter(outFile);

        while(totalItemsToDownload > 0) {
			O2GRequest marketDataRequest = requestFactory.createMarketDataSnapshotRequestInstrument(instrument, timeFrame, iMaxItemsPerRequest < totalItemsToDownload ? iMaxItemsPerRequest : totalItemsToDownload);
			requestFactory.fillMarketDataSnapshotRequestTime(marketDataRequest, beginDate, endDate, false);
			O2GResponse response = null;
			try {
				response = tradeStation.sendRequest(marketDataRequest);
			} catch (Exception e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
				System.exit(1);
			}
			
	        O2GMarketDataSnapshotResponseReader marketSnapshotReader = responseReaderFactory.createMarketDataSnapshotReader(response);
	        SimpleDateFormat dateFormatter = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
	        Calendar date;
	        for (int i = marketSnapshotReader.size() - 1; i>=0 ; i--) {
	            date = marketSnapshotReader.getDate(i);
	            //date = converter.convert(date, O2GTimeConverterTimeZone.EST);
	            out.println(dateFormatter.format(
	            		date.getTime()) + "\t" +
	                    marketSnapshotReader.getAskOpen(i) + "\t" +
	                    marketSnapshotReader.getAskHigh(i) + "\t" +
	                    marketSnapshotReader.getAskLow(i) + "\t" +
	                    marketSnapshotReader.getAskClose(i));
	        }
	        
	        Calendar firstDate = DateUtils.strToCalendar(dateFormatter.format(marketSnapshotReader.getDate(0).getTime()));
	        totalItemsToDownload = totalItemsToDownload - marketSnapshotReader.size();
	        if (totalItemsToDownload > 0) {
	        	endDate = (Calendar) firstDate.clone();
	        }
		}
        out.close();
	}
}