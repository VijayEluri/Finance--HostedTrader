Attribute VB_Name = "modMain"
Option Explicit

Dim oCore As FXCore.CoreAut
Dim oTradeDesk As FXCore.TradeDeskAut


Public Sub Main()
    Dim username As String
    Dim password As String
    Dim Symbols As Variant
    Dim symbol As Variant
    
    Symbols = Array("EUR/USD", "USD/JPY", "GBP/USD", "USD/CHF", "EUR/CHF", "AUD/USD", "USD/CAD", "NZD/USD", "EUR/GBP", "EUR/JPY", "GBP/JPY", "GBP/CHF")

    username = "FX1125841001"
    password = "3151"

    Set oCore = New FXCore.CoreAut
    Set oTradeDesk = oCore.CreateTradeDesk("trader")
    
    Call oTradeDesk.Login(username, password, "http://www.fxcorporate.com/", "Demo")
    
    For Each symbol In Symbols
    Call PrintRateHistory(CStr(symbol), "m5")
    Next
    Call oTradeDesk.Logout
    
    Set oTradeDesk = Nothing
    Set oCore = Nothing
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
    Set file = fso.CreateTextFile(symbol, True, False)
    For Each rate In rates
        file.Write Format(rate.StartDate, "YYYY-MM-DD hh:mm:ss") & vbTab & _
                    CStr(rate.AskOpen) & vbTab & _
                    CStr(rate.AskHigh) & vbTab & _
                    CStr(rate.AskLow) & vbTab & _
                    CStr(rate.AskClose)
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
