::/*------------------------------------------------------------------------------
::  (c) Foxfire Technologies (India) Ltd. Hyderabad, India
::
::  Revision History:
::
::  Date        Person  Comments
::
::  2024/10/08  VM      Config changes due to svn to git transitions and new Jenkins pipeline job (ADP-142/AMF-125/CIMSV3-3707/CIMSV3-3831/BK-1113)
::  2024/05/17  VM      DB Build Configurations: CreateDB.bat => BaseCreate.sql, CIMSCreate.sql, _init_Base.sql
::                      Moved all InitDB.bat configs to _init_All.sql and so deprecated InitDB.bat (CIMSV3-3625)
::  2024/04/12  VM      Process base FieldAttributes, Forms, EntityInfo and Selections by folder (CIMSV3-3327)
::  2024/04/10  VM      Process base files by folders (CIMSV3-3526)
::  2024/02/16  VM      Changes to handle re-organization of SQL/Create, SQL/InitScript folders/files in CIMS repo (CIMSV3-3415)
::  2024/01/23  VM      Process folders only when they exists (JLFL-893)
::  2024/01/22  VM      This file is specific to the environments which has new structured folders/files (JLFL-835/JLCA-1249)
::  2024/01/04  VM      Config changes to process files from new strcutured meta data folders and subfolders (JLFL-835)
::  2023/12/14  VM      Config changes to run init_BU.sql and _init_Base.sql right after BaseCreate.sql (CIMSV3-3291)
::  2023/07/18  VM      Run BaseCreate.sql first than CIMSCreate.sql (CIMSV3-2959)
::  2022/08/10  VM      Made call to _init_Finalize (HA-2976)
::  2021/12/22  VM      Included Patch_Version Patches (CIMSV3-1797)
::  2021/03/04  YJ      Included API projects (BK-243)
::  2020/12/19  VM      Configure Custom RF Meta data upgrades (CIMSV3-1279)
::  2020/12/18  VM      Initial revision to use common CreateDB.bat (CIMS-3100)
::  2020/12/04  VM      Configure Release Patches for both Meta data and Data upgrades (CIMSV3-1260)
::  2020/12/03  VM      (CIMSV3-1260)
::                      Configure Custom Meta data upgrades
::                      Configure Custom Patches Meta data and Init Data upgrades
::------------------------------------------------------------------------------*/

echo off
setlocal

:: ============================================================================
:: Change to the directory where the batch file resides: 
:: This is important to set as when Jenkins pipeline runs this batch file, Jenkins uses its workspace directory.
:: If we call any other file from this file, it will be relative to the workspace directory and
:: hence file may not be located. So, to avoid that, change the directory where this batch file resides.
:: ============================================================================
cd /d %~dp0

:: Initialize a counter to track the current parameter
set count=1

:: ============================================================================
:: To handle more than 9 parameters in a batch file, you need to use the SHIFT command
::   to shift parameters and access those beyond %9. Batch files do not support direct access 
::   to parameters beyond %9 (e.g., %10, %11, etc.) without shifting.
:: The count variable is initialized to 1 and incremented after processing each parameter
::   to keep track of which parameter is being processed.
:: Shift Parameters: The shift command shifts all parameters to the left, so %2 becomes %1, %3 becomes %2, and so on.
::   This allows the loop to access parameters beyond %9
:: Loop through all parameters and assign params to variables.
::
:: %~1 to remove surrounding quotes of param value 
::   as an example 'servername' below is sent in quotes to handle comma(,) in it like "13.126.62.109\SQL2019DEV,1534".
::   So, we need to strip off quotes, used it.
:: ============================================================================
:loop
if "%~1"=="" goto end

if %count%==1 set servername=%~1
if %count%==2 set dbpath=%1
if %count%==3 set dblogpath=%1
if %count%==4 set dbname=%1
if %count%==5 set dbfile=%1
if %count%==6 set adp_sql_source_path=%1
if %count%==7 set adp_sqlinit_source_path=%1
if %count%==8 set adp_sql_source_cims_path=%1
if %count%==9 set adp_sqlinit_source_cims_path=%1
if %count%==10 set adp_sql_source_client_path=%1
if %count%==11 set adp_sqlinit_source_client_path=%1
if %count%==12 set aaf_sql_source_path=%1
if %count%==13 set aaf_sqlinit_source_path=%1
if %count%==14 set aaf_sql_source_cims_path=%1
if %count%==15 set aaf_sqlinit_source_cims_path=%1
if %count%==16 set aaf_sql_source_client_path=%1
if %count%==17 set aaf_sqlinit_source_client_path=%1
if %count%==18 set amf_sql_source_path=%1
if %count%==19 set amf_sqlinit_source_path=%1
if %count%==20 set amf_sql_source_cims_path=%1
if %count%==21 set amf_sqlinit_source_cims_path=%1
if %count%==22 set amf_sql_source_client_path=%1
if %count%==23 set amf_sqlinit_source_client_path=%1
if %count%==24 set de_sql_source_cims_path=%1
if %count%==25 set de_sqlinit_source_cims_path=%1
if %count%==26 set de_sql_source_client_path=%1
if %count%==27 set de_sqlinit_source_client_path=%1
if %count%==28 set ui_sql_source_path=%1
if %count%==29 set ui_sqlinit_source_path=%1
if %count%==30 set ui_sql_source_cims_path=%1
if %count%==31 set ui_sqlinit_source_cims_path=%1
if %count%==32 set ui_sql_source_client_path=%1
if %count%==33 set ui_sqlinit_source_client_path=%1
if %count%==34 set cims_sql_source_path=%1
if %count%==35 set cims_sqlinit_source_path=%1
if %count%==36 set cims_sql_patches_source_path=%1
if %count%==37 set cims_sqlinit_patches_source_path=%1
if %count%==38 set cims_sqlcreate_path=%1
if %count%==39 set cims_sql_source_client_path=%1
if %count%==40 set cims_sqlinit_source_client_path=%1
if %count%==41 set cims_sql_patches_source_client_path=%1
if %count%==42 set cims_sqlinit_patches_source_client_path=%1
if %count%==43 set cims_sqldeploy_source_client_path=%1
if %count%==44 set cims_sqlcreate_client_path=%1

:: Increment the counter and shift parameters
set /a count+=1
shift
goto loop

:end

set dbdatafile=%dbpath%\%dbfile%.mdf
set dblogfile=%dblogpath%\%dbfile%.ldf

echo servername: %servername%
echo dbpath: %dbpath%
echo dblogpath: %dblogpath%
echo dbname: %dbname%
echo dbfile: %dbfile%
echo adp_sql_source_path: %adp_sql_source_path%
echo adp_sqlinit_source_path: %adp_sqlinit_source_path%
echo adp_sql_source_cims_path: %adp_sql_source_cims_path%
echo adp_sqlinit_source_cims_path: %adp_sqlinit_source_cims_path%
echo adp_sql_source_client_path: %adp_sql_source_client_path%
echo adp_sqlinit_source_client_path: %adp_sqlinit_source_client_path%
echo aaf_sql_source_path: %aaf_sql_source_path%
echo aaf_sqlinit_source_path: %aaf_sqlinit_source_path%
echo aaf_sql_source_cims_path: %aaf_sql_source_cims_path%
echo aaf_sqlinit_source_cims_path: %aaf_sqlinit_source_cims_path%
echo aaf_sql_source_client_path: %aaf_sql_source_client_path%
echo aaf_sqlinit_source_client_path: %aaf_sqlinit_source_client_path%
echo amf_sql_source_path: %amf_sql_source_path%
echo amf_sqlinit_source_path: %amf_sqlinit_source_path%
echo amf_sql_source_cims_path: %amf_sql_source_cims_path%
echo amf_sqlinit_source_cims_path: %amf_sqlinit_source_cims_path%
echo amf_sql_source_client_path: %amf_sql_source_client_path%
echo amf_sqlinit_source_client_path: %amf_sqlinit_source_client_path%
echo de_sql_source_cims_path: %de_sql_source_cims_path%
echo de_sqlinit_source_cims_path: %de_sqlinit_source_cims_path%
echo de_sql_source_client_path: %de_sql_source_client_path%
echo de_sqlinit_source_client_path: %de_sqlinit_source_client_path%
echo ui_sql_source_path: %ui_sql_source_path%
echo ui_sqlinit_source_path: %ui_sqlinit_source_path%
echo ui_sql_source_cims_path: %ui_sql_source_cims_path%
echo ui_sqlinit_source_cims_path: %ui_sqlinit_source_cims_path%
echo ui_sql_source_client_path: %ui_sql_source_client_path%
echo ui_sqlinit_source_client_path: %ui_sqlinit_source_client_path%
echo cims_sql_source_path: %cims_sql_source_path%
echo cims_sqlinit_source_path: %cims_sqlinit_source_path%
echo cims_sql_patches_source_path: %cims_sql_patches_source_path%
echo cims_sqlinit_patches_source_path: %cims_sqlinit_patches_source_path%
echo cims_sqlcreate_path: %cims_sqlcreate_path%
echo cims_sql_source_client_path: %cims_sql_source_client_path%
echo cims_sqlinit_source_client_path: %cims_sqlinit_source_client_path%
echo cims_sql_patches_source_client_path: %cims_sql_patches_source_client_path%
echo cims_sqlinit_patches_source_client_path: %cims_sqlinit_patches_source_client_path%
echo cims_sqldeploy_source_client_path: %cims_sqldeploy_source_client_path%
echo cims_sqlcreate_client_path: %cims_sqlcreate_client_path%

echo .
echo ********************************************************************
echo Database %dbname% creation on %servername%
echo ********************************************************************
echo .

echo Server:   %servername%
echo Database: %dbname%
rem pause

echo .
echo ********************************************************************
echo Database %dbname% Base Meta data upgrade on %servername%
echo ********************************************************************
echo .

cscript //nologo %cims_sqlcreate_path%\dbsetup.vbs /s:%servername% /f:BaseCreate.sql /mode:install /d:%dbname% /data:%dbdatafile%;%dblogfile% /verbose /out /u:redgateuser /p:redgateuser1

if not errorlevel 0 goto ExitWithError

echo .
echo ********************************************************************
echo Database %dbname% Base Init data on %servername%
echo ********************************************************************
echo .

cd %ui_sqlinit_source_path%
cscript //nologo %cims_sqlcreate_path%\dbsetup.vbs /s:%servername% /f:_init_Base.sql /mode:update /d:%dbname% /verbose /out:InitScripts.log /u:redgateuser /p:redgateuser1

if not errorlevel 0 goto ExitWithError

echo .
echo ********************************************************************
echo Database %dbname% WMS V3 Meta data on %servername%
echo ********************************************************************
echo .

cd %cims_sqlcreate_path%
cscript //nologo %cims_sqlcreate_path%\dbsetup.vbs /s:%servername% /f:CIMSCreate.sql /mode:update /d:%dbname% /data:%dbdatafile%;%dblogfile% /verbose /out /u:redgateuser /p:redgateuser1

if not errorlevel 0 goto ExitWithError

echo .
echo ********************************************************************
echo Database %dbname% Client Patches Meta data upgrade on %servername%
echo ********************************************************************
echo .

if exist "%cims_sql_patches_source_client_path%" (
  cd %cims_sql_patches_source_client_path%
  cd..
  cscript //nologo %cims_sqlcreate_path%\dbsetup.vbs /s:%servername% /o:SQL /mode:update /d:%dbname% /data:%dbdatafile%;%dblogfile% /verbose /out /u:redgateuser /p:redgateuser1
)
if not errorlevel 0 goto ExitWithError

echo .
echo ********************************************************************
echo Database %dbname% WMS V3 Init data upgrade on %servername% 
echo ********************************************************************
echo .

cd %cims_sqlinit_source_path%
cscript //nologo %cims_sqlcreate_path%\dbsetup.vbs /s:%servername% /f:_init_All.sql /mode:update /d:%dbname% /verbose /out:InitScripts.log /u:redgateuser /p:redgateuser1

if not errorlevel 0 goto ExitWithError

echo .
echo ********************************************************************
echo Database %dbname% V3_RF Init data upgrade on %servername%
echo ********************************************************************
echo .

cd %amf_sqlinit_source_path%
cscript //nologo %cims_sqlcreate_path%\dbsetup.vbs /s:%servername% /f:_init_UpgradeAll_V3RF.sql /mode:update /d:%dbname% /verbose /out:InitScripts.log /u:redgateuser /p:redgateuser1

if not errorlevel 0 goto ExitWithError

echo .
echo ********************************************************************
echo Database %dbname% V3_DaB Init data upgrade on %servername%
echo ********************************************************************
echo .

cd %adp_sqlinit_source_path%
cscript //nologo %cims_sqlcreate_path%\dbsetup.vbs /s:%servername% /f:_init_UpgradeAll_V3DaB.sql /mode:update /d:%dbname% /verbose /out:InitScripts.log /u:redgateuser /p:redgateuser1

if not errorlevel 0 goto ExitWithError

echo .
echo ********************************************************************
echo Database %dbname% V3_API Init data upgrade on %servername%
echo ********************************************************************
echo .

cd %aaf_sqlinit_source_path%
cscript //nologo %cims_sqlcreate_path%\dbsetup.vbs /s:%servername% /f:_init_UpgradeAll_V3API.sql /mode:update /d:%dbname% /verbose /out:InitScripts.log /u:redgateuser /p:redgateuser1

if not errorlevel 0 goto ExitWithError

echo .
echo ********************************************************************
echo Database %dbname% V3_API Client Init data upgrade on %servername%
echo ********************************************************************
echo .

cd %aaf_sqlinit_source_client_path%
cscript //nologo %cims_sqlcreate_path%\dbsetup.vbs /s:%servername% /f:_init_UpgradeAll_V3API_CL.sql /mode:update /d:%dbname% /verbose /out:InitScripts.log /u:redgateuser /p:redgateuser1

if not errorlevel 0 goto ExitWithError

echo .
echo ********************************************************************
echo Database %dbname% Client Init data upgrade on %servername%
echo ********************************************************************
echo .

cd %cims_sqlinit_source_client_path%
cscript //nologo %cims_sqlcreate_path%\dbsetup.vbs /s:%servername% /f:_init_UpgradeAll_CL.sql /mode:update /d:%dbname% /verbose /out:InitScripts.log /u:redgateuser /p:redgateuser1

if not errorlevel 0 goto ExitWithError

echo .
echo ********************************************************************
echo Database %dbname% Client RF Init data upgrade on %servername%
echo ********************************************************************
echo .

cd %amf_sqlinit_source_client_path%
cscript //nologo %cims_sqlcreate_path%\dbsetup.vbs /s:%servername% /f:_init_UpgradeAll_V3RF_CL.sql /mode:update /d:%dbname% /verbose /out:InitScripts.log /u:redgateuser /p:redgateuser1

if not errorlevel 0 goto ExitWithError

echo .
echo ********************************************************************
echo Database %dbname% Release Patches Init data upgrade on %servername%
echo ********************************************************************
echo .

cd %cims_sqlinit_patches_source_path%
cd..
cscript //nologo %cims_sqlcreate_path%\dbsetup.vbs /s:%servername% /o:SQLInit /mode:update /d:%dbname% /data:%dbdatafile%;%dblogfile% /verbose /out /u:redgateuser /p:redgateuser1

if not errorlevel 0 goto ExitWithError

echo .
echo ********************************************************************
echo Database %dbname% Client Patches Init data upgrade on %servername%
echo ********************************************************************
echo .

if exist %cims_sqlinit_patches_source_client_path% (
  cd %cims_sqlinit_patches_source_client_path%
  cd..
  cscript //nologo %cims_sqlcreate_path%\dbsetup.vbs /s:%servername% /o:SQLInit /mode:update /d:%dbname% /data:%dbdatafile%;%dblogfile% /verbose /out /u:redgateuser /p:redgateuser1
)
if not errorlevel 0 goto ExitWithError

echo .
echo ********************************************************************
echo Database %dbname% CIMS Init Finalize on %servername%
echo ********************************************************************
echo .

cd %cims_sqlinit_source_path%\Main
cscript //nologo %cims_sqlcreate_path%\dbsetup.vbs /s:%servername% /f:_init_Finalize.sql /mode:update /d:%dbname% /verbose /out:InitScripts.log /u:redgateuser /p:redgateuser1

if not errorlevel 0 goto ExitWithError

echo .
echo ********************************************************************
echo Database %dbname% CIMS finalize on %servername%
echo ********************************************************************
echo .

cd %cims_sqlcreate_path%
cscript //nologo %cims_sqlcreate_path%\dbsetup.vbs /s:%servername% /f:CIMSFinalize.sql /mode:update /d:%dbname% /data:%dbdatafile%;%dblogfile% /verbose /out /u:redgateuser /p:redgateuser1

goto Finished

:ExitWithError
echo DATABASE INSTALLATION FAILED, TERMINATING...
echo ...
pause
:Finished
