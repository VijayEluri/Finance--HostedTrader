Attribute VB_Name = "modMain"
Option Explicit

Private Declare Function FreeConsole Lib "kernel32" () As Long
Private Declare Sub Sleep Lib "kernel32" (ByVal dwMilliseconds As Long)
Private Declare Function GetTickCount Lib "kernel32" () As Long

Dim oCore As FXCore.CoreAut
Dim oTradeDesk As FXCore.TradeDeskAut
Dim oLog As Logger

Type TimeframeInfoType
    SleepInterval As Long
    LastTimeDownloaded As Long
    FXCore2GO_Code As String
End Type

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
    
    If dateTo = "0" Then getPositions
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
            Sleep 250
            oLog.log ("Fetching " & numTicks & " data items in timeframe " & TfInfo(i).FXCore2GO_Code)
            TfInfo(i).LastTimeDownloaded = GetTickCount()
            For Each symbol In Symbols
                Call PrintRateHistory(CStr(symbol), TfInfo(i).FXCore2GO_Code, numTicks, CDate(dateFrom), CDate(dateTo))
                If dateTo = "0" Then ProcessEvents
            Next
            oLog.log ("Fetching done")
        End If
        If dateTo = "0" Then ProcessEvents
    Next
    If oTerminator.isTerminate() Then
        Call oLog.log("Terminator signal invoked, exiting")
        Exit Do
    End If
    Sleep 2000
    numTicks = 10
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
Dim i As Long
Dim Direction As String
Dim openPrice As Double
Dim Size As Long
Dim when As String

Set trades = oTradeDesk.FindMainTable("trades")

Dim fso As Scripting.FileSystemObject
Dim stream As Scripting.TextStream
Set fso = New Scripting.FileSystemObject

Set stream = fso.OpenTextFile("C:/trades.yml", ForWriting, True)

Dim sTrade As String
For Each trade In trades.Rows
        sTrade = "- symbol: " & trade.CellValue("Instrument") & vbLf & _
                 "  direction: " & IIf(trade.CellValue("BS") = "B", "long", "short") & vbLf & _
                 "  openPrice: " & trade.CellValue("Open") & vbLf & _
                 "  size: " & trade.CellValue("Lot") & vbLf & _
                 "  when: " & Format$(trade.CellValue("Time"), "yyyy-mm-dd hh:nn:ss") & vbLf
        stream.Write sTrade
Next

stream.Close
Set stream = Nothing
Set fso = Nothing

Set trades = Nothing
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
    
    
    
    If refresh Then getPositions
End Sub
