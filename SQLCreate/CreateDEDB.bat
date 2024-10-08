::/*------------------------------------------------------------------------------
::  (c) Foxfire Technologies (India) Ltd. Hyderabad, India
::
::  Revision History:
::
::  Date        Person  Comments
::
::  2024/10/08  VM      Config changes due to svn to git transitions and new Jenkins pipeline job (ADP-142/AMF-125/CIMSV3-3707/CIMSV3-3831/BK-1113)
::  2024/05/16  VM      Few DB Build Configurations: CreateDEDB.bat=>CIMSDECreate.sql (CIMSV3-3625)
::  2024/04/10  VM      Process Base procedures and functions through folders (CIMSV3-3526)
::  2024/02/28  VM      Process V3 procedures and functions through folders (CIMSV3-3430)
::  2024/02/16  VM      Changes to handle re-organization of SQL/Create, SQL/InitScript folders/files in CIMS repo (CIMSV3-3415)
::  2024/01/30  VM      Config changes to process files from new strcutured meta data folders and subfolders 
::                      This file is specific to the environments which has new structured folders/files
::                      Process folders only when they exists (HA-3952)
::  2020/12/19  VM      Initial revision to use common CreateDEDB.bat (CIMS-3100)
::------------------------------------------------------------------------------*/

echo off

:: ============================================================================
:: Change to the directory where the batch file resides: 
:: This is important to set as when Jenkins pipeline runs this batch file, Jenkins uses its workspace directory.
:: If we call any other file from this file, it will be relative to the workspace directory and
:: hence file may not be located. So, to avoid that, change the directory where this batch file resides.
:: ============================================================================
cd /d %~dp0

if not %1 == "" set servername=%1
if not %2 == "" set dbpath=%2
if not %3 == "" set dblogpath=%3
if not %4 == "" set dbname=%4
if not %5 == "" set dbfile=%5
if not %6 == "" set de_sqlinit_source_cims_path=%6
if not %7 == "" set de_sqlinit_source_client_path=%7
if not %8 == "" set cims_sqlcreate_path=%8

set dbdatafile=%dbpath%\%dbfile%.mdf
set dblogfile=%dblogpath%\%dbfile%.ldf

echo servername=%servername%
echo dbpath=%dbpath%
echo dblogpath=%dblogpath%
echo dbname=%dbname%
echo dbfile=%dbfile%
echo de_sqlinit_source_cims_path=%de_sqlinit_source_cims_path%
echo de_sqlinit_source_client_path=%de_sqlinit_source_client_path%
echo cims_sqlcreate_path=%cims_sqlcreate_path%
echo dbdatafile=%dbdatafile%
echo dblogfile=%dblogfile%

echo .
echo *****************
echo Database %dbname% creation on %servername%
echo *****************
echo .

echo Server:   %servername%
echo Database: %dbname%
rem pause

cscript //nologo %cims_sqlcreate_path%\dbsetup.vbs /s:%servername% /f:CIMSDECreate.sql /mode:install /d:%dbname% /data:%dbdatafile%;%dblogfile% /verbose /out /u:redgateuser /p:redgateuser1 

if not errorlevel 0 goto ExitWithError

echo .
echo ********************************************************************
echo Database %dbname% DE Init data upgrade on %servername%
echo ********************************************************************
echo .

cd %de_sqlinit_source_cims_path%
cscript //nologo %cims_sqlcreate_path%\dbsetup.vbs /s:%servername% /f:_init_UpgradeAll_V3DE.sql /mode:update /d:%dbname% /verbose /out:InitScripts.log /u:redgateuser /p:redgateuser1

if not errorlevel 0 goto ExitWithError

echo .
echo ********************************************************************
echo Database %dbname% Client DE Init data upgrade on %servername%
echo ********************************************************************
echo .

cd %de_sqlinit_source_client_path%
cscript //nologo %cims_sqlcreate_path%\dbsetup.vbs /s:%servername% /f:_init_UpgradeAll_V3DE_CL.sql /mode:update /d:%dbname% /verbose /out:InitScripts.log /u:redgateuser /p:redgateuser1

if not errorlevel 0 goto ExitWithError

goto Finished

:ExitWithError
echo DATABASE INSTALLATION FAILED, TERMINATING...
echo ...
pause
:Finished
