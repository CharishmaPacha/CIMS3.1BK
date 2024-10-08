'------------------------------------------------------------------------------------
' Description:  This script is used to set an image into a given image field
'               for multiple records on a given table in a given database on
'               a given server.
'
' Author:       Tony Roper
' Date:         2005/07/25
' Revised:      2006/09/04 - fix: update multiple records that match the where clause.
'               2007/11/25 - enhanced to use a FileDialog to prompt for image file.
'------------------------------------------------------------------------------------

' Require explicit variable declarations
Option Explicit

' ADO settings
Const adOpenKeyset               = 1          ' From adovbs.inc
Const adLockOptimistic           = 3          ' From adovbs.inc
Const adTypeBinary               = 1          ' From adovbs.inc
Const ADO_PROVIDER               = "SQLOLEDB" ' Use OLE DB (not ODBC) driver
Const ADO_CONNECTION_TIMEOUT     = 5          ' 5 seconds should be enough
Const ADO_DEFAULT_QUERY_TIMEOUT  = 30         ' 30 seconds should be enough
Const ADO_DEFAULT_AUTHENTICATION = "SSPI"     ' Windows Authentication

' ADO global objects
Dim rs     ' As New ADODB.Recordset
Dim conn   ' As New ADODB.Connection

' Create ADO-specific objects.
Set conn = CreateObject("ADODB.Connection")
Set rs   = CreateObject("ADODB.Recordset")

' Set ADO to use OLE DB provider and define connection properties.
conn.Provider                                = ADO_PROVIDER
conn.ConnectionTimeout                       = ADO_CONNECTION_TIMEOUT
conn.CommandTimeout                          = ADO_DEFAULT_QUERY_TIMEOUT
conn.Properties("Integrated Security").Value = ADO_DEFAULT_AUTHENTICATION

' Get server name from the user
Dim sServerName
sServerName = InputBox("Enter server name:")
if sServerName = "" then
  conn.Properties("Data Source").Value = "(local)"
else
  conn.Properties("Data Source").Value = sServerName
end if

' Get database name from the user
Dim sDatabaseName
sDatabaseName = InputBox("Enter database name:")
if sDatabaseName = "" then
  conn.Properties("Initial Catalog").Value = "master"
else
  conn.Properties("Initial Catalog").Value = sDatabaseName
end if

' Get the table name from the user
Dim sTableName
sTableName = InputBox("Enter table name:")
if sTableName = "" then
  MsgBox "Table name is a required parameter"
  WScript.Quit(-1)
end if

' Get the image field name from the user
Dim sImageField
sImageField = InputBox("Enter image field name:")
if sImageField = "" then
  MsgBox "Image field name is a required parameter"
  WScript.Quit(-1)
end if

' Get the where clause from the user
Dim sWhereClause
sWhereClause = InputBox("Enter where clause:")
if sWhereClause = "" then
  MsgBox "Where clause is a required parameter"
  WScript.Quit(-1)
end if

' Get the image file name from the user
Dim objDialog, iResult
Set objDialog = CreateObject("UserAccounts.CommonDialog")
objDialog.Filter = "All Files|*.*"
objDialog.FilterIndex = 1
objDialog.InitialDir = "..\..\Images"
iResult = objDialog.ShowOpen

if iResult = 0 then
  MsgBox "Image file name is a required parameter"
  WScript.Quit(-1)
end if

' Open connection...
conn.Open

' Open recordset...
Dim sSql
sSql = "Select * from " & sTableName & " where " & sWhereClause
rs.Open sSql, conn, adOpenKeyset, adLockOptimistic

Dim stm ' As New ADODB.Stream
Set stm = CreateObject("ADODB.Stream")

' Load the image file into an ADO stream
with stm
  .Type = adTypeBinary
  .Open
  .LoadFromFile objDialog.FileName
end with

' Set the image in each image column of every record that matched the criteria
rs.MoveFirst
Do While (Not rs.EOF)
  rs(sImageField).Value = stm.Read
  stm.Position = 0 ' reset position
  rs.Update
  if Err.Number <> 0 then
    MsgBox Err.Description
  end if
  rs.MoveNext
Loop
MsgBox "Image fields successfully updated!"

' Cleanup
Set objDialog = Nothing
stm.Close
Set stm = Nothing
rs.Close
Set rs = Nothing
conn.Close
Set conn = Nothing
WScript.Quit(0)
