/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/17  SK      Added Field name (HA-1567)
  2020/07/13  MS      Initial Revision (CIMSV3-548)
------------------------------------------------------------------------------*/

Go

declare @FormName TName;

/*------------------------------------------------------------------------------*/
/* select Locations Parameter Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'CycleCount_CycleCountLocations';  -- This should be like MenuId_Context, since it is input Param Dataset

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
             (FieldName,               ControlName,           FieldCaption,                IsRequired,    DefaultValue, SortSeq, DataTagType, DataTagName,        FormName,  BusinessUnit)
      select 'LocationType',          'LocationType_DD',      'Location Type' ,            1,             'R',          1,       'Data',      'LocationType',     @FormName, BusinessUnit from vwBusinessUnits
union select 'StorageType',           'StorageType_DD',       'Storage Type' ,             null,          null,         2,       'Data',      'StorageType',      @FormName, BusinessUnit from vwBusinessUnits
union select 'PutawayZone',           'PutawayZone_DD',       'Putaway Zone',              null,          null,         3,       'Data',      'PutawayZone',      @FormName, BusinessUnit from vwBusinessUnits
union select 'PickingZone',           'PickZone_DD',          'Pick Zone',                 null,          null,         4,       'Data',      'PickingZone',      @FormName, BusinessUnit from vwBusinessUnits
union select 'PendingCCLoc',          'YesNo_DD',             'Show Pending CC Locations', 1,             'N',          5,       'Data',      'PendingCCLoc',     @FormName, BusinessUnit from vwBusinessUnits
union select 'CCLocationDetail',      'CC_LocationDetail_DD', 'Location Detail',           1,             'LOC',        6,       'Data',      'CCLocationDetail', @FormName, BusinessUnit from vwBusinessUnits
union select 'SKU',                   'SKU_DD',               'SKU',                       null,          null,         7,       'Data',      'SKU',              @FormName, BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* CC Create Tasks Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'CC_CreateTasks';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
            (FieldName,               ControlName,             FieldCaption,    FieldHint,           IsRequired, DefaultValue,          SortSeq, DataTagType, DataTagName,        FormName,  BusinessUnit)
      select 'CCProcess',             'CC_Process_DD',         'CC Process',    null,                1,          'CC',                  1,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'CCLevel',               'CC_Level_DD',           'Count Level',   null,                1,          '_1',                  2,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'Priority',              'IntegerMin0',           null,            null,                1,          '5',                   3,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'ScheduledDate',         'DateFuture',            null,            null,                1,          'Today',               4,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits

Go
