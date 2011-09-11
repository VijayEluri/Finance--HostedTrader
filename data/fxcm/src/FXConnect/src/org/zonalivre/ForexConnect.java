package org.zonalivre;

import org.zonalivre.utils.DateUtils;
import org.zonalivre.utils.Log;

import com.fxcore2.Constants;
import com.fxcore2.IO2GResponseListener;
import com.fxcore2.IO2GSessionStatus;
import com.fxcore2.O2GAccountRow;
import com.fxcore2.O2GAccountsTableResponseReader;
import com.fxcore2.O2GOfferRow;
import com.fxcore2.O2GOffersTableResponseReader;
import com.fxcore2.O2GOrderResponseReader;
import com.fxcore2.O2GRequest;
import com.fxcore2.O2GRequestFactory;
import com.fxcore2.O2GRequestParamsEnum;
import com.fxcore2.O2GResponse;
import com.fxcore2.O2GResponseReaderFactory;
import com.fxcore2.O2GSession;
import com.fxcore2.O2GSessionStatusCode;
import com.fxcore2.O2GTableType;
import com.fxcore2.O2GTradeRow;
import com.fxcore2.O2GTradesTableResponseReader;
import com.fxcore2.O2GTransport;
import com.fxcore2.O2GValueMap;


public class ForexConnect implements IO2GSessionStatus, IO2GResponseListener {
	private O2GSession session;
	private boolean isLoggedIn = false;
	private boolean requestInProgress = false;
	private String currentRequestID = null;
	private String completedRequestID = null;
	private O2GResponse response = null;
	private String failReason = "";
	private boolean logoutComplete = false;
	private boolean loginFailed = false;
	private String loginFailedMessage = "";
	private long timeout = 20000;
	private int logLevel = 1;
	
	public ForexConnect(String username, String password, String AccountType) throws TimeoutException {
		session = O2GTransport.createSession();
		session.subscribeSessionStatus(this);
		session.subscribeResponse(this);

		session.login(username, password, "http://www.fxcorporate.com/Hosts.jsp", AccountType);
		long init = System.currentTimeMillis();
		while (!isLoggedIn) {
			try {
				Thread.sleep(10);
			} catch (InterruptedException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
			if (System.currentTimeMillis() - init > timeout) {
				throw new TimeoutException("Login");
			}
			if (loginFailed) {
				throw new RuntimeException(loginFailedMessage);
			}
		}
	}
	
	public void logout() throws TimeoutException {
		logoutComplete = false;
		session.logout();
		long init = System.currentTimeMillis();
		while (!logoutComplete) {
			try {
				Thread.sleep(10);
			} catch (InterruptedException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
			if (System.currentTimeMillis() - init > timeout) {
				throw new TimeoutException("logout");
			}
		}
	}
	
	public O2GResponse sendRequest(O2GRequest request) throws Exception {
		requestInProgress = true;
		response = null;
		currentRequestID = request.getRequestId();
		session.sendRequest(request);
		long init = System.currentTimeMillis();
		while (requestInProgress) {
			try {
				Thread.sleep(10);
			} catch (InterruptedException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
			if (System.currentTimeMillis() - init > timeout) {
				throw new TimeoutException("sendRequest");
			}
		}
		
		if (response == null) {
			throw new Exception("Request failed: " + failReason);
		}
		
		if (!completedRequestID.equals(currentRequestID)) {
			throw new Exception("RequestID was " + currentRequestID + "\nResponseID was for " + completedRequestID);
		}
		
		return response;
	}
	
	public String getTrades() throws Exception {
		O2GRequestFactory requestBuilder = session.getRequestFactory();
		O2GRequest request = requestBuilder.createRefreshTableRequest(O2GTableType.TRADES);
		O2GResponse response = this.sendRequest(request);
		O2GResponseReaderFactory responseReaderFactory = session.getResponseReaderFactory();
		O2GTradesTableResponseReader tradesTable = responseReaderFactory.createTradesTableReader(response);
		
		String output = new String("");
		for (int i = 0; i < tradesTable.size(); i++) {
			O2GTradeRow trade = tradesTable.getRow(i);
			O2GOfferRow offer = getOfferRow(Integer.parseInt(trade.getOfferID()));
			Boolean isLong = trade.getBuySell().equals(Constants.Buy);
			double baseCurrencyPL = ( (isLong ?  offer.getBid() - trade.getOpenRate() : trade.getOpenRate() - offer.getAsk()) * trade.getAmount() ); 
			output +=
					"- symbol: " + offer.getInstrument() + "\n" +
					"  id: " + trade.getTradeID() + "\n" +
					"  direction: " + (isLong ? "long" : "short") + "\n" +
					"  openPrice: " + trade.getOpenRate() + "\n" +
					"  size: " + trade.getAmount() +  "\n" +
					"  openDate: " + DateUtils.calendarToString(trade.getOpenTime()) + "\n" +
					"  pl: 0" + "\n"
					;
		}
		return output;
	}
	
	public O2GTradeRow getTrade(String tradeID) throws Exception {
		O2GRequestFactory requestBuilder = session.getRequestFactory();
		O2GRequest request = requestBuilder.createRefreshTableRequest(O2GTableType.TRADES);
		O2GResponse response = this.sendRequest(request);
		O2GResponseReaderFactory responseReaderFactory = session.getResponseReaderFactory();
		O2GTradesTableResponseReader tradesTable = responseReaderFactory.createTradesTableReader(response);

		for (int i = 0; i < tradesTable.size(); i++) {
			O2GTradeRow trade = tradesTable.getRow(i);
			if (tradeID.equals(trade.getTradeID())) {
				return trade;
			}
		}
		throw new Exception("TradeID = " + tradeID + " not found");
	}
	
	public O2GTradeRow getTradeByOrderID(String orderID) throws Exception {
		O2GRequestFactory requestBuilder = session.getRequestFactory();
		O2GRequest request = requestBuilder.createRefreshTableRequest(O2GTableType.TRADES);
		O2GResponse response = sendRequest(request);
		O2GResponseReaderFactory responseReaderFactory = session.getResponseReaderFactory();
		O2GTradesTableResponseReader tradesTable = responseReaderFactory.createTradesTableReader(response);

		for (int i = 0; i < tradesTable.size(); i++) {
			O2GTradeRow trade = tradesTable.getRow(i);
			if (orderID.equals(trade.getOpenOrderID())) {
				return trade;
			}
		}
		throw new Exception("OrderID = " + orderID + " not found");
	}
	
	private O2GOfferRow getOfferRow(int offerID) throws Exception {
		O2GRequestFactory requestBuilder = session.getRequestFactory();
		O2GRequest request = requestBuilder.createRefreshTableRequest(O2GTableType.OFFERS);
		O2GResponse response = sendRequest(request);
		O2GResponseReaderFactory responseReaderFactory = session.getResponseReaderFactory();
		O2GOffersTableResponseReader offersTable = responseReaderFactory.createOffersTableReader(response);
		
		for (int i = 0; i < offersTable.size(); i++) {
			O2GOfferRow offer = offersTable.getRow(i);
			if (Integer.parseInt(offer.getOfferID()) == offerID) {
				return offer;
			}
		}
		throw new Exception("offerID not found in offers table: " + offerID);
	}
	
	private O2GOfferRow getOfferRow(String symbol) throws Exception {
		O2GRequestFactory requestBuilder = session.getRequestFactory();
		O2GRequest request = requestBuilder.createRefreshTableRequest(O2GTableType.OFFERS);
		O2GResponse response = sendRequest(request);
		O2GResponseReaderFactory responseReaderFactory = session.getResponseReaderFactory();
		O2GOffersTableResponseReader offersTable = responseReaderFactory.createOffersTableReader(response);
		
		for (int i = 0; i < offersTable.size(); i++) {
			O2GOfferRow offer = offersTable.getRow(i);
			if (!symbol.equals(offer.getInstrument())) {
				continue;
			}
			return offer;
		}
		throw new Exception("Symbol not found in offers table: " + symbol);
	}
	
	private O2GAccountRow getAccountRow() throws Exception {
		return getAccountRow(0);
	}
	
	private O2GAccountRow getAccountRow(int accountIndex) throws Exception {
		O2GResponse response = session.getLoginRules().getTableRefeshResponse(O2GTableType.ACCOUNTS);
		O2GResponseReaderFactory responseReaderFactory = session.getResponseReaderFactory();
		O2GAccountsTableResponseReader accountsTable = responseReaderFactory.createAccountsTableReader(response);

		return accountsTable.getRow(accountIndex);
	}
	
	public double getAsk(String symbol) throws Exception {
		O2GOfferRow offer = getOfferRow(symbol);
		return offer.getAsk();
	}

	public double getBid(String symbol) throws Exception {
		O2GOfferRow offer = getOfferRow(symbol);
		return offer.getBid();
	}
	
	public int getContractMultiplier(String symbol) throws Exception {
		O2GOfferRow offer = getOfferRow(symbol);
		return offer.getContractMultiplier();
	}
	
	public String getContractCurrency(String symbol) throws Exception {
		O2GOfferRow offer = getOfferRow(symbol);
		return offer.getContractCurrency();
	}
	
	public O2GRequestFactory getRequestFactory() {
		return session.getRequestFactory();
	}
	
	public O2GResponseReaderFactory getResponseReaderFactory() {
		return session.getResponseReaderFactory();
	}
	
	@Override
	public void onRequestCompleted(String requestID, O2GResponse rsp) {
		completedRequestID = requestID;
		if (logLevel > 1) {
			Log.log("Request ID = " + requestID + " complete sucess");
		}
		response = rsp;
		requestInProgress = false;
	}

	@Override
	public void onRequestFailed(String requestID, String reason) {
		Log.log("Request ID = " + requestID + " complete fail");
		response = null;
		failReason = reason;
		requestInProgress = false;
	}

	@Override
	public void onTablesUpdates(O2GResponse arg0) {
		//Log.log("onTablesUpdates");
	}

	@Override
	public void onLoginFailed(String reason) {
		loginFailed = true;
		loginFailedMessage = reason;
	}

	@Override
	public void onSessionStatusChanged(O2GSessionStatusCode status) {
		if (logLevel > 1) {
			Log.log("Got session status = " + status.toString());
		}
		switch (status) {
			case	CONNECTING:
				break;
			case	CONNECTED:
				isLoggedIn = true;
				break;
			case	DISCONNECTED:
				isLoggedIn = false;
				logoutComplete = true;
				break;
			case	TRADING_SESSION_REQUESTED:
				break;
			case	PRICE_SESSION_RECONNECTING:
				break;
			case	RECONNECTING:
				break;
			case	SESSION_LOST:
				isLoggedIn = false;
				break;
		}
	}

	public void setLogLevel(int logLevel) {
		this.logLevel = logLevel;
	}

	public int getLogLevel() {
		return logLevel;
	}
	
	public String openMarket(String symbol, String Direction, int amount) throws Exception {
		O2GAccountRow account = getAccountRow();
		O2GOfferRow offer = getOfferRow(symbol);

		O2GRequestFactory requestBuilder = session.getRequestFactory();
		O2GValueMap valueMap = requestBuilder.createValueMap();
		valueMap.setString(O2GRequestParamsEnum.COMMAND, Constants.Commands.CreateOrder);
		valueMap.setString(O2GRequestParamsEnum.ORDER_TYPE, Constants.Order.TrueMarketOpen);
		valueMap.setString(O2GRequestParamsEnum.ACCOUNT_ID, account.getAccountID());
		valueMap.setString(O2GRequestParamsEnum.OFFER_ID, offer.getOfferID());
		valueMap.setString(O2GRequestParamsEnum.BUY_SELL, Direction);
		valueMap.setInt(O2GRequestParamsEnum.AMOUNT, amount);
		valueMap.setString(O2GRequestParamsEnum.CUSTOM_ID, "FXConnect OpenMarket");
		
		O2GRequest orderRequest = requestBuilder.createOrderRequest(valueMap);
		O2GResponse orderResponse = sendRequest(orderRequest);
		O2GResponseReaderFactory responseReaderFactory = session.getResponseReaderFactory();
		O2GOrderResponseReader orderResponseReader = responseReaderFactory.createOrderResponseReader(orderResponse);
		if (!orderResponseReader.isSuccessful()) {
			throw new RuntimeException(orderResponseReader.getErrorDescription());
		}
		
		O2GTradeRow trade = getTradeByOrderID(orderResponseReader.getOrderID());
		return trade.getTradeID() + " " + trade.getOpenRate();
	}
	
	public String closeMarket(String sTradeID, int amount) throws Exception {
		O2GAccountRow account = getAccountRow();
		O2GTradeRow trade = getTrade(sTradeID);

		O2GRequestFactory requestBuilder = session.getRequestFactory();
		O2GValueMap valueMap = requestBuilder.createValueMap();
		valueMap.setString(O2GRequestParamsEnum.COMMAND, Constants.Commands.CreateOrder);
		valueMap.setString(O2GRequestParamsEnum.ORDER_TYPE, Constants.Order.TrueMarketClose);
		valueMap.setString(O2GRequestParamsEnum.ACCOUNT_ID, account.getAccountID());
		valueMap.setString(O2GRequestParamsEnum.OFFER_ID, trade.getOfferID());
		valueMap.setString(O2GRequestParamsEnum.TRADE_ID, sTradeID);
		valueMap.setString(O2GRequestParamsEnum.BUY_SELL, (trade.getBuySell().equals(Constants.Sell) ? Constants.Buy : Constants.Sell));
		valueMap.setInt(O2GRequestParamsEnum.AMOUNT, amount);
		valueMap.setString(O2GRequestParamsEnum.CUSTOM_ID, "FXConnect CloseMarket");
		
		O2GRequest orderRequest = requestBuilder.createOrderRequest(valueMap);
		O2GResponse orderResponse = sendRequest(orderRequest);
		O2GResponseReaderFactory responseReaderFactory = session.getResponseReaderFactory();
		O2GOrderResponseReader orderResponseReader = responseReaderFactory.createOrderResponseReader(orderResponse);
		if (!orderResponseReader.isSuccessful()) {
			throw new RuntimeException(orderResponseReader.getErrorDescription());
		}
		return orderResponseReader.getOrderID();
	}
	
	public double getNav() throws Exception {
		return getAccountRow().getM2MEquity();
	}
	
	public double getBalance() throws Exception {
		return getAccountRow().getBalance();
	}
	
	public static void main(String[] args) throws Exception {
		String username = args[0];
		String password = args[1];
		String type = args[2];
		
		ForexConnect tradeStation = new ForexConnect(username, password, type);
		//String id = tradeStation.openMarket("EUR/USD", Constants.Buy, 10000);
		//String rv = tradeStation.closeMarket("10145053", 10000);
		//System.out.println(tradeStation.getTrades());
		System.out.println(tradeStation.getNav());
		/*Log.log("" + tradeStation.getNav());
		Log.log("" + tradeStation.getBalance());
		Log.log(
				tradeStation.getAsk("XAU/USD") + "\n" +
				tradeStation.getBid("USD/JPY") + "\n" + 
				"");*/
		tradeStation.logout();
	}
}
