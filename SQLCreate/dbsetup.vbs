'------------------------------------------------------------------------------------
'  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

'  Revision History:

'  Date        Person  Comments

'  2024/10/23  VM      ProcessSqlFolders: Bug-fix to consider finding start of the folder string filter properly (CIMSV3-3962)
'  2024/05/15  VM      ProcessSqlFile: Enhanced to process files by filefilter/folder/subfolder/subfolderfilter reading from the SQL script file
'                      ProcessSqlFolder, ProcessSqlFolders: Made changes to show message by context
'                      GetInputFoldersInfo, ProcessSqlFiles: Inroduced new functions (CIMSV3-3601)
'  2023/11/02  VM      Script enhanced to accept folder and folder filter to get the sub folders of the given folder based upon the folder filter given
'                      SetScriptExecutionOptions: GetParam => GetParams to get both folder and folder filter also, if given
'                      UpdateDatabase: Made changes to process files from the sub folder if the folder filter is given otherwise, process as earlier
'                      ProcessSqlFolders: Introduced to get sub folders of the given folder based upon the folder filter and process files under them (CIMSV3-3146)
'  2020/08/12  VM      Script enhanced to support to accept folder to process files within it.
'                      UpdateDatabase: Made changes to process from folder if given otherwise, process top level script file normally
'                      ProcessSqlFolder: Introduced a new function (CIMS-3134)
'------------------------------------------------------------------------------------
' Description:  This script is used to create a DCCS database on a local
'               or remote instance of SQL  Server 2000 or greater.
'
'               On exit, the script will return one of the following codes (the
'               return code can be accessed via the %ERRORLEVEL% environment
'               variable):
'
'               1:  database exists (when checking for database existence)
'               0:  success, or
'                   database does not exist (when checking for database existence)
'               -1: setup error
'               -2: SQL Server connectivity or login error
'
'               To see usage information, execute the script with /? switch. To
'               understand the script logic, read the inline comments and method
'               descriptions (the Main function may be a good place to start).
'
'               To debug this script, execute it with the //D and //X command-line
'               parameters, e.g.:
'
'               cscript //nologo //D //X <Path to This Script> <Parameters...>
'
' Author:       adapted by Tony Roper from an original script by Alek Davis
'------------------------------------------------------------------------------------

' Require explicit variable declarations
Option Explicit

'------------------------------------------------------------------------------------
' Default settings


' Command-line parameter indicators and separators
Const SWITCH_INDICATOR1         = "/"       ' As in /switch
Const SWITCH_INDICATOR2         = "-"       ' As in -switch (same as above)
Const SWITCH_PARAM_DELIMITER    = ":"       ' As in /switch:param
Const SWITCH_PARAMS_DELIMITER   = ";"       ' As in /switch:param1;param2

' Setup file info
Const SETUP_LOG_FILE_EXT        = ".log"    ' Self-explanatory

' Command-line switches (to see descriptions, run this script with /? switch)
Const SWITCH_DB_NAME            = "d"       ' /d:MyDB
Const SWITCH_DB_SERVER          = "s"       ' /s:MYSERVER,1433
Const SWITCH_DB_USER            = "u"       ' /u:sqluser
Const SWITCH_DB_PASSWORD        = "p"       ' /p:sqlpassword
Const SWITCH_SCRIPT_FOLDER      = "o"       ' /o:program,proc_*
Const SWITCH_SCRIPT_FILE        = "f"       ' /f:_Init_All.sql
Const SWITCH_LOG_LEVEL          = "log"     ' /log:all
Const SWITCH_LOG_FILE           = "out"     ' /out:"c:\My Setup\MyDB\Logs"
Const SWITCH_NO_TIME            = "notime"  ' /notime
Const SWITCH_KEEP_LOG           = "keeplog" ' /keeplog
Const SWITCH_SETUP_MODE         = "mode"    ' /mode:default
Const SWITCH_DB_FILE            = "data"    ' /data:"C:\MyDB.mdf;E:\MyDB.ldf"
Const SWITCH_TIMEOUT            = "timeout" ' /timeout:60
Const SWITCH_VERBOSE            = "verbose" ' /verbose
Const SWITCH_SILENT             = "silent"  ' /silent
Const SWITCH_HELP1              = "?"       ' /?
Const SWITCH_HELP2              = "h"       ' /h
Const SWITCH_HELP3              = "help"    ' /help
Const SWITCH_DB_SIZE            = "dsize"   ' /dsize:"100MB;500MB;50MB" Init,Max,Growth
Const SWITCH_LOG_SIZE           = "lsize"   ' /lsize:"100MB;500MB;50MB" Init,Max,Growth

' ADO settings
Const ADO_PROVIDER              = "SQLOLEDB"' Use OLE DB (not ODBC) driver
Const ADO_DEFAULT_SQL_USER      = "sa"      ' Use default dba account
Const ADO_CONNECTION_TIMEOUT    = 25        ' 25 seconds should be enough
Const ADO_DEFAULT_DB            = "master"  ' To set default database context
Const ADO_DEFAULT_QUERY_TIMEOUT = -1        ' Must be 30 seconds (implicit)

' SQL settings
Const SQL_DATA_FILE_GROUP       = 1         ' See master..sysaltfiles table
Const SQL_TLOG_FILE_GROUP       = 0         ' See master..sysaltfiles table
Const SQL_DATA_FILE_EXT         = ".mdf"    ' File extension (data file)
Const SQL_TLOG_FILE_EXT         = ".ldf"    ' File extension (transaction log file)
Const SQL_DATA_FILE_POSTFIX     = "_DATA"   ' Used to end logical DB file name
Const SQL_TLOG_FILE_POSTFIX     = "_TLOG"   ' Used to end logical DB file name

'------------------------------------------------------------------------------------
' Constants

' Setup modes
Const MODE_DEFAULT              = 0         ' Mode determined at run time
Const MODE_INSTALL              = 1         ' Installs database
Const MODE_UPDATE               = 2         ' Updates database

' Log levels (do not change the order)
Const LOG_LEVEL_NONE            = 0         ' No logging
Const LOG_LEVEL_ERROR           = 1         ' Log errors only
Const LOG_LEVEL_ALL             = 2         ' Log status messages and errors

' Script exit codes
Const EXIT_SUCCESS              =  0        ' For any setup mode
Const EXIT_DB_EXISTS_NO         =  0        ' For the Check setup mode
Const EXIT_DB_EXISTS_YES        =  1        ' For the Check setup mode
Const EXIT_ERROR                = -1        ' For any setup mode
Const EXIT_SQL_CONNECTION_ERROR = -2        ' For any setup mode

' Formatting strings (use spaces instead of tabs)
Const TAB1                      = "  "      ' Untabified (space chars)

' Miscellaneous
Const WINDOW_STYLE_AS_CURRENT   = 10        ' DO NOT CHANGE THIS VALUE
Const WAIT                      = True      ' DO NOT CHANGE THIS VALUE
Dim   SCRIPT_ERROR                          ' Cannot assign expression to const :-(
      SCRIPT_ERROR              = vbObjectError + 1

' VB constants missing from VBScript
Const ForReading                =  1        ' When opening file
Const ForWriting                =  2        ' When opening file
Const TristateUseDefault        = -2        ' Sets default file format: ASCII/Unicode

'------------------------------------------------------------------------------------
' Global variables
Dim g_bVerbose          ' Indicates whether to display extended error info
Dim g_bSilent           ' Indicates whether to show feedback messages
Dim g_bNoTime           ' Indicates whether to include time stamps in the log file
Dim g_bKeepLog          ' Indicates whether to delete log file containing no entries
Dim g_nSetupMode        ' Defines setup mode (MODE_INSTALL, MODE_UPDATE, etc.)
Dim g_nLogLevel         ' Specifies what type of information to log
Dim g_nTimeout          ' Defines SQL query timeout
Dim g_strLogFile        ' Path to the setup log file
Dim g_strScriptFolder   ' Path to the script files folder
Dim g_strFolderFilter   ' Script folder filter
Dim g_strScriptFile     ' Path to the top-level script file
Dim g_strDBName         ' Name of the database
Dim g_strDBServer       ' Database server
Dim g_strDBUser         ' Login ID of the database admin
Dim g_strDBPassword     ' Database admin's password
Dim g_strDataFilePath   ' Path to data file
Dim g_strTLogFilePath   ' Path to transaction log file
Dim g_strDataInitSize   ' Initial data size
Dim g_strDataMaxSize    ' Max data size
Dim g_strDataFileGrowth ' Data file growth
Dim g_strlogInitSize    ' Initial log size
Dim g_strlogMaxSize     ' Max log size
Dim g_strlogFileGrowth  ' Log file growth

Dim g_oShell            ' Wscript.Shell object
Dim g_oNetwork          ' Wscript.Network object
Dim g_oFileSystem       ' Scripting.FileSystem object
Dim g_oConnection       ' ADO connection object
Dim g_oRecordset        ' ADO record set object
Dim g_oLogFile          ' Setup log file

'------------------------------------------------------------------------------------
' PSEUDO-MAIN FUNCTION (SCRIPT ENTRY POINT)
Wscript.Quit(Main())

'------------------------------------------------------------------------------------
' Method:       Main
'
' Description:  The main function, which defines the script logic. At first, it sets
'               the default options and checks if the script is executed via the
'               CSCRIPT.EXE (as opposed to WSCRIPT.EXE). It then checks if the script
'               was launched with the /help (or equivalent) switch and if so,
'               displays the usage information; otherwise, it continues by setting
'               global variables according to command-line options and ensures that
'               all required options were specified. If all required options are
'               provided, the script tries to connect to the database server. If the
'               connection to the database server is successful, then the top-level
'               script file is executed. This file can (and most likely will) contain
'               other script files to be executed by specifying the 'INPUT' statement.
'
' Returns:      Script exit code.
'------------------------------------------------------------------------------------
Function Main()
  Dim nExitCode, nConfirmYes, strMsg, strTitle

  ' 1. Initialize settings (error in any of these functions will abort setup).

  ' Define global settings, which may be needed before we get a chance to process
  ' command-line options.
  SetDefaultOptions

  ' Check if the script needs to display help info and do so (if needed).
  ShowHelp

  ' Make sure that this script is executed by CSRIPT.EXE, not WSCRIPT.EXE.
  RevertToCScript

  ' Initialize global variables.
  InitializeGlobals

    ' Make sure we got valid database connection info.
  VerifySqlConnectionInfo

  ' Determine setup mode, e.g. install, update, etc.
  VerifySetupMode

  ' 2. Perform setup operation.

  ' Execute setup actions based on the setup mode.
  nExitCode = EXIT_SUCCESS
  Select Case g_nSetupMode
    ' Create database (from scratch).
    Case MODE_INSTALL
      If InstallDatabase() Then
        nExitCode = EXIT_SUCCESS
        ShowFeedback "DATABASE HAS BEEN INSTALLED"
      Else
        nExitCode = EXIT_ERROR
        ShowFeedback "DATABASE INSTALLATION FAILED"
      End If

    ' Update database to the current version.
    Case MODE_UPDATE
      If (UpdateDatabase()) Then
        ShowFeedback "DATABASE HAS BEEN UPDATED"
      Else
        nExitCode = EXIT_ERROR
        ShowFeedback "DATABASE UPDATE FAILED"
      End If

    ' Wrong mode (normally, this should not happen).
    Case Else
      nExitCode    = EXIT_ERROR
      ShowError    "Invalid setup mode: " & CStr(g_nSetupMode) & "."
      ShowFeedback "SETUP FAILED"
  End Select

  ' Clean up the log file (if needed).
  CleanUpLogFile

  ' Done.
  Wscript.Quit(nExitCode)
End Function

'------------------------------------------------------------------------------------
' Method:       SetDefaultOptions
'
' Description:  Sets default values for some global variables.
'------------------------------------------------------------------------------------
Sub SetDefaultOptions
  g_nLogLevel       = LOG_LEVEL_NONE    ' Do not log messages
  g_bKeepLog        = False             ' Do not keep empty log file
  g_bVerbose        = False             ' Display only error descriptions
  g_bSilent         = False             ' Display messages
  g_bNoTime         = False             ' Include time stamp in the log file
  g_strLogFile      = ""                ' No log file
  g_strDBServer     = ""                ' Local system
  g_strDataFilePath = ""                ' Use default .MDF file
  g_strTLogFilePath = ""                ' Use default .LDF file
  g_strDataInitSize   = "500MB"           ' 500MB
  g_strDataMaxSize    = "UNLIMITED"             ' 2GB
  g_strDataFileGrowth = "100MB"           ' 100MB
  g_strlogInitSize    = "100MB"
  g_strlogMaxSize     = "UNLIMITED"
  g_strlogFileGrowth  = "10%"
  g_nTimeout        = 0                 ' Infinite
  g_nSetupMode      = MODE_DEFAULT
End Sub

'------------------------------------------------------------------------------------
' Method:       ShowHelp
'
' Description:  Check if we need to and, if so, display help and usage information.
'------------------------------------------------------------------------------------
Sub ShowHelp()

On Error Resume Next
  ' Create the file system object.
  Set g_oFileSystem = CreateObject("Scripting.FileSystemObject")
  AbortOnError "Scripting.FileSystemObject failure", EXIT_ERROR
On Error GoTo 0

  ' Check for help, h, ?, or missing command-line parameters.
  If ((Wscript.Arguments.Count = 0) Or HasParam(SWITCH_HELP1) Or _
    HasParam(SWITCH_HELP2) Or HasParam(SWITCH_HELP3)) Then

        ' Check script host.
        If (LCase(g_oFileSystem.GetBaseName(Wscript.FullName)) = "wscript") Then
          WScript.Echo "To view help and usage information, please execute " &_
                       "this script from command prompt via cscript.exe " &_
                       "(instead of wscript.exe). You can use the following " &_
                       "command:" &_
                       vbCrLf & vbCrLF &_
                       "cscript.exe //nologo """ & Wscript.ScriptFullName & """" &_
                       vbCrLf & vbCrLF &_
                       "Note: When invoking the script from its directory, " &_
                       "you do not have to include the full path."
            Wscript.Quit(EXIT_SUCCESS)
        End If

    ' Show usage info.
    ShowUsage

    ' Exit with success.
    Wscript.Quit(EXIT_SUCCESS)
  End If
End Sub

'------------------------------------------------------------------------------------
' Method:       RevertToCScript
'
' Description:  Verifies that this script is launched via CSCRIPT.EXE; if not,
'               re-launches the script in CSCRIPT.EXE passing all specified
'               command-line parameters to it. This step is needed, because if the
'               script gets executed via the WSCRIPT.EXE, the user will have a hard
'               time dealing with the pop-up message boxes.
'------------------------------------------------------------------------------------
Sub RevertToCScript()
  Dim strCommandLine, nExitCode, i

On Error Resume Next
  ' Check script host.
  If (LCase(g_oFileSystem.GetBaseName(Wscript.FullName)) = "cscript") Then
    ' Script is already being executed via CSCRIPT.EXE, so we're OK.
    Exit Sub
  End If

  ' Build command line (//nologo suppresses WSH logo).
  strCommandLine = "cscript.exe //nologo "

  ' Set batch mode if needed (//B sets batch mode).
  If (Not Wscript.Interactive) Then
    strCommandLine = strCommandLine & "//B "
  End If

  ' Append script's path (in double quotes in case there are blanks).
  strCommandLine = strCommandLine & """" & Wscript.ScriptFullName & """"

  ' Append all command-line parameters.
  For i = 0 To Wscript.Arguments.Count - 1
      strCommandLine = strCommandLine & " " & Wscript.Arguments(i)
  Next

  ' Create the Windows shell object.
  Set g_oShell = CreateObject("Wscript.Shell")
  AbortOnError "Wscript.Shell failure", EXIT_ERROR

  ' Execute command; wait for the launched process to complete and get return code.
  nExitCode = g_oShell.Run(strCommandLine, WINDOW_STYLE_AS_CURRENT, WAIT)
  AbortOnError "Wscript.Shell.Run failure", EXIT_ERROR

  ' Abort script execution and return exit code of the invoked script.
  Wscript.Quit(nExitCode)
End Sub

'------------------------------------------------------------------------------------
' Method:       InitializeGlobals
'
' Description:  Initializes global variables.
'------------------------------------------------------------------------------------
Sub InitializeGlobals()
  CreateGlobalObjects
  SetScriptExecutionOptions
End Sub

'------------------------------------------------------------------------------------
' Method:       DatabaseExists
'
' Description:  Checks if database exists.
'
' Returns:      True if database exists; false otherwise.
'------------------------------------------------------------------------------------
Function DatabaseExists()
  Dim strSql

  ShowFeedback "Checking if database exists..."
  strSql = "SELECT    1 " &_
           "FROM      master..sysdatabases " &_
           "WHERE     name = '" & g_strDBName & "'"

On Error Resume Next
  Set g_oRecordset = g_oConnection.Execute(strSql)
  AbortOnError "SQL query checking database existence failed", EXIT_ERROR

  If (Not g_oRecordset.EOF) Then
    DatabaseExists = True
  Else
    DatabaseExists = False
  End If
  g_oRecordset.Close
  Err.Clear
End Function

'------------------------------------------------------------------------------------
' Method:       InstallDatabase
'
' Description:  Installs the database using the specified command-line parameters
'               and the database scripts. The database name and path to the top-level
'               script are always specified via the command line. Locations of the
'               database's data and transaction log files can also be specified via
'               the command line. To install the database, the script first creates
'               the database device (using the specified database name, and optional
'               transaction log and data file paths). It uses the defaults for other
'               database parameters, such as the initial database size and growth
'               information. After the database is created, the script executes the
'               files provided in the database script in the order specified in the
'               body of this method. If the setup encounters an error at any step
'               after creating the database, it will drop the database from the server.
'
' Returns:      True on success, false on failure.
'------------------------------------------------------------------------------------
Function InstallDatabase()
  Dim bSuccess

  bSuccess = False

  ' If database already exists, then drop it
  If (DatabaseExists()) Then
    If (Not DropDatabase()) then
      ShowError "Could not drop database '" & g_strDBName & "'."
      InstallDatabase = False
      Exit Function
    End If
  End If

  ' Set file paths for the database transaction log and data files. If it does not
  ' work, we will use the defaults.
  GetDatabaseFilePaths

  ' Add database to the SQL Server.
  ShowFeedback "Creating database..."
  If (Not CreateDatabase()) Then
    ShowError "Cannot create database '" & g_strDBName & "'."
    InstallDatabase = False
    Exit Function
  End If

  ' Change current database (do not ignore errors).
  If (UseDatabase(g_strDBName, False)) Then
    ' Process top-level script file
    ShowFeedback "Processing script file " & g_strScriptFile & "..."
    bSuccess = ProcessSqlFile(g_strScriptFile)
    if (not bSuccess) then
      ShowError "Failure processing SQL file"
    end if
  End If

  ' Since the error occurred after we created the database, we should drop it.
  If (Not bSuccess) Then
    DropDatabase
    InstallDatabase = False
    Exit Function
  End If

  InstallDatabase = True
End Function

'------------------------------------------------------------------------------------
' Method:       UpdateDatabase
'
' Description:  Updates the database from an older version to the current version.
'               To perform an update, the setup executes the scripts found in the
'               top-level script file.
'
' Returns:      True on success, false on failure.
'------------------------------------------------------------------------------------
Function UpdateDatabase()
  Dim strFromVersion, strToVersion, strFolder, aFolders, bSuccess

  ' Change current database (do not ignore errors).
  If (Not UseDatabase(g_strDBName, False)) Then
    UpgradeDatabase = False
    Exit Function
  End If

  ' Process script files from the script folder, if the folder is passed
  if (trim(g_strScriptFolder) <> "") then
    ' Process script files from all the sub folders identified by the given filter, if the folder filter is given
    if (trim(g_strFolderFilter) <> "") then
      ShowFeedback "Processing script folder(s) " & g_strScriptFolder & "/" & g_strFolderFilter & "*..."
      bSuccess = ProcessSqlFolders(g_strScriptFolder, g_strFolderFilter)
    else
      ShowFeedback "Processing script folder " & g_strScriptFolder & "..."
      bSuccess = ProcessSqlFolder(g_strScriptFolder)
    end if

    if (not bSuccess) then
      ShowError "Failure processing SQL folder"
    end if
  else
    ' Process top-level script file
    ShowFeedback "Processing script file " & g_strScriptFile & "..."

    bSuccess = ProcessSqlFile(g_strScriptFile)

    if (not bSuccess) then
      ShowError "Failure processing SQL file"
    end if
  end if

  UpdateDatabase = bSuccess
End Function

'------------------------------------------------------------------------------------
' Method:       GetDatabaseFilePaths
'
' Description:  Determines locations of the database files (data file and transaction
'               log files), if they were not specified via the command-line
'               parameters. We will try to find an existing database, which does not
'               come with SQL Server, and see where its files go to. If there are no
'               custom databases, we will use one which comes with the system. The
'               idea here is to see if there is an alternative location used by
'               non-system database files. If we are able to determine this location
'               we will use it to build the database file paths; otherwise, we will
'               just use the defaults.
'------------------------------------------------------------------------------------
Sub GetDatabaseFilePaths()
    Dim strSql, strTLogFile, strDataFile

    ' If we already got file paths, there is nothing else we need to do.
    If (g_strDataFilePath <> "" And g_strTLogFilePath <> "") Then
        Exit Sub
    End If

    ' Query to get file info for existing databases.
    strSql = "SELECT    dbid, groupid, filename " &_
             "FROM      sysaltfiles " &_
             "ORDER BY  dbid DESC, groupid"     ' system databases have smaller dbids

On Error Resume Next
    Err.Clear
    Set g_oRecordset = g_oConnection.Execute(strSql)
    If IsError() Then
        ' We don't really care about errors here, since it is not a critical step.
        Err.Clear
        g_oConnection.Errors.Clear
        Exit Sub
    End If

On Error GoTo 0
    If (g_oRecordset.BOF And g_oRecordset.EOF) Then
        ' There are no records.
        g_oRecordset.Close
        Exit Sub
    End If

    g_oRecordset.MoveFirst
    Do While (Not g_oRecordset.EOF)
        ' Check if this record is for the transaction log file.
        If (g_oRecordset("groupid") = SQL_TLOG_FILE_GROUP Or _
            InStr(LCase(g_oRecordset("filename")), LCase(SQL_TLOG_FILE_EXT))_
                > 0) Then
            If (IsEmpty(strTLogFile)) Then
                strTLogFile = g_oRecordset("filename")
            End If
        ' Check if this record is for the primary database file.
        ElseIf (g_oRecordset("groupid") = SQL_DATA_FILE_GROUP Or _
            InStr(LCase(g_oRecordset("filename")), LCase(SQL_DATA_FILE_EXT)) _
                > 0) Then
            If (IsEmpty(strDataFile)) Then
                strDataFile = g_oRecordset("filename")
            End If
        End If
        ' If we got both file paths, no need to continue.
        If (IsEmpty(strTLogFile) Or IsEmpty(strDataFile)) Then
            g_oRecordset.MoveNext
        Else
            Exit Do
        End If
    Loop
    g_oRecordset.Close
    Err.Clear

    ' Define data and transaction log files.
    If (g_strDataFilePath = "" And (Not IsEmpty(strDataFile))) Then
        g_strDataFilePath = g_oFileSystem.BuildPath( _
                                g_oFileSystem.GetParentFolderName(strDataFile), _
                                g_strDBName & SQL_DATA_FILE_EXT)
    End If
    If (g_strTLogFilePath = "" And (Not IsEmpty(strTLogFile))) Then
        g_strTLogFilePath = g_oFileSystem.BuildPath( _
                                g_oFileSystem.GetParentFolderName(strTLogFile), _
                                g_strDBName & SQL_TLOG_FILE_EXT)
    End If
End Sub

'------------------------------------------------------------------------------------
' Method:       CreateDatabase
'
' Description:  Creates the database. If the database and transaction log files
'               are provided, the script will use them in the T-SQL CREATE command;
'               otherwise, the defaults will be used. The script will use the
'               defaults for all other parameters, such as database growth.
'
' Returns:      True on success; false on failure.
'------------------------------------------------------------------------------------
Function CreateDatabase()
  Dim strSql

  strSql =    "CREATE DATABASE [" & g_strDBName & "]"

  ' Specify locations of database and transaction log files.
  If (g_strDataFilePath <> "") Then
    strSql = strSql & " ON (" &_
                 "NAME = " & Replace(g_strDBName, " ", "_") &_
                 SQL_DATA_FILE_POSTFIX _
                 & ", " &  "FILENAME = '" & g_strDataFilePath &_
                 "', SIZE = " & g_strDataInitSize &_
                 ", MAXSIZE = " & g_strDataMaxSize &_
                 ", FILEGROWTH = " & g_strDataFileGrowth & ")"
  End If
  If (g_strTLogFilePath <> "") Then
    strSql = strSql & " LOG ON (" &_
                 "NAME = " & Replace(g_strDBName, " ", "_") &_
                 SQL_TLOG_FILE_POSTFIX &_
                 ", " & "FILENAME = '" & g_strTLogFilePath &_
                 "', SIZE = " & g_strLogInitSize &_
                 ", MAXSIZE = " & g_strLogMaxSize &_
                 ", FILEGROWTH = " & g_strLogFileGrowth & ")"
  End If

  ' Specify a case-insensitive collation just in case the server instance is defined otherwise
  strSql = strSql & " COLLATE SQL_Latin1_General_CP1_CI_AS"

On Error Resume Next
  g_oConnection.Error.Clear
  Err.Clear
  g_oConnection.Execute(strSql)
  If IsError() Then
    CreateDatabase = False
  Else
    CreateDatabase = True
  End If
End Function

'------------------------------------------------------------------------------------
' Method:       UseDatabase
'
' Description:  Changes the current database context.
'
' Returns:      True on success, false on failure.
'
' Parameters:   strDBName
'                   Name of the database to use.
'               bIgnoreError
'                   Flag indicating whether to ignore (clear) or keep error info.
'------------------------------------------------------------------------------------
Function UseDatabase(ByVal strDBName, ByVal bIgnoreError)
  Dim strSql

  strSql = "USE [" & strDBName & "]"

On Error Resume Next
  g_oConnection.Errors.Clear
  Err.Clear
  g_oConnection.Execute(strSql)

  If IsError() Then
    If (bIgnoreError) Then
      Err.Clear
    End If
    ShowError "Cannot switch to database '" & strDBName & "'."
    UseDatabase = False
  Else
    g_oConnection.Errors.Clear
    UseDatabase = True
  End If
End Function

'------------------------------------------------------------------------------------
' Method:       DropDatabase
'
' Description:  Drops the database.
'
' Returns:      True on success; false on failure.
'------------------------------------------------------------------------------------
Function DropDatabase()
  Dim strSql
  Dim strSql1

  ' Since we may be using this database now, we must switch to another database,
  ' e.g. master; otherwise, we would not be able to drop it. If this operation
  ' fails, we will still try to drop the database.
  UseDatabase ADO_DEFAULT_DB, True

  ShowFeedback "Dropping database..."
  strSql  = "ALTER DATABASE [" & g_strDBName & "] SET SINGLE_USER WITH ROLLBACK IMMEDIATE"
  strSql1 = "DROP DATABASE [" & g_strDBName & "]"

On Error Resume Next
  g_oConnection.Errors.Clear
  Err.Clear
  g_oConnection.Execute(strSql)
  g_oConnection.Execute(strSql1)
  If IsError() Then
    DropDatabase = False
  Else
    DropDatabase = True
  End If
End Function

'------------------------------------------------------------------------------------
' Method:       ProcessSqlFile
'
' Description:  Processes SQL commands in a script. This function will read blocks
'               of SQL statements until it finds the GO command and execute each
'               block. The last block does not have to contain the GO command. The
'               Transact-SQL batch execution rules relevant to GO command apply.
'
'               It is now enhanced to read each line in different ways. It can be
'               in any one of the following way to process SQL files.
'               fyi, paths of files/folders below mentioned are relative to the path of SQL script file passed to this method.
'                 Input FileName.sql;                 -> Processes the given SQL file.                      ex: Input init_BusinessUnits.sql;
'                 Input .\FolderName\FileName.sql;    -> Processes the given SQL file.                      ex: Input .\Main/init_Control.sql;
'                 Input .\FolderName|FileFilter;      -> Processes all SQL files of the given folder
'                                                          which matches with the given SQL FileFilter.     ex: Input .\CycleCount|init_RF_Form_*.sql;
'                 Input .\FolderName;                 -> Processes all SQL files of the given folder.       ex: Input .\Putaway;
'                 Input .\FolderName|SubFolder;       -> Processes all SQL files of the given SubFolder     ex: Input .\Base|DataTypes;
'                 Input .\FolderName|SubFolderFilter; -> Processes all SQL files of all SubFolders 
'                                                          which matches with the SubFolderFilter.          ex: Input .\Functions|fn_*;
'
' Returns:      True on success, false on failure.
'
' Parameters:   strFile
'                   Path to the file.
'------------------------------------------------------------------------------------
Function ProcessSqlFile(ByVal strFile)
  Dim strLine, strSql, oStream
  Dim splitArray, strFolder, strFolderFilter, strFileFilter

On Error Resume Next
  Err.Clear
  Set oStream = g_oFileSystem.OpenTextFile(strFile, ForReading, False, TristateUseDefault)
  If IsError() Then
    ShowError "Cannot open file"
    ProcessSqlFile = False
    Exit Function
  End If

  ' Process all lines in the file.
  strSql = ""

  Do While (Not oStream.AtEndOfStream)
    strLine = GetNextLineOrLinesOfMultiLineComment(oStream)

    ' If we are not in the middle of the multi-line comment, look for the GO statement.
    If (IsEndOfSqlBatch(strLine)) Then
      If (Not ExecuteSqlBatch(strSql)) Then
        oStream.Close
        ProcessSqlFile = False
        Exit Function
      Else
        ' Clear SQL block.
        strSql = ""
      End If
    ElseIf (IsInputStatement(strLine)) Then
      ShowFeedback strLine
      ' Read if input line is configured with a SQL file (or) SQL file filter (or) a folder (or) a subfolder (or) subfolder filter and process the files accordingly.
      If (InStr(1, strLine, "*.sql") <> 0) Then
        ' If a SQL file filter is given - process all the files which matches with the filter
        strSql = GetInputFileName(strLine)
        ' Split the string based on the '|' delimiter
        splitArray = Split(strSql, "|")
        ' Access the parts of the split string
        strFolder = splitArray(0)
        ' Remove "*" from the given file filter
        strFileFilter = Replace(splitArray(1), "*.sql", "")
        ' strFileFilter =  Replace(strFileFilter, "*.sql", "")
        If (not ProcessSqlFiles(strFolder, strFileFilter)) Then
          oStream.Close
          ProcessSqlFile = False
          Exit Function
        Else
          ' Clear SQL block.
          strSql = ""
        End If
      ElseIf (InStr(1, strLine, ".sql") <> 0) Then
        ' If a SQL file is given - process the file
        strSql = GetInputFileName(strLine)
        'ShowFeedback strSql
        If (not ProcessSqlFile(strSql)) Then
          oStream.Close
          ProcessSqlFile = False
          Exit Function
        Else
          ' Clear SQL block.
          strSql = ""
        End If
      ElseIf (InStr(1, strLine, "|") <> 0) Then
        ' If a subfolder / subfolder filter is given - process subfolder(s) files
        strSql = GetInputFoldersInfo(strLine)
        ' ShowFeedback strSql
        ' Split the string based on the '|' delimiter
        splitArray = Split(strSql, "|")
        ' Access the parts of the split string
        strFolder = splitArray(0)
        ' Remove "*"" from the given folder filter
        strFolderFilter = Replace(splitArray(1), "*", "")
        ' ShowFeedback strFolder & " " & strFolderFilter
        If (not ProcessSqlFolders(strFolder, strFolderFilter)) Then
          oStream.Close
          ProcessSqlFile = False
          Exit Function
        Else
          ' Clear SQL block.
          strSql = ""
        End If
      Else
       ' If a folder is given - process the folder files
        strSql = GetInputFoldersInfo(strLine)
        ' ShowFeedback strSql
        If (not ProcessSqlFolder(strSql)) Then
          oStream.Close
          ProcessSqlFile = False
          Exit Function
        Else
          ' Clear SQL block.
          strSql = ""
        End If
      End If
    Else
      ' Append this line to the SQL block (since ReadLine chops it off).
      strSql = strSql & strLine & vbCrLf
    End If
  Loop

  ' If there are any pending SQL statements, execute them as well.
  If (TrimAll(strSql) <> "") Then
    If (Not ExecuteSqlBatch(strSql)) Then
      oStream.Close
      ProcessSqlFile = False
      Exit Function
    Else
      ' Clear SQL block.
      strSql = ""
    End If
  End If

  oStream.Close
  ProcessSqlFile = True
End Function

'------------------------------------------------------------------------------------
' Method:       ProcessSqlFiles
'
' Description:  Retrieve all SQL files from the given folder, finds the files which matches with file filter and Processes them.
'
' Returns:      True on success, false on failure.
'
' Parameters:   strFolder
'                   Path to the sql files folder.
'               strFileFilter
'                   File filter
'------------------------------------------------------------------------------------
Function ProcessSqlFiles(ByVal strFolder, strFileFilter)
  Dim oFolder, oFile, strSql, bSuccess

On Error Resume Next
  Err.Clear
  Set oFolder = g_oFileSystem.GetFolder(strFolder)
  strSql = ""

  If IsError() Then
    ShowError "Cannot open folder"
    ProcessSqlFiles = False
    Exit Function
  End If

  ' Process all SQL files one by one which matches with the file filter within the given folder
  For Each oFile in oFolder.Files
    If ((InStr(oFile.Name, strFileFilter) > 0) And (InStr(oFile.Name, ".sql") > 0)) Then
      If InStr(strFolder, "\") > 0 Then
        ShowFeedback "Processing " & strFolder & "\" & oFile.Name & "..."  
      Else
        ShowFeedback "Processing " & "\" & strFolder & "\" & oFile.Name & "..."
      End IF
      strSql = oFolder & "\" & oFile.Name
      bSuccess = ProcessSqlFile(strSql)

      If (not bSuccess) then
        ShowError "Failure processing SQL file"
        ProcessSqlFiles = False
        Exit Function
      End If
    End If
  Next

  ProcessSqlFiles = True
End Function

'------------------------------------------------------------------------------------
' Method:       ProcessSqlFolder
'
' Description:  Retrieve all SQL files from the given folder and Processes files.
'
' Returns:      True on success, false on failure.
'
' Parameters:   strFolder
'                   Path to the sql files folder.
'------------------------------------------------------------------------------------
Function ProcessSqlFolder(ByVal strFolder)
  Dim oFolder, oFile, strSql, bSuccess

On Error Resume Next
  Err.Clear
  Set oFolder = g_oFileSystem.GetFolder(strFolder)
  strSql = ""

  If IsError() Then
    ShowError "Cannot open folder"
    ProcessSqlFolder = False
    Exit Function
  End If

  ' Process all files within the folder one by one
  For Each oFile in oFolder.Files
    ' Avoid processing other than SQL files.
    If InStr(oFile.Name, ".sql") > 0 Then
      If InStr(strFolder, "\") > 0 Then
        ShowFeedback "Processing " & strFolder & "\" & oFile.Name & "..."  
      Else
        ShowFeedback "Processing " & "\" & strFolder & "\" & oFile.Name & "..."
      End IF
      strSql = oFolder & "\" & oFile.Name

      bSuccess = ProcessSqlFile(strSql)

      If (not bSuccess) then
        ShowError "Failure processing SQL folder"
        ProcessSqlFolder = False
        Exit Function
      End If
    End If
  Next

  ProcessSqlFolder = True
End Function

'------------------------------------------------------------------------------------
' Method:       ProcessSqlFolders
'
' Description:  Retrieve all sub folders from the given folder and Processes files under them.
'
' Returns:      True on success, false on failure.
'
' Parameters:   strFolder:        folder
'               strFolderFiltter .filter to get the sub folders
'------------------------------------------------------------------------------------
Function ProcessSqlFolders(ByVal strFolder, ByVal strFolderFilter)
  Dim oFolder, oSubFolder, bSuccess

On Error Resume Next
  Err.Clear
  Set oFolder = g_oFileSystem.GetFolder(strFolder)

  If IsError() Then
    ShowError "Cannot open folder"
    ProcessSqlFolders = False
    Exit Function
  End If
  
  ' Get sub folders within the folder one by one
  For Each oSubFolder in oFolder.SubFolders
    ' Process only folders based on folder filter given.
    If Left(oSubFolder.Name, Len(strFolderFilter)) = strFolderFilter Then
      If InStr(strFolder, "\") > 0 Then
        ShowFeedback "Processing " & strFolder & "\" & oSubFolder.Name & "..."
      Else
        ShowFeedback "Processing " & "\" & strFolder & "\" & oSubFolder.Name & "..."
      End If

      ' Process the folder files
      bSuccess = ProcessSqlFolder(strFolder & "\" & oSubFolder.Name)
  
      If (not bSuccess) then
        ShowError "Failure processing SQL folder"
        ProcessSqlFolders = False
        Exit Function
      End If
    End If
  Next

  ProcessSqlFolders = True
End Function

'------------------------------------------------------------------------------------
' Method:       IsInputStatement
'
' Description:  Determine if a given line contains an INPUT statement in the first
'               position.
'
' Returns:      True if strLine contains the INPUT keyword, false otherwise.
'
' Parameters:   strLine
'                   Line read from SQL script file.
'------------------------------------------------------------------------------------
Function IsInputStatement(ByVal strLine)
  IsInputStatement = (InStr(1, UCase(Trim(strLine)), "INPUT ") = 1)
End Function

'------------------------------------------------------------------------------------
' Method:       GetInputFileName
'
' Description:  Return the filename that follows the INPUT keyword
'
' Returns:      INPUT filename
'
' Parameters:   strLine
'                   Line read from SQL script file containing INPUT statment.
'------------------------------------------------------------------------------------
Function GetInputFileName(ByVal strLine)
  Dim strFileName

  ' Strip off "INPUT" from the front of the file name
  strFileName = Trim(Mid(strLine, InStr(1, UCase(strLine), " ")+1, Len(strLine)))

  ' If there is a trailing semicolon, remove it
  If (InStr(1, strLine, ";") > 0) Then
    strFileName = StrReverse(Mid(StrReverse(strFileName), 2, Len(strFileName)))
  End If

  GetInputFileName = strFileName
End Function

'------------------------------------------------------------------------------------
' Method:       GetInputFoldersInfo
'
' Description:  Return the foldersinfo that follows the INPUT keyword
'
' Returns:      INPUT foldersinfo
'
' Parameters:   strLine
'                   Line read from SQL script file containing INPUT statment.
'------------------------------------------------------------------------------------
Function GetInputFoldersInfo(ByVal strLine)
  Dim strFoldersInfo

  ' Strip off "INPUT" from the front of the folder name
  strFoldersInfo = Trim(Mid(strLine, InStr(1, UCase(strLine), " ")+1, Len(strLine)))

  ' If there is a trailing semicolon, remove it
  If (InStr(1, strLine, ";") > 0) Then
    strFoldersInfo = StrReverse(Mid(StrReverse(strFoldersInfo), 2, Len(strFoldersInfo)))
  End If

  GetInputFoldersInfo = strFoldersInfo
End Function

'------------------------------------------------------------------------------------
' Method:       ExecuteSqlBatch
'
' Description:  Executes a block (batch) of SQL statements.
'
' Returns:      True on success, false on failure.
'
' Parameters:   strSql
'                   SQL statements.
'------------------------------------------------------------------------------------
Function ExecuteSqlBatch(ByVal strSql)
On Error Resume Next
  g_oConnection.Errors.Clear
  Err.Clear
  g_oConnection.Execute(strSql)

  If IsError() Then
    ExecuteSqlBatch = False
  Else
    ExecuteSqlBatch = True
  End If
End Function

'------------------------------------------------------------------------------------
' Method:       IsEndOfSqlBatch
'
' Description:  Indicates whether the message contains the SQL "GO" command,
'               indicating end of batch.
'
' Returns:      True if the message contains the GO command; false otherwise.
'
' Parameters:   strLine
'                   Message containing SQL statements or comments.
'------------------------------------------------------------------------------------
Function IsEndOfSqlBatch(ByVal strLine)
    Dim strSql

    strSql = TrimAll(strLine)

    ' In the most simple case, the line will be made of just the "GO" command.
    If (Len(strSql) = Len("GO")) Then
        If (UCase(strSql) = "GO") Then
            IsEndOfSqlBatch = True
            Exit Function
        Else
            IsEndOfSqlBatch = False
            Exit Function
        End If
    End If

    ' The line contains many characters. In most cases, it will not contain "GO"
    ' in the first two bytes.
    If (UCase(Left(strSql, Len("GO"))) <> "GO") Then
        IsEndOfSqlBatch = False
        Exit Function
    End If

    ' The line starts with "GO"; let's see what follows (it can only be followed by
    ' a comment).
    strSql = TrimAll(Right(strSql, Len(strSql) - Len("GO")))

    ' Look for comment marks in the first position.
    If (InStr(strSql, "--") = 1 Or InStr(strSql, "/*") = 1) Then
        IsEndOfSqlBatch = True
        Exit Function
    End If

    IsEndOfSqlBatch = False
End Function

'------------------------------------------------------------------------------------
' Method:       GetNextLineOrLinesOfMultiLineComment
'
' Description:  Returns the next line from a SQL file. If the line contains open
'               comment (/*), this function will read all lines until it finds
'               the closing comment (*/).
'
' Returns:      Line(s) read from the open file.
'
' Parameters:   oStream
'                   Text stream for the open SQL file.
'------------------------------------------------------------------------------------
Function GetNextLineOrLinesOfMultiLineComment(ByRef oStream)
    Dim strLine, strLines

    strLine  = ""
    strLines = ""

    ' Get next line.
    strLine = oStream.ReadLine()

    ' If this is the list file, nothing else we can do.
On Error Resume Next
    If (oStream.AtEndOfStream) Then
        GetNextLineOrLinesOfMultiLineComment = strLine
        Exit Function
    End If
On Error GoTo 0

    ' Check if we got an open comment.
    If (InStr(strLine, "/*") <= 0) Then
        GetNextLineOrLinesOfMultiLineComment = strLine
        Exit Function
    End If

    ' We got an open comment. Continue reading lines until we get a closing comment.
    strLines = strLine
    Do While (Not oStream.AtEndOfStream)
        ' See if this line contains a closing comment.
        If (InStr(strLine, "*/") > 0) Then
            ' Make sure that there is no opening comment after the closing comment.
            If (InStrRev(strLine, "/*") <= 0 Or _
                  (InStrRev(strLine, "/*") < InStrRev(strLine, "*/"))) Then
                Exit Do
            End If
        End If
        strLine  = oStream.ReadLine()
        strLines = strLines & vbCrLf & strLine
    Loop

    GetNextLineOrLinesOfMultiLineComment = strLines
End Function

'------------------------------------------------------------------------------------
' Method:       CreateGlobalObjects
'
' Description:  Initializes all global objects which may be needed during setup.
'------------------------------------------------------------------------------------
Sub CreateGlobalObjects()
On Error Resume Next
  Err.Clear

  ' Create Windows-specific objects.
  Set g_oShell = CreateObject("Wscript.Shell")
  AbortOnError "Wscript.Shell failure", EXIT_ERROR
  Set g_oNetwork = CreateObject("Wscript.Network")
  AbortOnError "Wscript.Network failure", EXIT_ERROR

  ' Create ADO-specific objects.
  Set g_oConnection = CreateObject("ADODB.Connection")
  AbortOnError "ADODB.Connection failure", EXIT_ERROR
  Set g_oRecordset = CreateObject("ADODB.Recordset")
  AbortOnError "ADODB.Recordset failure", EXIT_ERROR
End Sub

'------------------------------------------------------------------------------------
' Method:       SetScriptExecutionOptions
'
' Description:  Initializes and verifies the setup options from the command-line
'               parameters.
'------------------------------------------------------------------------------------
Sub SetScriptExecutionOptions()
  Dim strValue, aAttributes, i, temp

  ' Get indicator for displaying error messages.
  If (HasParam(SWITCH_VERBOSE)) Then
      g_bVerbose = True
  End If

  ' Get indicator for displaying feedback messages.
  If (HasParam(SWITCH_SILENT)) Then
      g_bSilent = True
  End If

  ' Get indicator for keeping empty log file.
  If (HasParam(SWITCH_KEEP_LOG)) Then
      g_bKeepLog = True
  End If

  ' Get indicator for logging time stamp in the log file.
  If (HasParam(SWITCH_NO_TIME)) Then
      g_bNoTime = True
  End If

  ' Make sure that the specified database name is legal.
  g_strDBName = GetRequiredParam(SWITCH_DB_NAME, "database")
  Select Case LCase(g_strDBName)
    Case "master", "model", "msdb", "tempdb", "pubs", "northwind"
      ShowErrorAndExit "Cannot operate on a system database '" &_
                       g_strDBName & "'.", EXIT_ERROR
  End Select

  ' Get the script files folder and folder filter also if given
  aAttributes = GetParams(SWITCH_SCRIPT_FOLDER)
  If (Not IsNull(aAttributes)) Then
    Select Case UBound(aAttributes) - LBound(aAttributes)
      Case 0  ' 1 element
        g_strScriptFolder = TrimAll(aAttributes(LBound(aAttributes)))
      Case 1  ' 2 elements
        g_strScriptFolder = TrimAll(aAttributes(LBound(aAttributes)))
        g_strFolderFilter = TrimAll(aAttributes(LBound(aAttributes)+1))
      Case Else
        ShowBadParamValueErrorAndExit SWITCH_SCRIPT_FOLDER, _
                                      GetParam(SWITCH_SCRIPT_FOLDER), _
                                      EXIT_ERROR
    End Select
  End If

  ' Get path to the top-level script file
  g_strScriptFile = GetParam(SWITCH_SCRIPT_FILE)

  ' Get logging info.
  If (HasParam(SWITCH_LOG_LEVEL) Or HasParam(SWITCH_LOG_FILE)) Then
    strValue = GetParam(SWITCH_LOG_LEVEL)
    If (IsNull(strValue) Or strValue = "") Then
      g_nLogLevel = LOG_LEVEL_ALL
    Else
      Select Case UCase(strValue)
        Case "NONE"
          g_nLogLevel = LOG_LEVEL_NONE
        Case "ERROR"
          g_nLogLevel = LOG_LEVEL_ERROR
        Case "ALL"
          g_nLogLevel = LOG_LEVEL_ALL
        Case Else
          g_nLogLevel = LOG_LEVEL_NONE
          ShowBadParamValueErrorAndExit SWITCH_LOG_LEVEL, strValue, EXIT_ERROR
      End Select
    End If
  End If
  If (g_nLogLevel > LOG_LEVEL_NONE) Then
    strValue = GetParam(SWITCH_LOG_FILE)
    If (IsNull(strValue) Or strValue = "") Then
      g_strLogFile = g_oFileSystem.BuildPath( _
                     g_oFileSystem.GetParentFolderName(Wscript.ScriptFullName), _
                     g_strDBName & SETUP_LOG_FILE_EXT)
    Else
      g_strLogFile = strValue
    End If
On Error Resume Next
    ' Open log file for writing.
    Set g_oLogFile = g_oFileSystem.OpenTextFile(g_strLogFile, ForWriting, _
                                                True, TristateUseDefault)
    If IsError() Then
      ' Reset log level, so we don't attempt to write error to file.
      g_nLogLevel = LOG_LEVEL_NONE
      ShowErrorAndExit "Cannot open setup log file '" & g_strLogFile &_
                       "' for writing", EXIT_ERROR
    Else
      ShowFeedback "DATABASE SETUP STARTED"
    End If
    ' If the log file was specified, but the log level was
    If (g_strLogFile <> "" And g_nLogLevel = LOG_LEVEL_NONE) Then
      g_nLogLevel = LOG_LEVEL_ERROR
    End If
  End If

  ' Get SQL query timeout value.
  strValue = GetParam(SWITCH_TIMEOUT)
  If (Not(IsNull(strValue) Or strValue = "")) Then
    If (IsNumeric(strValue)) Then
      g_nTimeout = CInt(strValue)
    Else
      ShowBadParamValueErrorAndExit SWITCH_TIMEOUT, strValue, EXIT_ERROR
    End If
  End If

  ' If server is not specified, use local machine.
  g_strDBServer = GetParam(SWITCH_DB_SERVER)
  If (IsNull(g_strDBServer) Or g_strDBServer = "") Then
    g_strDBServer = g_oNetwork.ComputerName
  End If

  ' If user switch is missing, use NTLM. If user switch is present, but the value
  ' is missing, use "sa".
  g_strDBUser = GetParam(SWITCH_DB_USER)
  If (IsNull(g_strDBUser)) Then
     g_strDBUser = ""
  ElseIf (g_strDBUser = "") Then
    g_strDBUser = ADO_DEFAULT_SQL_USER
  End If
  ' If password switch is missing, use blank password (VERY BAD SECURITY, THOUGH).
  g_strDBPassword = GetParam(SWITCH_DB_PASSWORD)
  If (IsNull(g_strDBPassword)) Then
    g_strDBPassword = ""
  End If

  ' Get setup mode.
  strValue = GetParam(SWITCH_SETUP_MODE)
  If ((Not IsNull(strValue)) And (strValue <> "")) Then
    Select Case UCase(strValue)
      Case "DEFAULT"
        g_nSetupMode = MODE_DEFAULT
      Case "INSTALL"
        g_nSetupMode = MODE_INSTALL
      Case "UPDATE"
        g_nSetupMode = MODE_UPDATE
      Case Else
        ShowBadParamValueErrorAndExit SWITCH_SETUP_MODE, strValue,_
                                      EXIT_ERROR
    End Select
  End If

  ' Get locations of data and transaction log files.
  aAttributes = GetParams(SWITCH_DB_FILE)
  If (Not IsNull(aAttributes)) Then
    Select Case UBound(aAttributes) - LBound(aAttributes)
      Case 0  ' 1 element
        g_strDataFilePath = TrimAll(aAttributes(LBound(aAttributes)))
        g_strTLogFilePath = ""
      Case 1  ' 2 elements
        g_strDataFilePath = TrimAll(aAttributes(LBound(aAttributes)))
        g_strTLogFilePath = TrimAll(aAttributes(UBound(aAttributes)))
      Case Else
        ShowBadParamValueErrorAndExit SWITCH_DB_FILE, _
                                      GetParam(SWITCH_DB_FILE), _
                                      EXIT_ERROR
    End Select
  End If

  ' Size parameter of data files.
  aAttributes = GetParams(SWITCH_DB_SIZE)
  If (Not IsNull(aAttributes)) Then
    Select Case UBound(aAttributes) - LBound(aAttributes)
      Case 0  ' 1 element
        g_strDataInitSize = TrimAll(aAttributes(LBound(aAttributes)))
      Case 1  ' 2 elements
        g_strDataInitSize = TrimAll(aAttributes(LBound(aAttributes)))
        g_strDataMaxSize = TrimAll(aAttributes(LBound(aAttributes)+1))
      Case 2  ' 3 elements
        g_strDataInitSize = TrimAll(aAttributes(LBound(aAttributes)))
        g_strDataMaxSize = TrimAll(aAttributes(LBound(aAttributes)+1))
        g_strDataFileGrowth = TrimAll(aAttributes(LBound(aAttributes)+2))
      Case Else
        ShowBadParamValueErrorAndExit SWITCH_DB_SIZE, _
                                      GetParam(SWITCH_DB_SIZE), _
                                      EXIT_ERROR
    End Select
  End If

  ' Size parameter of log files.
  aAttributes = GetParams(SWITCH_DB_SIZE)
  If (Not IsNull(aAttributes)) Then
    Select Case UBound(aAttributes) - LBound(aAttributes)
      Case 0  ' 1 element
        g_strlogInitSize = TrimAll(aAttributes(LBound(aAttributes)))
      Case 1  ' 2 elements
        g_strlogInitSize = TrimAll(aAttributes(LBound(aAttributes)))
        g_strlogMaxSize = TrimAll(aAttributes(LBound(aAttributes)+1))
      Case 2  ' 3 elements
        g_strlogInitSize = TrimAll(aAttributes(LBound(aAttributes)))
        g_strlogMaxSize = TrimAll(aAttributes(LBound(aAttributes)+1))
        g_strlogFileGrowth = TrimAll(aAttributes(LBound(aAttributes)+2))
      Case Else
        ShowBadParamValueErrorAndExit SWITCH_LOG_SIZE, _
                                      GetParam(SWITCH_LOG_SIZE), _
                                      EXIT_ERROR
    End Select
  End If

End Sub

'------------------------------------------------------------------------------------
' Method:       VerifySqlConnectionInfo
'
' Description:  Sets up SQL connection info and tries to open it.
'------------------------------------------------------------------------------------
Sub VerifySqlConnectionInfo()
On Error Resume Next
  Err.Clear

  ' Set ADO to use OLE DB provider and define connection properties.
  g_oConnection.Provider = ADO_PROVIDER
  AbortOnError "ADODB.Connection.Provider failure", EXIT_ERROR

  ' Default connection timeout is usually too long; overwrite it.
  g_oConnection.ConnectionTimeout = ADO_CONNECTION_TIMEOUT
  AbortOnError "ADODB.Connection.ConnectionTimeout failure", EXIT_ERROR

  ' Set command (SQL query) timeout (only works on MDAC 2.6+).
  If (g_nTimeout <> ADO_DEFAULT_QUERY_TIMEOUT) Then
    g_oConnection.CommandTimeout = g_nTimeout
  End If
  AbortOnError "ADODB.Connection.CommandTimeout failure", EXIT_ERROR

  ' Set SQL Server name and default database.
  g_oConnection.Properties("Data Source").Value   = g_strDBServer
  AbortOnError "ADODB.Connection.Properties('Data Source') failure", _
               EXIT_ERROR
  g_oConnection.Properties("Initial Catalog").Value   = ADO_DEFAULT_DB
  AbortOnError "ADODB.Connection.Properties('Initial Catalog') failure", _
               EXIT_ERROR

  ' Define SQL user ID and password.
  If (g_strDBUser <> "") Then
    g_oConnection.Properties("User ID") = g_strDBUser
    AbortOnError "ADODB.Connection.Properties('User ID') failure", _
            EXIT_ERROR
    g_oConnection.Properties("Password") = g_strDBPassword
    AbortOnError "ADODB.Connection.Properties('Password') failure", _
            EXIT_ERROR

    ShowFeedback("Connecting to SQL Server '" & g_strDBServer &_
                 "' as '" & g_strDBUser & "'...")
  ' If user name is not given, use integrated Windows authentication.
  Else
    g_oConnection.Properties("Integrated Security").Value = "SSPI"
    ShowFeedback("Connecting to SQL Server '" & g_strDBServer &_
                 "' as '" & g_oNetwork.UserDomain & "\" &_
                 g_oNetwork.UserName & "'...")
  End If

  g_oConnection.Open
  AbortOnError "Cannot connect to SQL Server.", EXIT_SQL_CONNECTION_ERROR
  g_oConnection.Execute("SET NOCOUNT ON"       & vbCrLf &_
                        "SET ANSI_WARNINGS ON" & vbCrLf &_
                        "SET XACT_ABORT ON")
End Sub

'------------------------------------------------------------------------------------
' Method:       VerifySetupMode
'
' Description:  Determines setup mode.
'------------------------------------------------------------------------------------
Sub VerifySetupMode()
  Dim nResult

  ' If setup mode was explicitly defined and it is not an update, we are done.
  If (g_nSetupMode <> MODE_DEFAULT And g_nSetupMode <> MODE_UPDATE) Then
    Exit Sub
  End If

  ' If database does not exist, then we go to install mode.
  If (Not DatabaseExists()) Then
    ShowFeedback "Database does not exist, starting installation..."
    g_nSetupMode = MODE_INSTALL
    Exit Sub
  Else
    ShowFeedback "Database exists, starting update..."
    g_nSetupMode = MODE_UPDATE
  End If
End Sub

'------------------------------------------------------------------------------------
' Method:       GetRequiredParam
'
' Description:  Gets the value of a required command-line parameter. Aborts the
'               process if the value is missing.
'
' Returns:      Parameter value.
'
' Parameters:   strSwitchName
'                   Name of the command-line switch.
'               strValueName
'                   Description of parameter value.
'------------------------------------------------------------------------------------
Function GetRequiredParam(strSwitch, strValueName)
  Dim strValue

  strValue = GetParam(strSwitch)

  If (IsNull(strValue)) Then
    ShowErrorAndExit "Missing required parameter: /" & strSwitch &_
                     SWITCH_PARAM_DELIMITER & strValueName, EXIT_ERROR
  ElseIf (strValue = "") Then
    ShowErrorAndExit "Missing required parameter value: /" & strSwitch &_
                     SWITCH_PARAM_DELIMITER & strValueName, EXIT_ERROR
  End If

  GetRequiredParam = strValue
End Function

'------------------------------------------------------------------------------------
' Method:       TrimAll
'
' Description:  Untabifies and trims all white spaces from beginning and end of
'               a string.
'
' Returns:      Trimmed string
'
' Parameters:   strMsg
'                   Original string.
'------------------------------------------------------------------------------------
Function TrimAll(ByVal strMsg)
  If (IsNull(strMsg)) Then
    TrimAll = strMsg
    Exit Function
  End If

  ' Replace all white space characters by blanks.
  strMsg = Replace(strMsg, vbCr, " ")
  strMsg = Replace(strMsg, vbLf, " ")
  strMsg = Replace(strMsg, vbTab, "    ")

  TrimAll = Trim(strMsg)
End Function

'------------------------------------------------------------------------------------
' Method:       FormatSentence
'
' Description:  Untabifies and appends period at the end of the sentence, if needed.
'
' Parameters:   strMsg
'                   Original message (on input), modified message (on output).
'------------------------------------------------------------------------------------
Sub FormatSentence(ByRef strMsg)
    Dim strLastChar

  strMsg = Trim(strMsg)

  If (strMsg = "") Then
    Exit Sub
  End If

  strLastChar = Right(strMsg, 1)

  If (strLastChar <> "." And strLastChar <> "," And strLastChar <> ";") Then
    strMsg = strMsg & "."
  End If
End Sub

'------------------------------------------------------------------------------------
' Method:       GetErrorMessage
'
' Description:  Generates formatted error message from the following:
'               - Brief error message passed as a parameter.
'               - Global Err object (if Err.Number is set).
'               - Errors collection of ADODB.Connection (if Err.Number <> 0)
'               After retrieving error info from the Err and Errors objects,
'               they will be cleared.
'
' Returns:      Formatted error message.
'
' Parameters:   strMsg
'                   Brief message.
'------------------------------------------------------------------------------------
Function GetErrorMessage(ByVal strMsg)
  Dim strErrMsg       ' Formatted error message
  Dim strSource       ' Error source info
  Dim oAdoError       ' ADO connection error

  ' Trim error message.
  strMsg = TrimAll(strMsg)

  ' Check if we got error info in the Err object.
  If (Err.Number = 0) Then
    If (strMsg <> "") Then
      FormatSentence strMsg
      strErrMsg = strMsg
    Else
      strMsg = "Unknown error occurred."
      FormatSentence strMsg
      strErrMsg = strMsg
    End If
  Else
    ' Copy meaningful error source info
    If (Err.Source = "" Or Err.Source = "Microsoft VBScript runtime error") Then
      strSource = ""
    Else
      strSource = Err.Source
    End If

    ' Append period (if needed) and/or blank space to error description.
    FormatSentence strMsg

    ' Add error info retrieved from the Err object.
    If (Not g_bVerbose) Then
      strErrMsg = strMsg & vbCrLf & Err.Description
    Else
      If strSource <> "" And  Err.Description <> "" Then
        strErrMsg = strMsg & vbCrLf &_
                    "Error " & CStr(Err.Number) & " occurred in " &_
                    strSource & ": " & Err.Description
      ElseIf strSource <> "" Then
        strErrMsg = strMsg & vbCrLf & "Error " & CStr(Err.Number) & " occurred in " &_
                    strSource
      ElseIf Err.Description <> "" Then
        strErrMsg = strMsg & vbCrLf & "Error " & CStr(Err.Number) & " occurred: " &_
                    Err.Description
      Else
        strErrMsg = strMsg & vbCrLf & "Error " & CStr(Err.Number) & " occurred."
      End If
    End If

    ' Trim blanks and append a period at the end if needed.
    FormatSentence strErrMsg
  End If

  ' Check for ADO errors only if the Error object indicates error; otherwise,
  ' it will show informational messages (such as switching to a different
  ' database).

  ' If we got any ADO errors in ADODB.Connection object, add them as well.
  If (Not IsEmpty(g_oConnection) And Not IsNull(g_oConnection)) Then
    If (g_oConnection.Errors.Count > 0) Then
      For Each oAdoError In g_oConnection.Errors
        If (oAdoError.Number <> 0) Then
          If (InStr(strErrMsg, oAdoError.Description) = 0) Then
            If (Not g_bVerbose) Then
              strErrMsg = strErrMsg & vbCrLf & oAdoError.Description
            Else
              strErrMsg = strErrMsg                                & vbCrLf &_
                          "Error: "        & oAdoError.Number      & vbCrLf &_
                          "Source: "       & oAdoError.Source      & vbCrLf &_
                          "State: "        & oAdoError.SQLState    & vbCrLf &_
                          "Native error: " & oAdoError.NativeError & vbCrLf &_
                          "Description: "  & oAdoError.Description & vbCrLf
            End If
            FormatSentence strErrMsg
          End If
        End If
      Next
      ' We don't need to keep error info.
      g_oConnection.Errors.Clear
    End If
  End If

  ' We don't need to keep error info any more.
  Err.Clear
    FormatSentence strErrMsg

  GetErrorMessage = strErrMsg
End Function

'------------------------------------------------------------------------------------
' Method:       IsError
'
' Description:  Returns
'
' Returns:      True if either the VBScript Err object has Err.Number <> 0 or
'               ADOConn.Errors.Count > 0 and at least one of those ADO.Error objects
'               has a .Number other than 0. Otherwise, returns False.
'------------------------------------------------------------------------------------
Function IsError()
  Dim oAdoError

  If Err.Number <> 0 Then
    IsError = True
    Exit Function
  End If

  ' If we got any ADO errors in ADODB.Connection object, count them as well.
  If (Not IsEmpty(g_oConnection) And Not IsNull(g_oConnection)) Then
    If (g_oConnection.Errors.Count > 0) Then
      For Each oAdoError In g_oConnection.Errors
        If oAdoError.Number <> 0 Then
          IsError = True
          Exit Function
        End If
      Next
    End If
  End If

  IsError = False
End Function

'------------------------------------------------------------------------------------
' Method:       ShowError
'
' Description:  Formats and displays error information using provided brief error
'               description and contents of the global Err object.
'
' Parameters:   strMsg
'                   Brief message.
'------------------------------------------------------------------------------------
Sub ShowError(ByVal strMsg)
  Dim strErrMsg
  strErrMsg = GetErrorMessage(strMsg)

  ' Show formatted error message.
  If (Not g_bSilent) Then
    Wscript.Echo strErrMsg
  End If
  If (g_nLogLevel >= LOG_LEVEL_ERROR) Then
    AddToLog strErrMsg
  End If
End Sub

'------------------------------------------------------------------------------------
' Method:       ShowBadParamValueErrorAndExit
'
' Description:  Displays error message about invalid parameter value and aborts
'               script execution.
'
' Parameters:   strName
'                   Name of the switch.
'               strValue
'                   Parameter value.
'               nExitCode
'                   Script exit code returned to OS.
'------------------------------------------------------------------------------------
Sub ShowBadParamValueErrorAndExit(ByVal strName, ByVal strValue, ByVal nExitCode)
  ShowErrorAndExit "Invalid parameter value: /" & strName &_
                   SWITCH_PARAM_DELIMITER & strValue, nExitCode
End Sub

'------------------------------------------------------------------------------------
' Method:       ShowErrorAndExit
'
' Description:  Displays error message and aborts script execution.
'
' Parameters:   strMsg
'                   Brief message.
'               nExitCode
'                   Script exit code returned to OS.
'------------------------------------------------------------------------------------
Sub ShowErrorAndExit(ByVal strMsg, ByVal nExitCode)
  ShowError strMsg
  ShowError "SETUP WAS ABORTED."
  Wscript.Quit(nExitCode)
End Sub

'------------------------------------------------------------------------------------
' Method:       AbortOnError
'
' Description:  Checks global error objects and if it detects error displays error
'               message and aborts script execution.
'
' Parameters:   strMsg
'                   Brief message.
'               nExitCode
'                   Script exit code returned to OS.
'------------------------------------------------------------------------------------
Sub AbortOnError(ByVal strMsg, ByVal nExitCode)
  ' See if we got an error.
  If (Not IsError()) Then
    Exit Sub
  End If

  ShowErrorAndExit strMsg, nExitCode
End Sub

'------------------------------------------------------------------------------------
' Method:       ShowFeedback
'
' Description:  Displays feedback message unless setup is running in silent mode.
'               If logging option is set to include informational messages, append
'               the feedback message to the log file.
'
' Parameters:   strMsg
'                   Feedback message.
'------------------------------------------------------------------------------------
Sub ShowFeedback(ByVal strMsg)
  If (Not g_bSilent) Then
    Wscript.Echo strMsg
  End If
  If (g_nLogLevel > LOG_LEVEL_ERROR) Then
    AddToLog strMsg
  End If
End Sub

'------------------------------------------------------------------------------------
' Method:       GetParams
'
' Description:  Returns the values of the specified command-line parameter for a
'               given switch. Command-line switches are case insensitive and must be
'               specified in the form:
'                   {/|-}switch[:Attribute1,Attribute2,...]
'               For example:
'                   /in:"c:\data1.txt;c:\data2.txt"
'                   -IN:c:\data1.txt
'                   -IN:";c:\data2.txt"
'                   /iN:"c:\my data1.txt;c:\my data1.txt"
'
' Returns:      Array of parameter values (or NULL if not parameters have been
'               specified for this option or if the switch is not found).
'
' Parameters:   strSwitchName
'                   Name of the switch. The name cannot contain a preceding slash
'                   or dash character as well as a trailing colon. For example,
'                   for a command line parameter "-s:" only letter "s" must be
'                   specified.
'------------------------------------------------------------------------------------
Function GetParams(ByVal strSwitchName)
  Dim strParam

  ' Get all parameter attributes.
  strParam = GetParam(strSwitchName)
  If (IsNull(strParam) Or (strParam = "")) Then
    GetParams = Null
    Exit Function
  End If

  GetParams = Split(TrimAll(strParam), SWITCH_PARAMS_DELIMITER)
End Function

'------------------------------------------------------------------------------------
' Method:       GetParam
'
' Description:  Returns the value of the specified command-line parameter for a
'               given switch. Command-line switches are case insensitive and must
'               be specified in the form:
'                   {/|-}switch[:Value]
'               For example, the following switches are considered identical:
'                   /in:c:\data.txt
'                   -IN:c:\data.txt
'                   /iN:"c:\my data.txt"
'
' Returns:      String value of the specified command-line switch or NULL if the
'               switch has not been defined.
'
' Parameters:   strSwitchName
'                   Name of the switch. The name cannot contain a preceding slash
'                   or dash character as well as a trailing colon. For example,
'                   for a command line parameter "-s:" only letter "s" must be
'                   specified.
'------------------------------------------------------------------------------------
Function GetParam(ByVal strSwitchName)
  Dim strParam        ' Command-line parameter
  Dim i               ' Index of the argument
  Dim nPos            ' Position of the substring
  Dim strSwitch       ' Current value of the switch
  Dim strValue        ' Value of the switch

  ' Remove special characters from the switch name.
  strSwitchName = Trim(strSwitchName)
  While (Len(strSwitchName) > 0 And _
         InStr(strSwitchName, SWITCH_PARAM_DELIMITER) = Len(strSwitchName))
    strSwitchName = RTrim(Left(strSwitchName))
  Wend
  While (Len(strSwitchName) > 0 And _
         (InStr(strSwitchName, SWITCH_INDICATOR1) = Len(strSwitchName) OR _
          InStr(strSwitchName, SWITCH_INDICATOR2) = Len(strSwitchName)))
    strSwitchName = LTrim(Right(strSwitchName))
  Wend

  ' Return blank if name of the switch is not specified.
  strSwitchName = UCase(strSwitchName)
  If (strSwitchName = "") Then
    GetParam = Null
    Exit Function
  End If

  ' Loop through all command-line params until we find the one we are looking for.
  For i=0 To Wscript.Arguments.Count - 1
    ' Get next command-line argument.
    strParam = Trim(Wscript.Arguments(i))

    ' Find a switch separator character.
    nPos = InStr(strParam, SWITCH_PARAM_DELIMITER)
    If (nPos > 0) Then
      strSwitch = Trim(UCase(Left(strParam, nPos - Len(SWITCH_PARAM_DELIMITER))))
      strValue  = Trim(Right(strParam, Len(strParam) - nPos))
    Else
      strSwitch = Trim(UCase(strParam))
      strValue  = ""
    End If

    ' Check if we got our switch.
    If ((strSwitch = SWITCH_INDICATOR1 & strSwitchName) Or _
        (strSwitch = SWITCH_INDICATOR2 & strSwitchName)) Then

      ' Remove double quotes at the beginning and end of the parameter value.
      If (Len(strValue) > 0) Then
        If (InStr(strValue, """") = 1) Then
          strValue = Right(strValue, Len(strValue) - 1)
        End If
        If (InStrRev(strValue, """") = Len(strValue)) Then
          strValue = Left(strValue, Len(strValue) - 1)
        End If
      End If

      ' We are done.
      GetParam = Trim(strValue)
      Exit Function
    End If
  Next

  ' If we got here, switch was not found.
  GetParam = NULL
End Function

'------------------------------------------------------------------------------------
' Method:       HasParam
'
' Description:  Returns flag indicating whether a command-line switch was specified.
'               Command-line switches are case-insensitive and must be preceded by
'               the dash or slash character. Command-line switches are case
'               insensitive.
'
' Returns:      True if the switch was specified, false otherwise.
'
' Parameters:   strSwitchName
'                   Name of the switch. The name cannot contain a preceding slash
'                   or dash character as well as a trailing colon. For example,
'                   for a command line parameter "-s:" only letter "s" must be
'                   specified.
'------------------------------------------------------------------------------------
Function HasParam(ByVal strSwitchName)
  If (IsNull(GetParam(strSwitchName))) Then
    HasParam = False
  Else
    HasParam = True
  End If
End Function

'------------------------------------------------------------------------------------
' Method:       AddToLog
'
' Description:  Adds a message to the log file.
'
' Parameters:   strMsg
'                   Message to add.
'------------------------------------------------------------------------------------
Sub AddToLog(ByVal strMsg)
  Dim strTimeStamp

  ' Get rid of trailing blanks.
  strMsg = RTrim(strMsg)

  ' Get rid of trailing new line.
  If (InStr(strMsg, vbCrLf) = Len(strMsg)) Then
    strMsg = Left(strMsg, Len(strMsg) - Len(vbCrLf))
  End If
  ' Get rid of new line at the beginning.
  If (InStr(strMsg, vbCrLf) = 1) Then
    strMsg = Right(strMsg, Len(strMsg) - Len(vbCrLf))
  End If

  ' If we need to add a timestamp, replace all new lines by the timestamp.
  If (Not g_bNoTime) Then
    strTimeStamp =  FormatDateTime(Now, vbShortDate) & " " &_
                    FormatDateTime(Now, vbShortTime) & " "
    strMsg = strTimeStamp & Replace(strMsg, vbCrLf, vbCrLf & strTimeStamp)
  End If

On Error Resume Next
  Err.Clear
  g_oLogFile.WriteLine strMsg
  If IsError() Then
    g_nLogLevel = LOG_LEVEL_NONE
    ShowError "Cannot write to the setup log file"
  Else
    ' Since we added at least one message to the log, we should not delete it.
    g_bKeepLog = True
  End If
End Sub

'------------------------------------------------------------------------------------
' Method:       CleanUpLogFile
'
' Description:  Deletes empty log file.
'------------------------------------------------------------------------------------
Sub CleanUpLogFile()
  If ((g_nLogLevel > LOG_LEVEL_NONE) And (Not g_bKeepLog)) Then
    If (IsObject(g_oLogFile)) Then
On Error Resume Next
      Err.Clear
      g_oLogFile.Close
      Err.Clear
      g_oFileSystem.DeleteFile g_strLogFile, True
      Err.Clear
    End If
  End If
End Sub

'------------------------------------------------------------------------------------
' Method:       ShowUsage
'
' Description:  Shows the help/usage message.
'------------------------------------------------------------------------------------
Sub ShowUsage()
  Dim strMsg          ' help message

  ' We know that user wants to see help, so generate help message.
  strMsg =    _
  "DESCRIPTION:" & vbCrLf &_
  vbCrLf &_
  "  This script is used to install or update a DCCS database on a local" &_
  vbCrLf &_
  "  or remote instance of SQL Server 2000 or higher." & vbCrLf &_
  vbCrLf &_
  "USAGE:"  & vbCrLf &_
  vbCrLf &_
  "  cscript //nologo " & Wscript.ScriptName &_
  " [/option[:parameter[;...]]] [...]" & vbCrLf &_
  vbCrLf &_
  "Options:" & vbCrLf &_
  vbCrLf &_
  "  /d:databasename" & vbCrLf &_
  vbCrLf &_
  "      Name of the database. Default databases, which come with SQL Server" &_
  vbCrLf &_
  "      (such as 'master', 'msdb', 'tempdb', etc.) are not allowed. If the" &_
  vbCrLf &_
  "      database name contains blanks, enclose it in double quotes, such as" &_
  vbCrLf &_
  "      /d:""My DB"". This option is always required." & vbCrLf &_
  vbCrLf &_
  "      Example:  /d:MyDB" & vbCrLf &_
  vbCrLf &_
  "  /s:sqlservername" & vbCrLf &_
  vbCrLf &_
  "      Name or IP address of the SQL Server. This argument can include the" &_
  vbCrLf &_
  "      name of a SQL Server instance and a port number. If this option is" &_
  vbCrLf &_
  "      missing, or if the parameter is blank, the default instance of the" &_
  vbCrLf &_
  "      local SQL Server will be used." & vbCrLf &_
  vbCrLf &_
  "      Examples: /s:myserver" & vbCrLf &_
  "                /s:myserver\instance" & vbCrLf &_
  "                /s:myserver\instance,1433" & vbCrLf &_
  vbCrLf &_
  "  /u[:user]" & vbCrLf &_
  "      Login ID of the SQL Server user, who has enough privileges to" &_
  vbCrLf &_
  "      perform the setup operations. If this option is missing, the script" &_
  vbCrLf &_
  "      will use the Windows credentials of the current user. If the" &_
  vbCrLf &_
  "      option is specified, but the argument is blank, 'sa' will be used." &_
  vbCrLf &_
  vbCrLf &_
  "      Examples: /u        (same as /u:sa)" & vbCrLf &_
  "                /u:jsmith" & vbCrLf &_
  vbCrLf &_
  "  /p:password" & vbCrLf &_
  vbCrLf &_
  "      SQL password of the user specified via the /u option. If the /u" &_
  vbCrLf &_
  "      option is not specified, the password will be ignored." & vbCrLf &_
  vbCrLf &_
  "      Example:  /p:p@s5w0rd." & vbCrLf &_
  vbCrLf &_
  "  /mode:setupmode" & vbCrLf &_
  vbCrLf &_
  "      Setup mode, which can be one of the following:" &_
  vbCrLf &_
  "      'install', 'update', or 'default'. In the Default" &_
  vbCrLf &_
  "      mode, the setup will check if the database exists, and" &_
  vbCrLf &_
  "      if not, it will install it. If the setup detects that the database" &_
  vbCrLf &_
  "      exists, it will update the database. Any other parameter value will" &_
  vbCrLf &_
  "      cause an error. If this option is missing, the Default mode will be used." & vbCrLf &_
  vbCrLf &_
  "      Example:  /mode:install" & vbCrLf &_
  vbCrLf &_
  "  /o:scriptfilefolder" & vbCrLf &_
  "      Path to the folder, which contains .sql files." &_
  vbCrLf &_
  "  /f:scriptfilepath" & vbCrLf &_
  "      Path to the top-level .sql file, which can contain nested input .sql files." &_
  vbCrLf &_
  "      When specifying the path, which contains spaces, use double quotes," &_
  vbCrLf &_
  "      such as /out:""c:\dccs with spaces\common\sql\create\DccsCreate.sql""." & vbCrLf &_
  vbCrLf &_
  "      Example:  /f:c:\foxfire\dccs\common\create\sql\DccsCreate.sql." & vbCrLf &_
  vbCrLf &_
  "  /out[:logfilepath]" & vbCrLf &_
  vbCrLf &_
  "      Path to the file, which will contain setup operation status" &_
  vbCrLf &_
  "      messages and/or errors. When this option is specified with the" &_
  vbCrLf &_
  "      blank argument, the log file will be created in the same folder," &_
  vbCrLf &_
  "      where this script is located and it will be named after the" &_
  vbCrLf &_
  "      database defined via the /d switch with the .log extension. The" &_
  vbCrLf &_
  "      same logic will be used to create the log file if this option is" &_
  vbCrLf &_
  "      missing, but the /log option is set to the Error or All log level." &_
  vbCrLf &_
  "      When specifying the path, which contains spaces, use double quotes," &_
  vbCrLf &_
  "      such as /out:""c:\my dir\dbsetup.log""." & vbCrLf &_
  vbCrLf &_
  "      Examples: /out" & vbCrLf &_
  "                /out:c:\mysetup\mydb.log" & vbCrLf &_
  vbCrLf &_
  "  /log:loglevel" & vbCrLf &_
  vbCrLf &_
  "      Log level, which can be one of the following: 'none', 'error', and" &_
  vbCrLf &_
  "      'all'. All other parameter values will cause an error. If the log" &_
  vbCrLf &_
  "      level is None, no logging will be performed. In this case, the log" &_
  vbCrLf &_
  "      file will not be created even if it is specified via the /out" &_
  vbCrLf &_
  "      option. Use the Error log level to exclude informational messages" &_
  vbCrLf &_
  "      from the log file, or All to log both informational and error" &_
  vbCrLf &_
  "      messages. By default, all log entries will include timestamps," &_
  vbCrLf &_
  "      which can be removed via the /notime switch. If the log file is" &_
  vbCrLf &_
  "      specified via the /out option, but the log level is not, the All" &_
  vbCrLf &_
  "      level will be used." & vbCrLf &_
  vbCrLf &_
  "      Examples: /log:all" & vbCrLf &_
  vbCrLf &_
  "  /notime" & vbCrLf &_
  vbCrLf &_
  "      If this option is specified, timestamps will not be included in" &_
  vbCrLf &_
  "      the log file." & vbCrLf &_
  vbCrLf &_
  "  /keeplog" & vbCrLf &_
  vbCrLf &_
  "      When the log level is set to Error (via the /log option), and the" &_
  vbCrLf &_
  "      setup completes without errors, the log file will be empty. By" &_
  vbCrLf &_
  "      default, the setup script will delete the empty log file. If the" &_
  vbCrLf &_
  "      /keeplog option is is specified, the empty log file will not be" &_
  vbCrLf &_
  "      deleted." & vbCrLf &_
  vbCrLf &_
  "  /data:[databasefilepath][;transactionlogfilepath]" & vbCrLf &_
  vbCrLf &_
  "      This option can be used during database installation to specify" &_
  vbCrLf &_
  "      locations of the data and transaction log files. In the absence" &_
  vbCrLf &_
  "      of this option or its argument(s), the SQL Server defaults will" &_
  vbCrLf &_
  "      be used. Because the semicolon is used as an argument separator," &_
  vbCrLf &_
  "      the file path strings cannot contain semicolons. If any of the" &_
  vbCrLf &_
  "      arguments contain a space character, enclose them (after the colon)" &_
  vbCrLf &_
  "      in double quote characters, such as /data:""c:\my dir\mydb.mdf;" &_
  vbCrLf &_
  "      c:\my dir\mydb.ldf"". Keep in mind that when performing a database" &_
  vbCrLf &_
  "      installation on a remote server, the paths should be valid on that" &_
  vbCrLf &_
  "      server, not on the system where the setup script is running." &_
  vbCrLf &_
  vbCrLf &_
  "      Examples: /data:c:\mydir\mydb.mdf" & vbCrLf &_
  "                /data:;c:\mydir\mydb.ldf" & vbCrLf &_
  "                /data:c:\mydir\mydb.mdf;c:\mydir\mydb.ldf" & vbCrLf &_
  vbCrLf &_
  "  /timeout:querytimeout" & vbCrLf &_
  vbCrLf &_
  "      Indicates how long to wait (in seconds) while executing a SQL" &_
  vbCrLf &_
  "      command before terminating the attempt and generating an error." &_
  vbCrLf &_
  "      The timeout value is set via the CommandTimeout property of the" &_
  vbCrLf &_
  "      ADODB.Connection object. If this option is missing, the timeout" &_
  vbCrLf &_
  "      value will be set to 0 (infinite). This option may not function" &_
  vbCrLf &_
  "      properly on MDAC versions prior to 2.6. For additional" &_
  vbCrLf &_
  "      information about CommandTimeout, see the MSDN documentation." & vbCrLf &_
  vbCrLf &_
  "      Examples: /timeout:0   (no timeout)" & vbCrLf &_
  "                /timeout:60" & vbCrLf &_
  vbCrLf &_
  "  /verbose" & vbCrLf &_
  vbCrLf &_
  "      If this option is specified, all system error messages will include" &_
  vbCrLf &_
  "      detailed information (such as error numbers, sources, etc). Without" &_
  vbCrLf &_
  "      this option, error messages will only contain error descriptions." &_
  vbCrLf &_
  vbCrLf &_
  "  /silent" & vbCrLf &_
  vbCrLf &_
  "      This option will cause the setup script not to display any feedback" &_
  vbCrLf &_
  "      or error messages on the screen." & vbCrLf &_
  vbCrLf &_
  vbCrLf &_
  "  /dsize" & vbCrLf &_
  vbCrLf &_
  "      This option allows setting the Initial, Maximum, and Autogrow factor" &_
  vbCrLf &_
  "      for the database data file." & vbCrlf &_
  vbCrLf &_
  vbCrLf &_
  "  /lsize" & vbCrLf &_
  vbCrLf &_
  "      This option allows setting the Initial, Maximum, and Autogrow factor" &_
  vbCrLf &_
  "      for the database log file." & vbCrLf &_
  vbCrLf &_
  "      Examples: /dsize:" & chr(34) & "100MB;500MB;50MB" & chr(34) & vbCrLf &_
  "                /lsize:" & chr(34) & "100MB;500MB;50MB" & chr(34) & vbCrLf &_
  vbCrLf &_
  vbCrLf &_
  "  /help, /h, or /?" & vbCrLf &_
  vbCrLf &_
  "      Displays this help information. If this option is specified, all" &_
  vbCrLf &_
  "      other command-line parameters will be ignored." &_
  vbCrLf &_
  vbCrLf &_
  "For additional information, read the script's source code and comments."

  ' Show help message.
  Wscript.Echo strMsg
End Sub
