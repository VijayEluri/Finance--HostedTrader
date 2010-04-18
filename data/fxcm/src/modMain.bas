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
    
    Set oLog = New Logger
    Call oLog.log(vbCrLf)
    Call oLog.log("---------------------")
    Call oLog.log("App init")
    
    On Error GoTo ErrorHandler
    FreeConsole
    
    Args = Split(Command$, " ")
    
    If UBound(Args) < 2 Then
        Call oLog.log("Invalid arguments")
        End
    End If
    numTimeframes = UBound(Args) - 1
    ReDim TfInfo(numTimeframes - 1)
    For i = 0 To numTimeframes - 1
        TfInfo(i).SleepInterval = CLng(Args(2 + i)) * 250
        TfInfo(i).LastTimeDownloaded = TfInfo(i).SleepInterval * (-2) ' This is necessary because in Wine, GetTickCount starts at 0 when the application starts
        TfInfo(i).FXCore2GO_Code = UnmapTimeframe(Args(2 + i))
    Next
    
    
    Symbols = Array("EUR/USD", "USD/JPY", "GBP/USD", "USD/CHF", "EUR/CHF", "AUD/USD", "USD/CAD", "NZD/USD", "EUR/GBP", "EUR/JPY", "GBP/JPY", "GBP/CHF")

    username = Args(0)
    password = Args(1)

    Set oCore = New FXCore.CoreAut
    Set oTradeDesk = oCore.CreateTradeDesk("trader")
    
    Call oTradeDesk.Login(username, password, "http://www.fxcorporate.com/", "Demo")
    Call oLog.log("Login successfull")
    numTicks = 300
    
    Set oTerminator = New Terminator
    Do While (1)

    For i = 0 To numTimeframes - 1
        If TfInfo(i).SleepInterval + TfInfo(i).LastTimeDownloaded <= GetTickCount() Then
            oLog.log ("Fetching " & numTicks & " data items in timeframe " & TfInfo(i).FXCore2GO_Code)
            TfInfo(i).LastTimeDownloaded = GetTickCount()
            For Each symbol In Symbols
                Call PrintRateHistory(CStr(symbol), TfInfo(i).FXCore2GO_Code, numTicks)
            
            Next
            oLog.log ("Fetching done")
        End If
    Next
    If oTerminator.isTerminate() Then
        Call oLog.log("Terminator signal invoked, exiting")
        Exit Do
    End If
    Sleep 5000
    numTicks = 10
    Loop
    
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


Function PrintRateHistory(ByVal symbol As String, ByVal period As String, Optional ByVal ItemCount As Integer = 300)
    Dim rates As FXCore.MarketRateEnumAut
    Dim rate As FXCore.MarketRateAut
    Dim dateFrom As Date, dateTo As Date
    Dim sql As String
    
    Dim fso As Scripting.FileSystemObject
    Dim file As Scripting.TextStream

    Set fso = New Scripting.FileSystemObject
    dateFrom = "2004-01-01"
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

