/***********************************************************************
 main.cpp - The main() routine for all the "Basic Winsock" suite of
    programs from the Winsock Programmer's FAQ.  This function parses
    the command line, starts up Winsock, and calls an external function
    called DoWinsock to do the actual work.

 This program is hereby released into the public domain.  There is
 ABSOLUTELY NO WARRANTY WHATSOEVER for this product.  Caveat hacker.
***********************************************************************/

#include <winsock.h>

#include <stdlib.h>
#include <iostream>

using namespace std;


//// Prototypes ////////////////////////////////////////////////////////

extern int DoWinsock(const char*, int, const char*, const char*, const char*);


//// main //////////////////////////////////////////////////////////////

int main(int argc, char* argv[])
{
    // Do we have enough command line arguments?
    if (argc < 5) {
        cerr << "usage: " << argv[0] << " <server-address> " <<
                "server-port username password (Demo|Real)" << endl << endl;
        return 1;
    }

    // Get host and (optionally) port from the command line
    const char* pcHost = argv[1];
    int nPort = atoi(argv[2]);
	const char* pcUser = argv[3];
	const char* pcPassw = argv[4];
	const char* pcAcType = argv[5];

    // Start Winsock up
    WSAData wsaData;
	int nCode;
    if ((nCode = WSAStartup(MAKEWORD(1, 1), &wsaData)) != 0) {
		cerr << "WSAStartup() returned error code " << nCode << "." <<
				endl;
        return 255;
    }

    // Call the main example routine.
    int retval = DoWinsock(pcHost, nPort, pcUser, pcPassw, pcAcType);

    // Shut Winsock back down and take off.
    WSACleanup();
    return retval;
}