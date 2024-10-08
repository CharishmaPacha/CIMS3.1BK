/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/10/08  VM      Config changes as CIMS SQL is on Git (BK-1113)
  2024/10/08  VM      Config changes due to UI SQL (Base SQL) is on Git (CIMSV3-3831)
  2024/05/17  VM      DB Build Configurations: CreateDB.bat => BaseCreate.sql (CIMSV3-3625)
  2024/04/10  VM      Skip processing files which are split and moved to latest folders (CIMSV3-3526)
  2023/12/11  VM      domains_Access, domains_Interface, def_Logging, vwBusinessUnits, vwControls,
                      sp_EntityTypes, sp_Statuses: Moved from WMS to Base (CIMSV3-3291)
  2023/11/23  VM      Moved *LookUps from WMS to Base (CIMSV3-3209)
  2023/07/18  VM      Run all Base files from BaseCreate.sql (CIMSV3-2959)
  2023/07/14  VM      sp_Miscellaneous: Moved to top as some views dependent on some of the objects in this file
                        but commented to run from CIMSCreates.sql temporarily (CIMSV3-2957)
  2023/07/13  VM      Base\def_Presentation.sql, Base\def_Printing.sql: Commented to run from CIMSCreates.sql temporarily (CIMSV3-2951)
  2023/07/11  VM      Base\domains_Core.sql: Commented to run from CIMSCreates.sql temporarily (CIMSV3-2928)
  2023/05/22  GAG     Added vwUIPasswordRules, def_RBAC, vwUsers, vwRoles,
                      vwRolePermissions, vwUIRolePermissions, vwActiveUIRolePermissions, vwUserUIRolePermissions, trig_Permissions,
                      sp_RBAC, trig_Roles, sp_Access, sp_Users (JLCA-683)
  2023/01/17  NB      Added vwUIUserSharedPrivileges(CIMSV3-2566)
  2022/12/10  RV      Added vwDocumentLibrary (FBV3-1430)
  2021/09/22  VM      Added domains_TempTables (CIMSV3-1109)
  2022/09/16  SK      Added def_DBA.sql (CIMSV3-1815)
  2021/02/19  MS      Added vwPrintJobDetails (BK-156)
  2020/11/16  SJ      sp_PrintService.sql: Moved from WMS to Base (JL-293)
  2020/06/06  NB      Added sp_UI.sql(CIMSV3-954)
  2020/05/27  VM      Added vwPrintRequests (HA-251)
  2020/05/24  NB      Added sp_UI_DataSources (HA-101)
  2020/05/19  MS      sp_Orders: Moved procedures to WMS (HA-568)
              MS      sp_Waves: Moved procedures to WMS (HA-569)
  2020/04/24  VM      sp_Layouts.sql: Moved from WMS to Base (CIMSV3-855)
  2020/04/19  VM      File rename changes:
                        sp_Sales => sp_Orders, sp_Batching.sql => sp_Waves.sql (CIMSV3-824)
  2020/03/26  NB      Added def_Printing.sql (CIMSV3-221)
  2020/03/24  VM      domains_Shipping => domains_Printing, domains_TempTables => domains_Presentation (CIMSV3-778)
                      Moved vwTables, vwWaves to WMS (CIMSV3-778)
  2020/02/03  NB      Added sp_devices.sql(CIMSV3-687)
  2019/11/26  NB      Added sp_reports.sql(CIMSV3-658)
  2019/05/07  VM      Added more files (CIMSV3-406)
  2019/03/08  VM      Initial Revision (CIMSV3-406).
------------------------------------------------------------------------------*/

/* Row Versioning */
declare @sSql nvarchar(80);
set @sSql = 'Alter Database ' + DB_Name() + ' set Read_Committed_Snapshot On;';
exec(@sSql);
Go

/* Base DataTypes, TableTypes, Tables, Views, Functions, Procedures, Triggers and Finalize objects */
Input ..\SQL_UI\SQL\DataTypes;
Input ..\SQL_UI\SQL\TableTypes;
Input ..\SQL_UI\SQL\Tables;
Input ..\SQL_UI\SQL\Functions|fn_*;
Input ..\SQL_UI\SQL\Views;
Input ..\SQL_UI\SQL\Procedures|sp_*;
Input ..\SQL_UI\SQL\Triggers;
Input ..\SQL_UI\SQL\Finalize;

Go
