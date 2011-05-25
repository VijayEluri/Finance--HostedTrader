/***********************************************************************
http://tangentsoft.net/wskfaq/examples/basics/threaded-server.html

 basic-server.cpp - Implements a fairly basic single-threaded Winsock 
    server program that waits for a connection, accepts it, echoes back
    any data it receives, and then goes back to listening when the
    client drops the connection.

 Compiling:
    VC++: cl -GX basic-server.cpp main.cpp ws-util.cpp wsock32.lib
    BC++: bcc32 basic-server.cpp main.cpp ws-util.cpp
    
 This program is hereby released into the public domain.  There is
 ABSOLUTELY NO WARRANTY WHATSOEVER for this product.  Caveat hacker.
***********************************************************************/

#include "ws-util.h"

#include <winsock.h>

#include <iostream>

#include <vector>

using namespace std;

#import "c:\\Programas\\Candleworks\\FXOrder2Go\\fxcore.dll" 

#include <iostream>
#include <sstream>
#include <time.h>

using namespace std;

template <class T>
bool from_string(T& t, 
                 const std::string& s, 
                 std::ios_base& (*f)(std::ios_base&))
{
  std::istringstream iss(s);
  return !(iss >> f >> t).fail();
}


bool g_IsRunning;
FXCore::ICoreAutPtr g_pCore;
FXCore::ITradeDeskAutPtr g_pTradeDesk;
FXCore::ITradingSettingsProviderAutPtr g_pTradingSettings;

const char* g_pcLogin;
const char* g_pcPassw;
const char* g_pcAcType;

using namespace FXCore;

bool initCore();
string CmdGetCurrentPrice(string , string );
string CmdGetNAV();
string CmdGetBaseUnit(string );
string CmdOpenMarketOrder(string , string , int );
string CmdCloseMarketOrder(string , int );
string CmdGetTrades();
string CmdGetInstruments();
string CmdGetBaseCurrency();
string convertSymbolFromFXCM(string symbol);
void CmdSetSymbolEnabled(string );
void CmdSetSymbolDisabled(string );


string sCommandData;
////////////////////////////////////////////////////////////////////////
// Constants

const int kBufferSize = 1025;
        

////////////////////////////////////////////////////////////////////////
// Prototypes

SOCKET SetUpListener(const char* pcAddress, int nPort);
SOCKET AcceptConnection(SOCKET ListeningSocket, sockaddr_in& sinRemote);
bool EchoIncomingPackets(SOCKET sd);


//// DoWinsock /////////////////////////////////////////////////////////
// The module's driver function -- we just call other functions and
// interpret their results.


void CheckTradeDeskLogin() {
	if (!g_pTradeDesk->IsLoggedIn()) {
		g_pTradeDesk->Login(g_pcLogin, g_pcPassw, "http://www.fxcorporate.com/Hosts.jsp", g_pcAcType);
	}
}

int DoWinsock(const char* pcAddress, int nPort, const char* pcLogin, const char* pcPassw, const char* pcAcType) {

	g_pcLogin = pcLogin;
	g_pcPassw = pcPassw;
	g_pcAcType = pcAcType;

	g_IsRunning = true;
	g_pCore = 0;
	g_pTradeDesk = 0;
	g_pTradingSettings = 0;

	if (!initCore()) exit(1);
	g_pTradeDesk = g_pCore->CreateTradeDesk("trader");

    try {
		g_pTradeDesk->Login(pcLogin, pcPassw, "http://www.fxcorporate.com/Hosts.jsp", pcAcType);
	}
	catch(_com_error e) {
		cout << "Login error: " << e.Description() << endl ;
		exit(1);
	}
	g_pTradingSettings = g_pTradeDesk->TradingSettingsProvider;

	// Begin listening for connections
    cout << "Establishing the listener..." << endl;
    SOCKET ListeningSocket = SetUpListener(pcAddress, htons(nPort));
    if (ListeningSocket == INVALID_SOCKET) {
        cout << endl << WSAGetLastErrorMessage("establish listener") << 
                endl;
        return 3;
    }

    // Spin forever handling clients
    while (g_IsRunning) {
        // Wait for a connection, and accepting it when one arrives.
        cout << "Waiting for a connection..." << flush;
        sockaddr_in sinRemote;
        SOCKET sd = AcceptConnection(ListeningSocket, sinRemote);
        if (sd != INVALID_SOCKET) {
            cout << "Accepted connection from " <<
                    inet_ntoa(sinRemote.sin_addr) << ":" <<
                    ntohs(sinRemote.sin_port) << "." << endl;
        }
        else {
            cout << endl << WSAGetLastErrorMessage(
                    "accept connection") << endl;
            return 3;
        }
        
		sCommandData.clear();
        if (EchoIncomingPackets(sd)) {
            // Successfully bounced all connections back to client, so
            // close the connection down gracefully.
            cout << "Shutting connection down..." << flush;
            if (ShutdownConnection(sd)) {
                cout << "Connection is down." << endl;
            }
            else {
                cout << endl << WSAGetLastErrorMessage(
                        "shutdown connection") << endl;
                return 3;
            }
        }
        else {
            cout << endl << WSAGetLastErrorMessage(
                    "echo incoming packets") << endl;
            //return 3;
        }
    }

#if defined(_MSC_VER)
    return 0;       // warning eater
#endif
}


//// SetUpListener /////////////////////////////////////////////////////
// Sets up a listener on the given interface and port, returning the
// listening socket if successful; if not, returns INVALID_SOCKET.

SOCKET SetUpListener(const char* pcAddress, int nPort)
{
    u_long nInterfaceAddr = inet_addr(pcAddress);
    if (nInterfaceAddr != INADDR_NONE) {
        SOCKET sd = socket(AF_INET, SOCK_STREAM, 0);
        if (sd != INVALID_SOCKET) {
            sockaddr_in sinInterface;
            sinInterface.sin_family = AF_INET;
            sinInterface.sin_addr.s_addr = nInterfaceAddr;
            sinInterface.sin_port = nPort;
            if (bind(sd, (sockaddr*)&sinInterface, 
                    sizeof(sockaddr_in)) != SOCKET_ERROR) {
                listen(sd, 1);
                return sd;
            }
        }
    }

    return INVALID_SOCKET;
}


//// AcceptConnection //////////////////////////////////////////////////
// Waits for a connection on the given socket.  When one comes in, we
// return a socket for it.  If an error occurs, we return 
// INVALID_SOCKET.

SOCKET AcceptConnection(SOCKET ListeningSocket, sockaddr_in& sinRemote)
{
    int nAddrSize = sizeof(sinRemote);
    return accept(ListeningSocket, (sockaddr*)&sinRemote, &nAddrSize);
}

void Tokenize(const string& str,
                      vector<string>& tokens,
                      const string& delimiters = " ")
{
    // Skip delimiters at beginning.
    string::size_type lastPos = str.find_first_not_of(delimiters, 0);
    // Find first "non-delimiter".
    string::size_type pos     = str.find_first_of(delimiters, lastPos);

    while (string::npos != pos || string::npos != lastPos)
    {
        // Found a token, add it to the vector.
        tokens.push_back(str.substr(lastPos, pos - lastPos));
        // Skip delimiters.  Note the "not_of"
        lastPos = str.find_first_not_of(delimiters, pos);
        // Find next "non-delimiter"
        pos = str.find_first_of(delimiters, lastPos);
    }
}


//// EchoIncomingPackets ///////////////////////////////////////////////
// Bounces any incoming packets back to the client.  We return false
// on errors, or true if the client closed the socket normally.

string ProcessCommand(string sCmd) {
	string sResponse;
	vector<string> tokens;

	Tokenize(sCmd, tokens, " ");
	try {
		if (tokens.size() == 0) {
			throw "Empty command";
		}

		if (tokens[0].compare("trades") == 0) {
			sResponse = CmdGetTrades();
		} else if (tokens[0].compare("ask") == 0) {
			if (tokens.size() != 2) {
				throw "Expected 1 argument";
			}
			sResponse = CmdGetCurrentPrice(tokens[1].c_str(), "Ask");
		} else if (tokens[0].compare("bid") == 0) {
			if (tokens.size() != 2) {
				throw "Expected 1 argument";
			}
			sResponse = CmdGetCurrentPrice(tokens[1].c_str(), "Bid");
		} else if (tokens[0].compare("baseunit") == 0) {
			if (tokens.size() != 2) {
				throw "Expected 1 argument";
			}
			sResponse = CmdGetBaseUnit(tokens[1].c_str());
		} else if (tokens[0].compare("nav") == 0) {
			sResponse = CmdGetNAV();
		} else if (tokens[0].compare("openmarket") == 0) {
			int i;
			if (tokens.size() != 4) {
				throw "Expected 3 arguments";
			}
			if (!from_string<int>(i, tokens[3], std::dec)) {
				throw "argument 3 must be an integer";
			}
			sResponse = CmdOpenMarketOrder(tokens[1], tokens[2], i);
		} else if (tokens[0].compare("closemarket") == 0) {
			int i;
			if (tokens.size() != 3) {
				throw "Expected 2 arguments";
			}
			if (!from_string<int>(i, tokens[2], std::dec)) {
				throw "argument 2 must be an integer";
			}
			sResponse = CmdCloseMarketOrder(tokens[1], i);
		} else if (tokens[0].compare("basecurrency") == 0) {
            sResponse = CmdGetBaseCurrency();
		} else if (tokens[0].compare("instruments") == 0) {
            sResponse = CmdGetInstruments();
		} else if (tokens[0].compare("symbolenable") == 0) {
			if (tokens.size() != 2) {
				throw "Expected 1 argument";
			}
			CmdSetSymbolEnabled(tokens[1].c_str());
			sResponse = "200";
		} else if (tokens[0].compare("symboldisable") == 0) {
			if (tokens.size() != 2) {
				throw "Expected 1 argument";
			}
			CmdSetSymbolDisabled(tokens[1].c_str());
			sResponse = "200";
		} else if (tokens[0].compare("quit") == 0) {
			g_IsRunning = false;
			sResponse = "200";
		} else {
			sResponse = "404 ";
			sResponse.append(sCmd);
		}
		goto clean;
	}

	catch(const char* Message) {
		sResponse = "500 ";
		sResponse.append(Message);
	}

	catch (_com_error e) {
		sResponse = "500 ";
		sResponse.append((const char*) e.Description());
	}

	catch(...) {
		sResponse = "500 Unknown exception";
	}

	sResponse.append(" : ");
	sResponse.append(sCmd);

clean:
	sResponse.append("||THE_END||");
	cout << sResponse;
	return sResponse;
}

bool EchoIncomingPackets(SOCKET sd) {
    // Read data from client
    char acReadBuffer[kBufferSize];
    int nReadBytes;
	unsigned int pos;
    do {
		memset(acReadBuffer, 0, kBufferSize);
        nReadBytes = recv(sd, acReadBuffer, kBufferSize-1, 0); //Reading one less than kBufferSize guarantees acReadBuffer is NULL terminated
        if (nReadBytes > 0) {
            cout << "Received " << nReadBytes << 
                    " bytes from client." << endl;
        
            int nSentBytes = 0;

			sCommandData.append(acReadBuffer);
			pos = sCommandData.find('\n');
			if (pos != string::npos) {
				string sResponse = ProcessCommand(sCommandData.substr(0, pos)).append("\n");
				sCommandData.erase(0,pos+1);
				int s_len = sResponse.length();
				const char* sendBuffer = sResponse.c_str();

				while (nSentBytes < s_len) {
					int nTemp = send(sd, sendBuffer + nSentBytes,
							s_len - nSentBytes, 0);
					if (nTemp > 0) {
						cout << "Sent " << nTemp << 
								" bytes back to client." << endl;
						nSentBytes += nTemp;
					} else if (nTemp == SOCKET_ERROR) {
						return false;
					} else {
						// Client closed connection before we could reply to
						// all the data it sent, so bomb out early.
						cout << "Peer unexpectedly dropped connection!" << 
								endl;
						return true;
					}
				}
			}
        }
        else if (nReadBytes == SOCKET_ERROR) {
            return false;
        }
    } while (nReadBytes != 0 && g_IsRunning);

    return true;
}






bool initCore() {
    CoInitializeEx(NULL, COINIT_APARTMENTTHREADED);   
    
    //create core object    
    try
	{
		HRESULT hr = g_pCore.CreateInstance(__uuidof(CoreAut));
        if (FAILED(hr))
			cout << "Can't init Trading Engine" << endl;
	}
	catch(_com_error e)
	{
		cout << e.Description() << endl;
        return false;
	}

    return true;
}

FXCore::ITableAutPtr _GetAccountsTable() {
	FXCore::ITableAutPtr pAcctTable = g_pTradeDesk->FindMainTable("Accounts");
	long rowcount = pAcctTable->RowCount;
	if (rowcount == 0) {
		throw "No rows defined in Accounts table, cannot fetch AccountID and raise an open market order, perhaps this login belongs to a closed account ?";
	}
	return pAcctTable;
}

double GetAccountNAV() {
	FXCore::ITableAutPtr pAcctTable = _GetAccountsTable();
	_variant_t NAV = pAcctTable->CellValue(1,"Equity");
	return NAV.dblVal;
}

_bstr_t GetAccountID() {
	FXCore::ITableAutPtr pAcctTable = _GetAccountsTable();
	_variant_t AcctID = pAcctTable->CellValue(1,"AccountID"); //Assumes only one account
	
	return (_bstr_t) AcctID.bstrVal;
}


double GetCurrentPrice(string symbol, string sType) {
	CheckTradeDeskLogin();
	FXCore::IRowAutPtr offer = g_pTradeDesk->FindRowInTable("offers", "Instrument", symbol.c_str() );
	_variant_t rv = offer->CellValue(sType.c_str());
	return rv.dblVal;
}


string CmdGetCurrentPrice(string symbol, string sType) {
	ostringstream os;
	double price = GetCurrentPrice(symbol, sType);
	string rv = "200 ";
	os << price;
	rv.append(os.str());
	return rv;
}

string CmdGetNAV() {
	ostringstream os;
	double nav = GetAccountNAV();
	string rv = "200 ";
	os << nav;
	rv.append(os.str());
	return rv;
}

string CmdGetBaseUnit(string symbol) {
	ostringstream os;
	string rv = "200 ";
	CheckTradeDeskLogin();
	_bstr_t AcctID = GetAccountID();
	int baseUnit = g_pTradingSettings->GetBaseUnitSize(symbol.c_str(), AcctID);

	os << baseUnit;
	rv.append(os.str());
	return rv;
}

string CmdOpenMarketOrder(string symbol, string direction, int iAmount) {
	string sType;
	boolean bBuy;
	double dRate;
	string rv;
	_variant_t vOrderID = "", vDealerInt = "";
	ostringstream os;

	CheckTradeDeskLogin();
	_bstr_t AcctID = GetAccountID();

	if (direction.compare("long") == 0) {
		sType = "Ask";
		bBuy = true;
	} else {
		sType = "Bid";
		bBuy = false;
	}
	dRate = GetCurrentPrice(symbol, sType);
	g_pTradeDesk->CreateFixOrder2(g_pTradeDesk->FIX_OPEN, "", dRate, 0, "", AcctID, symbol.c_str(), bBuy, 
				iAmount, "", 0, &vOrderID, &vDealerInt);

	rv = "200 ";// + vOrderID.bstrVal;// + " " + dRate;
	_bstr_t _vTradeID = g_pTradeDesk->GetTradeByOrder(vOrderID.bstrVal);
	rv.append((const char *) _vTradeID );
	rv+=" ";

	os << dRate;
	rv+=os.str().c_str();
	return rv;
}

string convertDate(_variant_t d) {
SYSTEMTIME sysTime;
std::ostringstream strs_Date;

	if (!VariantTimeToSystemTime(d.date, &sysTime)) {
		throw "Failed to convert variant time to system time";
	}

	strs_Date << sysTime.wYear << "-";
	if (sysTime.wMonth < 10) {
		strs_Date << "0";
	}
	strs_Date << sysTime.wMonth << "-";
	if (sysTime.wDay < 10) {
		strs_Date << "0";
	}
	strs_Date << sysTime.wDay << " ";
	if (sysTime.wHour < 10) {
		strs_Date << "0";
	}
	strs_Date << sysTime.wHour << ":";
	if (sysTime.wMinute < 10) {
		strs_Date << "0";
	}
	strs_Date << sysTime.wMinute << ":";
	if (sysTime.wSecond < 10) {
		strs_Date << "0";
	}
	strs_Date << sysTime.wSecond;

	return strs_Date.str();
}

string CmdGetTrades() {
CheckTradeDeskLogin();
FXCore::ITableAutPtr pTradesTable = g_pTradeDesk->FindMainTable("trades");
string sTrades = "200 ";


		unsigned long lRows = pTradesTable->GetRowCount();
		for (unsigned long l = 1; l <= lRows; ++l)
		{
			std::ostringstream strs_Price;
			std::ostringstream strs_Lot;
			std::ostringstream strs_PL;
			_bstr_t _symbol = pTradesTable->CellValue(l, "Instrument").bstrVal;
			string symbol = (const char*) _symbol;
			symbol = convertSymbolFromFXCM(symbol);

			_bstr_t _tradeID = pTradesTable->CellValue(l, "TradeID").bstrVal;
			string tradeID = (const char*) _tradeID;

			string direction = (const char*) pTradesTable->CellValue(l, "BS").bstrVal;
			if (direction.compare("B") == 0) {
				direction = "long";
			} else if (direction.compare("S") == 0) {
				direction = "short";
			} else {
				string e = "Invalid Direction returned in TradesTable: ";
				throw e.append(direction).c_str();
			}

			double openPrice = pTradesTable->CellValue(l, "Open").dblVal;
			strs_Price << openPrice;

			int size = pTradesTable->CellValue(l, "Lot").intVal;
			strs_Lot << size;

			_variant_t _openDate = pTradesTable->CellValue(l, "Time");
			string openDate = convertDate(_openDate);

			double pl = pTradesTable->CellValue(l, "GrossPL").dblVal;
			strs_PL << pl;

			sTrades.append("- symbol: ").append(symbol).append("\n");
			sTrades.append("  id: ").append(tradeID).append("\n");
			sTrades.append("  direction: ").append(direction).append("\n");
			sTrades.append("  openPrice: ").append(strs_Price.str()).append("\n");
			sTrades.append("  size: ").append(strs_Lot.str()).append("\n");
			sTrades.append("  openDate: ").append(openDate).append("\n");
			sTrades.append("  pl: ").append(strs_PL.str()).append("\n");
		}

		return sTrades;
/*
                 "  openDate: " & Format$(trade.CellValue("Time"), "yyyy-mm-dd hh:nn:ss") & vbLf
*/
}

string CmdGetInstruments() {
CheckTradeDeskLogin();
string sInstruments = "200 ";

    FXCore::IStringEnumAutPtr instruments = g_pTradeDesk->GetInstruments();

    for (int i = 1; i <= instruments->Count; i++) {
        _bstr_t symbol = instruments->Item(i);
		sInstruments.append("- ").append(symbol).append("\n");
    }

    return sInstruments;
}

string CmdGetBaseCurrency() {
CheckTradeDeskLogin();
string sBaseCurrency = "200 ";

	_variant_t out = g_pTradeDesk->GetSystemProperty("BASE_CRNCY");
	_bstr_t bOut = out.bstrVal;
	sBaseCurrency.append((const char *) bOut);

    return sBaseCurrency;
}

string CmdCloseMarketOrder(string sTradeID, int amount) {
_variant_t vOrderID = "", vDealerInt = "";

	CheckTradeDeskLogin();
	g_pTradeDesk->CreateFixOrder2(g_pTradeDesk->FIX_CLOSEMARKET, sTradeID.c_str(), 0, 0, "", "", "", 0, 
				amount, "", 0, &vOrderID, &vDealerInt);

	string rv = "200 ";
	_bstr_t _vOrderID = vOrderID.bstrVal;
	rv.append((const char *) _vOrderID);
	return rv;
}

void CmdSetSymbolEnabled(string symbol) {
	g_pTradeDesk->SetOfferSubscription(symbol.c_str(), "Enabled");
}

void CmdSetSymbolDisabled(string symbol) {
	g_pTradeDesk->SetOfferSubscription(symbol.c_str(), "Disabled");
}

string convertSymbolFromFXCM(string symbol) {
unsigned int i;
string rv = symbol;
	while ( (i = rv.find("/")) != string::npos ) {
		rv.replace(i, 1, "");
	}
	return rv;
}