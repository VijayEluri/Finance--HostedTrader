VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "Logger"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Dim fso As Scripting.FileSystemObject
Dim file As Scripting.TextStream

Private Sub Class_Initialize()
    Dim logfile As String
    logfile = App.EXEName & ".log"
    Set fso = New Scripting.FileSystemObject
    Set file = fso.OpenTextFile(logfile, ForAppending, True)
End Sub

Public Sub log(ByRef s As String)
    Call file.WriteLine("[" & Format(Now(), "YYYY-MM-DD hh:mm:ss") & "] " & s)
    Debug.Print "[" & Format(Now(), "YYYY-MM-DD hh:mm:ss") & "] " & s
End Sub

Private Sub Class_Terminate()
    file.Close
    Set file = Nothing
    Set fso = Nothing
End Sub
