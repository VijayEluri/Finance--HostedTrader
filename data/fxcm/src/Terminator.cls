VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "Terminator"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
Private fso As Scripting.FileSystemObject
Private sTerminatorFile As String

Private Sub Class_Initialize()
    Set fso = New Scripting.FileSystemObject
    sTerminatorFile = "c:\RatePrinter.kill"
    If fso.FileExists(sTerminatorFile) Then _
        Call fso.DeleteFile(sTerminatorFile, True)
End Sub

Public Function isTerminate() As Boolean
    isTerminate = fso.FileExists(sTerminatorFile)
End Function

Private Sub Class_Terminate()
    Set fso = Nothing
End Sub
