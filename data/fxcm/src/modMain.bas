Attribute VB_Name = "modMain"
Option Explicit

Private Declare Function FreeConsole Lib "kernel32" () As Long
Private Declare Sub Sleep Lib "kernel32" (ByVal dwMilliseconds As Long)
Private Declare Function GetTickCount Lib "kernel32" () As Long

Dim oCore As FXCore.CoreAut
Dim oTradeDesk As FXCore.TradeDeskAut
Dim oLog As Logger
Dim lastTimePositionsUpdated As Long

Type TimeframeInfoType
    SleepInterval As Long
    LastTimeDownloaded As Long
    FXCore2GO_Code As String
End Type

Sub ProcessOrders()
Dim fso As Scripting.FileSystemObject
Dim fld As Scripting.Folder
Dim file As Scripting.file
Dim stream As Scripting.TextStream
Dim Order() As String
Dim rv As Long
Dim fileCount As Long
Dim symbol As String

Set fso = New Scripting.FileSystemObject

If Not fso.FolderExists("c:/orders") Then Exit Sub
Set fld = fso.GetFolder("c:/orders")
fileCount = fld.Files.Count
If fileCount > 0 Then
    oLog.log "Processing " & fileCount & " order(s)"
    For Each file In fld.Files
        Set stream = file.OpenAsTextStream(ForReading)
        Order = Split(stream.ReadAll, " ")
        stream.Close
        Set stream = Nothing
        symbol = Left$(Order(0), 3) & "/" & Right$(Order(0), 3)
        If marketOrder(symbol, Order(1), Order(2), Order(3)) = 0 Then
            file.Delete True
        End If
    Next
End If
Set fld = Nothing
Set fso = Nothing

End Sub

Private Function marketOrder(ByVal symbol As String, ByVal direction As String, ByVal maxLoss As Long, ByVal maxLossPrice As Double) As Long
    Dim orderId, dealer
    Dim offer As Object
    Dim acct  As Object
    Dim value As Double
    Dim accountId As String
    Dim base As String
    Dim amount As Long
    Dim maxLossPts As Double

On Error GoTo EH:
    Set acct = oTradeDesk.FindMainTable("accounts")
    accountId = acct.CellValue(1, "AccountID")
    Set acct = Nothing
    
    base = UCase$(Right$(symbol, 3))
    If base <> "GBP" Then
        Set offer = oTradeDesk.FindRowInTable("offers", "Instrument", "GBP/" & base)
        maxLoss = maxLoss * offer.CellValue("Ask")
    End If
    
    Set offer = oTradeDesk.FindRowInTable("offers", "Instrument", symbol)
    If direction = "long" Then
        value = offer.CellValue("Ask")
        maxLossPts = value - maxLossPrice
    Else
        value = offer.CellValue("Bid")
        maxLossPts = maxLossPrice - value
    End If
    If maxLossPts <= 0 Then
        Err.Raise -1, "marketOrder", "Tried to set stop to " & CStr(maxLossPrice) & " but current price is " & value
    End If
    amount = (maxLoss / maxLossPts) / 10000
    amount = amount * 10000
    
    oTradeDesk.CreateFixOrder3 oTradeDesk.FIX_OPEN, "", value, 0, "", accountId, symbol, LCase$(direction) = "long", amount, "", 0, 0, oTradeDesk.TIF_IOC, orderId, dealer
    Set offer = Nothing
    marketOrder = 0
    Exit Function

EH:
   marketOrder = 1
   oLog.log symbol & " : " & direction & " : " & Err.Source & " : " & Err.Description
End Function


Public Sub Main()
    Dim username As String
    Dim password As String
    Dim Symbols As Variant
    Dim symbol As Variant
    Dim Args() As String
    Dim TfInfo() As TimeframeInfoType
    Dim numTimeframes As Long
    Dim i As Long, numTicks As Long
    Dim oTerminator As Terminator
    Dim dateFrom As Date, dateTo As Date
    Dim accountType As String
    
    Set oLog = New Logger
    Call oLog.log(vbCrLf)
    Call oLog.log("---------------------")
    Call oLog.log("App init")
    
    On Error GoTo ErrorHandler
    FreeConsole
    
    Args = Split(Command$, " ")
    
    If UBound(Args) < 5 Then
        Call oLog.log("Invalid arguments")
        End
    End If
    numTimeframes = UBound(Args) - 4
    ReDim TfInfo(numTimeframes - 1)
    For i = 0 To numTimeframes - 1
        TfInfo(i).SleepInterval = CLng(Args(5 + i)) * 250
        TfInfo(i).LastTimeDownloaded = TfInfo(i).SleepInterval * (-2) ' This is necessary because in Wine, GetTickCount starts at 0 when the application starts
        TfInfo(i).FXCore2GO_Code = UnmapTimeframe(Args(5 + i))
    Next
    
    Symbols = Array("EUR/USD", "USD/JPY", "GBP/USD", "USD/CHF", "EUR/CHF", "AUD/USD", "USD/CAD", "NZD/USD", "EUR/GBP", "EUR/JPY", "GBP/JPY", "GBP/CHF", "XAU/USD", "XAG/USD") ', "USOil", "UKOil", "NAS100", "SPX500")

    username = Args(0)
    password = Args(1)
    accountType = Args(2)
    dateFrom = CDate(Replace(Args(3), "_", " "))
    dateTo = CDate(Replace(Args(4), "_", " "))

    Set oCore = New FXCore.CoreAut
    Set oTradeDesk = oCore.CreateTradeDesk("trader")
    
    Call oTradeDesk.Login(username, password, "http://www.fxcorporate.com/Hosts.jsp", accountType)
    Call oLog.log("Login successfull")
    Call oLog.log("Account Type: " & accountType)
    Call oLog.log("Start date: " & dateFrom)
    Call oLog.log("Final date: " & dateTo)
    
    If dateTo = "0" Then
        getPositions
    End If
    Call oTradeDesk.EnablePendingEvents(oTradeDesk.EventAdd + oTradeDesk.EventRemove + oTradeDesk.EventSessionStatusChange)
    numTicks = 300
    
'    Dim Instruments As Object
'    Dim Instrument As Variant
'    Set Instruments = oTradeDesk.GetInstruments()
'    For Each Instrument In Instruments
'        oLog.log CStr(Instrument)
'    Next
    
    Set oTerminator = New Terminator
    Do

    For i = 0 To numTimeframes - 1
        If TfInfo(i).SleepInterval + TfInfo(i).LastTimeDownloaded <= GetTickCount() Then
            oLog.log ("Fetching " & numTicks & " data items in timeframe " & TfInfo(i).FXCore2GO_Code)
            TfInfo(i).LastTimeDownloaded = GetTickCount()
            For Each symbol In Symbols
                Call PrintRateHistory(CStr(symbol), TfInfo(i).FXCore2GO_Code, numTicks, CDate(dateFrom), CDate(dateTo))
                If dateTo = "0" Then
                    ProcessEvents
                    ProcessOrders
                End If
            Next
            oLog.log ("Fetching done")
        End If
        If dateTo = "0" Then
            ProcessEvents
            ProcessOrders
        End If
    Next
    If oTerminator.isTerminate() Then
        Call oLog.log("Terminator signal invoked, exiting")
        Exit Do
    End If
    Sleep 2000
    numTicks = 10
    If GetTickCount() - lastTimePositionsUpdated > 180000 Then
        oLog.log "Refreshing positions due to timeout"
        getPositions
    End If
    Loop While (dateTo = 0)
    
    GoTo CleanUp
    
ErrorHandler:
    Call oLog.log("FATAL EXCEPTION: " & Err.Source & " - " & Err.Description)

CleanUp:
On Error Resume Next
    Call oTradeDesk.Logout
    On Error GoTo 0
    Set oTradeDesk = Nothing
    Set oCore = Nothing
    Set oTerminator = Nothing
    Call oLog.log("App End")
    End
End Sub

Function PrintRateHistory(ByVal symbol As String, ByVal period As String, ByVal ItemCount As Integer, dateFrom As Date, dateTo As Date)
    Dim rates As FXCore.MarketRateEnumAut
    Dim rate As FXCore.MarketRateAut
    Dim sql As String
    
    Dim fso As Scripting.FileSystemObject
    Dim file As Scripting.TextStream

    Set fso = New Scripting.FileSystemObject
    Set rates = oTradeDesk.GetPriceHistoryUTC(symbol, period, dateFrom, dateTo, ItemCount, False, True)
    Set file = fso.CreateTextFile(Replace(symbol, "/", "") & "_" & MapTimeframe(period), True, False)
    For Each rate In rates
        file.Write Format(rate.StartDate, "YYYY-MM-DD hh:mm:ss") & vbTab & _
                    CStr(rate.AskOpen) & vbTab & _
                    CStr(rate.AskLow) & vbTab & _
                    CStr(rate.AskHigh) & vbTab & _
                    CStr(rate.AskClose) & Chr$(10)
    Next
    file.Close
    Set file = Nothing
    Set fso = Nothing
End Function

Private Function MapTimeframe(ByVal tf As String) As String
    If tf = "t" Then
        MapTimeframe = "0"
    ElseIf tf = "m1" Then
        MapTimeframe = "60"
    ElseIf tf = "m5" Then
        MapTimeframe = "300"
    ElseIf tf = "m15" Then
        MapTimeframe = "900"
    ElseIf tf = "m30" Then
        MapTimeframe = "1800"
    ElseIf tf = "H1" Then
        MapTimeframe = "3600"
    ElseIf tf = "D1" Then
        MapTimeframe = "86400"
    ElseIf tf = "W1" Then
        MapTimeframe = "604800"
    ElseIf tf = "M1" Then
        MapTimeframe = "2592000"
    Else
        End
    End If
End Function

Private Function UnmapTimeframe(ByVal tf As String) As String
    If tf = "0" Then
        UnmapTimeframe = "t"
    ElseIf tf = "60" Then
        UnmapTimeframe = "m1"
    ElseIf tf = "300" Then
        UnmapTimeframe = "m5"
    ElseIf tf = "90" Then
        UnmapTimeframe = "m15"
    ElseIf tf = "1800" Then
        UnmapTimeframe = "m30"
    ElseIf tf = "3600" Then
        UnmapTimeframe = "H1"
    ElseIf tf = "86400" Then
        UnmapTimeframe = "D1"
    ElseIf tf = "604800" Then
        UnmapTimeframe = "W1"
    ElseIf tf = "2592000" Then
        UnmapTimeframe = "M1"
    Else
        End
    End If
End Function


'Writes current open positions to a yaml file
Private Sub getPositions()
Dim trades As Object
Dim trade As Object

Set trades = oTradeDesk.FindMainTable("trades")

Dim fso As Scripting.FileSystemObject
Dim stream As Scripting.TextStream
Set fso = New Scripting.FileSystemObject

Set stream = fso.OpenTextFile("C:/trades.yml", ForWriting, True)

Dim sTrade As String
For Each trade In trades.Rows
        sTrade = "- symbol: " & Replace(trade.CellValue("Instrument"), "/", vbNullString) & vbLf & _
                 "  direction: " & IIf(trade.CellValue("BS") = "B", "long", "short") & vbLf & _
                 "  openPrice: " & trade.CellValue("Open") & vbLf & _
                 "  size: " & trade.CellValue("Lot") & vbLf & _
                 "  openDate: " & Format$(trade.CellValue("Time"), "yyyy-mm-dd hh:nn:ss") & vbLf
        stream.Write sTrade
Next

stream.Close
Set stream = Nothing
Set fso = Nothing
Set trades = Nothing

lastTimePositionsUpdated = GetTickCount()

End Sub

Private Sub ProcessEvents()
Dim Events As Object
Dim Ev As Object
Dim refresh As Boolean

    refresh = False
    Set Events = oTradeDesk.GetPendingEvents()
    For Each Ev In Events
        If Ev.TableType = "summary" Then
            Debug.Print Ev.ExtInfo
            refresh = True
        End If
    Next
    Set Events = Nothing
    
    If refresh Then
        oLog.log "Refreshing positions due to event received"
        getPositions
    End If
End Sub
