Attribute VB_Name = "modMain"
Option Explicit

Private Declare Function FreeConsole Lib "kernel32" () As Long
Private Declare Sub Sleep Lib "kernel32" (ByVal dwMilliseconds As Long)
Private Declare Function GetTickCount Lib "kernel32" () As Long

Dim oCore As FXCore.CoreAut
Dim oTradeDesk As FXCore.TradeDeskAut
Dim oLog As Logger


Public Sub Main()
    Dim username As String
    Dim password As String
    Dim accountType As String
    Dim Symbols As Variant
    Dim symbol As Variant
    Dim Args() As String
    
    Set oLog = New Logger
    Call oLog.log(vbCrLf)
    Call oLog.log("---------------------")
    Call oLog.log("App init")
    
    On Error GoTo ErrorHandler
    FreeConsole
    
    Args = Split(Command$, " ")
    
    If UBound(Args) < 3 Then
        Call oLog.log("Invalid arguments")
        End
    End If
    
    Symbols = Array("EUR/USD", "USD/JPY", "GBP/USD", "USD/CHF", "EUR/CHF", "AUD/USD", "USD/CAD", "NZD/USD", "EUR/GBP", "EUR/JPY", "GBP/JPY", "GBP/CHF", "XAU/USD", "XAG/USD") ', "USOil", "UKOil", "NAS100", "SPX500")

    username = Args(0)
    password = Args(1)
    accountType = Args(2)

    Set oCore = New FXCore.CoreAut
    Set oTradeDesk = oCore.CreateTradeDesk("trader")
    
    Call oTradeDesk.Login(username, password, "http://www.fxcorporate.com/Hosts.jsp", accountType)
    Call oLog.log("Login successfull")
    Call oLog.log("Account Type: " & accountType)
    
    Dim i As Long
    For i = 3 To UBound(Args)
        Dim j As Long
        Dim work As Variant
        Dim dates As Variant
        Dim timeframe As String
        work = Split(Args(i), ";", 2, vbBinaryCompare)
        timeframe = work(0)
        dates = Split(work(1), ",", -1, vbBinaryCompare)
        For j = 0 To UBound(dates)
            For Each symbol In Symbols
                Dim startFinish As Variant
                startFinish = Split(dates(j), "|", -1, vbBinaryCompare)
                oLog.log ("Fetching " & symbol & " " & timeframe & " " & startFinish(0) & " " & startFinish(1))
                Call PrintRateHistory(CStr(symbol), UnmapTimeframe(timeframe), -1, CDate(startFinish(0)), CDate(startFinish(1)))
            Next
        Next
    Next
    
    GoTo CleanUp
    
ErrorHandler:
    Call oLog.log("FATAL EXCEPTION: " & Err.Source & " - " & Err.Description)

CleanUp:
On Error Resume Next
    If oTradeDesk.IsLoggedIn() Then _
        Call oTradeDesk.Logout
On Error GoTo 0
    Set oTradeDesk = Nothing
    Set oCore = Nothing
    Call oLog.log("App End")
    Set oLog = Nothing
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
    Set file = fso.OpenTextFile(Replace(symbol, "/", "") & "_" & MapTimeframe(period), ForAppending, True)
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
