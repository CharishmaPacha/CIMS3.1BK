/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/05/27  NB      Initial Revision(HA-368)
------------------------------------------------------------------------------*/

Go

declare @FormName  TName;

/*------------------------------------------------------------------------------*/
/* Manage Replenishments Parameter Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'Replenishments_ManageReplenishments';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
             (FieldName,               ControlName,           FieldCaption,            IsRequired, DefaultValue, SortSeq, DataTagType, DataTagName,        FormName,  BusinessUnit)
      select 'PickingZone',           'PickZone_DD',          'Pick Zone',             null,       null,         1,       'Data',      'PickingZone',      @FormName, BusinessUnit from vwBusinessUnits
union select 'PutawayZone',           'PutawayZone_DD',       'Putaway Zone',          null,       null,         2,       'Data',      'PutawayZone',      @FormName, BusinessUnit from vwBusinessUnits
union select 'StorageType',           'StorageType_DD',       'Storage Type' ,         null,       null,         3,       'Data',      'StorageType',      @FormName, BusinessUnit from vwBusinessUnits
union select 'ReplenishType',         'ReplenishType_CBDD',   'Replenish Type' ,       1,          'R',          4,       'Data',      'ReplenishType',    @FormName, BusinessUnit from vwBusinessUnits
union select 'SKU',                   'SKU_DD',               'SKU',                   null,       null,         5,       'Data',      'SKU',              @FormName, BusinessUnit from vwBusinessUnits


Go
