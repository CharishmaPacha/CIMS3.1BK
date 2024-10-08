/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/10/08  VM      Config changes due to UI SQL (Base SQL) is on Git (CIMSV3-3831)
  2024/05/16  VM      DB Build Configurations: CreateDEDB.bat=>CIMSDECreate.sql (CIMSV3-3625)
  2024/04/10  VM      Base objects/files: Process exact objects and skip processing files which are split and moved to latest folders (CIMSV3-3526)
  2020/08/18  SK      Added sp_Miscellaneous.sql (HA-1267)
  2020/06/22  VM      Added sp_DE_Custom.sql (HA-1019)
  2020/06/19  VM      Added def_DE_Custom.sql (HA-1011)
  2020/04/19  VM      domains_Purchasing => domains_Receipts, domains_Sales => domains_Orders (CIMSV3-824)
  2020/04/11  VM      Added sp_Deploy.sql (CIMS-3069)
  2020/03/20  SK      Added sp_Admin.sql (HA-29)
  2020/02/26  AJM     Added domains_DE.sql (CIMS-2966)
  2017/10/30  TD      Initial Revision.
------------------------------------------------------------------------------*/

/* Row Versioning */
declare @sSql nvarchar(80);
set @sSql = 'Alter Database ' + DB_Name() + ' set Read_Committed_Snapshot On;';
exec(@sSql);
Go

/* Base DataTypes for DE - specific */
Input ..\SQL_UI\SQL\DataTypes\domains_Contacts.sql;
Input ..\SQL_UI\SQL\DataTypes\domains_Core.sql;

/* Base TableTypes for DE - specific */
Input ..\SQL_UI\SQL\TableTypes\TAuditDetails.sql;
Input ..\SQL_UI\SQL\TableTypes\TContentTemplates.sql;
Input ..\SQL_UI\SQL\TableTypes\TControlsTable.sql;
Input ..\SQL_UI\SQL\TableTypes\TEntityKeysTable.sql;
Input ..\SQL_UI\SQL\TableTypes\TEntityStatusCounts.sql;
Input ..\SQL_UI\SQL\TableTypes\TErrorInfo.sql;
Input ..\SQL_UI\SQL\TableTypes\TJobStepsInfo.sql;
Input ..\SQL_UI\SQL\TableTypes\TMarkers.sql;

/* WMS DataTypes for DE - specific */
Input ..\SQL_CIMS\SQL\DataTypes\domains_Core.sql;
Input ..\SQL_CIMS\SQL\DataTypes\domains_Inventory.sql;
Input ..\SQL_CIMS\SQL\DataTypes\domains_Contacts.sql;
Input ..\SQL_CIMS\SQL\DataTypes\domains_Orders.sql;
/* Depends on domains_Orders */
Input ..\SQL_CIMS\SQL\DataTypes\domains_Cubing.sql;
Input ..\SQL_CIMS\SQL\DataTypes\domains_Shipping.sql;
Input ..\SQL_CIMS\SQL\DataTypes\domains_Receipts.sql;
/* Depends on domains_Receipts */
Input ..\SQL_CIMS\SQL\DataTypes\domains_Interface.sql;
Input ..\SQL_CIMS\SQL\DataTypes\domains_Packing.sql;
Input ..\SQL_CIMS\SQL\DataTypes\domains_Tasks.sql;

/* WMS TableTypes for DE - specific */
/* Imports */
Input ..\SQL_CIMS\SQL\TableTypes\TASNLPNDetailImportType.sql;
Input ..\SQL_CIMS\SQL\TableTypes\TASNLPNImportType.sql;
Input ..\SQL_CIMS\SQL\TableTypes\TCartonTypesImportType.sql;
Input ..\SQL_CIMS\SQL\TableTypes\TContactImportType.sql;
Input ..\SQL_CIMS\SQL\TableTypes\TLocationImportType.sql;
Input ..\SQL_CIMS\SQL\TableTypes\TNoteImportType.sql;
Input ..\SQL_CIMS\SQL\TableTypes\TOrderDetailsImportType.sql;
Input ..\SQL_CIMS\SQL\TableTypes\TOrderHeaderImportType.sql;
Input ..\SQL_CIMS\SQL\TableTypes\TPackDetails.sql;
Input ..\SQL_CIMS\SQL\TableTypes\TReceiptDetailImportType.sql;
Input ..\SQL_CIMS\SQL\TableTypes\TReceiptHeaderImportType.sql;
Input ..\SQL_CIMS\SQL\TableTypes\TSKUAttributeImportType.sql;
Input ..\SQL_CIMS\SQL\TableTypes\TSKUImportType.sql;
Input ..\SQL_CIMS\SQL\TableTypes\TSKUPrepacksImportType.sql;
Input ..\SQL_CIMS\SQL\TableTypes\TUPCImportType.sql;
Input ..\SQL_CIMS\SQL\TableTypes\TImportInvAdjustments.sql;
/* Exports */
Input ..\SQL_CIMS\SQL\TableTypes\TExportsType.sql;
Input ..\SQL_CIMS\SQL\TableTypes\TExportCarrierTrackingInfo.sql;
Input ..\SQL_CIMS\SQL\TableTypes\TExportInvSnapshot.sql;
--Input ..\SQL_CIMS\SQL\TableTypes\TExportOrderDetails.sql;
Input ..\SQL_CIMS\SQL\TableTypes\TOnhandInventoryExportType.sql;
Input ..\SQL_CIMS\SQL\TableTypes\TOpenOrderExportType.sql;
Input ..\SQL_CIMS\SQL\TableTypes\TOpenOrdersSummary.sql;
Input ..\SQL_CIMS\SQL\TableTypes\TOpenReceiptExportType.sql;
Input ..\SQL_CIMS\SQL\TableTypes\TShippedLoadsExportType.sql;

/* Base Tables for DE - specific */
Input ..\SQL_UI\SQL\Tables\BusinessUnits.sql;
Input ..\SQL_UI\SQL\Tables\EventMonitor.sql;
/* Statuses - Required in vwBU */
Input ..\SQL_UI\SQL\Tables\Statuses.sql;

/* Base Views for DE - specific */
Input ..\SQL_UI\SQL\Views\vwBusinessUnits.sql;

/* Base Functions for DE - specific */
Input ..\SQL_UI\SQL\Functions\fn_Miscellaneous;
Input ..\SQL_UI\SQL\Functions\fn_Controls;

/* Base Procedures for DE - specific */
Input ..\SQL_UI\SQL\Procedures\sp_Miscellaneous;
Input ..\SQL_UI\SQL\Procedures\sp_Controls;
Input ..\SQL_UI\SQL\Procedures\sp_Deploy;
Input ..\SQL_UI\SQL\Procedures\sp_Jobs;

/* DE DataTypes, TableTypes, Tables, Views, Functions, Procedures and Triggers */
Input ..\SQL_CIMS\CIMSDE\SQL\DataTypes;
Input ..\SQL_CIMS\CIMSDE\SQL\TableTypes;
Input ..\SQL_CIMS\CIMSDE\SQL\Tables;
Input ..\SQL_CIMS\CIMSDE\SQL\Views;
Input ..\SQL_CIMS\CIMSDE\SQL\Functions|fn_*;
Input ..\SQL_CIMS\CIMSDE\SQL\Procedures|sp_*;
Input ..\SQL_CIMS\CIMSDE\SQL\Triggers;

/* WMS Functions and Procedures for DE - specific */
Input ..\SQL_CIMS\SQL\Functions\fn_Miscellaneous;
Input ..\SQL_CIMS\SQL\Procedures\sp_Admin;
Input ..\SQL_CIMS\SQL\Procedures\sp_Miscellaneous;

Go
