/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/09/30  VS      Added TControlsTable, TJobStepsInfo (HA-3084)
  2021/03/19  MS      Added TImportInvAdjustments (HA-2341)
  2021/02/16  VM      Added TExportCarrierTrackingInfo (BK-207)
  2020/08/18  SK      Added TEntityKeysTable (HA-1267)
  2020/08/12  MS      Added TOpenOrdersSummary(HA-1248)
  2020/05/13  MS      Removed TImportValidationType, TSKUPrepacksImportValidation, TReceiptDetailValidationType
                      TLocationImportType (HA-483)
  2020/02/20  MS/AJM  Initial Revision (CIMS-2966)
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
  To build the Blank DB for DE database, as of now we are using domains_Core.sql,
  domains_Inventory.sql etc.. files. In this flow we are creating
  unnecessary domains as well in database, which are not used in DE DB.
  Below script is to drop all those domains which are not used by the database.
  List given in this file includes only the TableTypes which are only used in DE.
------------------------------------------------------------------------------*/

declare @vSQL   nvarchar(max) = '';
declare @ttDEUDTs table(Name     varchar(max),
                        RecordId Integer Identity(1,1))

/* Insert all Domains which are using in DE */
insert into @ttDEUDTs(Name)
/* Imports */
      select 'TASNLPNDetailImportType'
union select 'TASNLPNImportType'
union select 'TCartonTypesImportType'
union select 'TContactImportType'
union select 'TLocationImportType'
union select 'TNoteImportType'
union select 'TOrderDetailsImportType'
union select 'TOrderHeaderImportType'
union select 'TReceiptDetailImportType'
union select 'TReceiptHeaderImportType'
union select 'TSKUAttributeImportType'
union select 'TSKUImportType'
union select 'TSKUPrepacksImportType'
union select 'TUPCImportType'
union select 'TImportInvAdjustments'
/* Exports */
union select 'TExportsType'
union select 'TExportCarrierTrackingInfo'
union select 'TExportInvSnapshot'
union select 'TOnhandInventoryExportType'
union select 'TOpenOrderExportType'
union select 'TOpenOrdersSummary'
union select 'TOpenReceiptExportType'
union select 'TShippedLoadsExportType'
/* Controls */
union select 'TControlsTable'
union select 'TJobStepsInfo'

/* Miscellaneous */
union select 'TEntityKeysTable'

/* select and drop all tabletypes which are not using in DE DB */
select @vSQL += 'Drop Type ' + STT.Name + ';'
from sys.table_types STT
  left outer join @ttDEUDTs DE on STT.Name = DE.Name
where (DE.Name is null /* which are not in the DEUDTs table */) and
      (STT.is_user_defined = 1)

exec(@vSQL);

Go
