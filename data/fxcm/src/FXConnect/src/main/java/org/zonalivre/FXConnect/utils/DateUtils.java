package org.zonalivre.FXConnect.utils;

import java.util.Calendar;
import java.util.Date;
import java.text.ParseException;
import java.text.SimpleDateFormat;

public class DateUtils {
  public static final String DATE_FORMAT = "yyyy-MM-dd HH:mm:ss";

  public static String now() {
    Calendar cal = Calendar.getInstance();
    SimpleDateFormat sdf = new SimpleDateFormat(DATE_FORMAT);
    return sdf.format(cal.getTime());

  }
  
  public static Calendar strToCalendar(String strDate) throws ParseException {
	  SimpleDateFormat formatter = new SimpleDateFormat(DATE_FORMAT);
	  Date date = (Date) formatter.parse(strDate);
	  Calendar cal = Calendar.getInstance();
	  cal.setTime(date);
	  return cal;
  }
  
  public static String calendarToString(Calendar cal) {
	  SimpleDateFormat formatter = new SimpleDateFormat(DATE_FORMAT);
	  
	  return formatter.format(cal.getTime());
  }
}
