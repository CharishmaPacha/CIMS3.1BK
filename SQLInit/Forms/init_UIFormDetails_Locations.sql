/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/06  AJM     Added LocationSubType in Location_ChangeType form (CIMSV3-1429)
  2020/12/18  AJM     Changed the control name in Location_AllowedOperations form (CIMSV3-1280)
  2020/10/08  MRK     Location_PrintLabels: Added NumCopies (CIMSV3-1115)
  2020/08/11  NB      Location_PrintLabels: defined HandlerTagName for LabelPrinter for Local Printer Support(CIMSV3-1047)
  2020/07/28  NB      Added Location_PrintLabels form details(CIMSV3-1029)
  2019/05/02  RIA     Added SortSeq for all the actions
                      Location_ModifyPickZone: Made changes to bind data for pickzone (CIMSV3-214)
  2019/03/23  MJ      Made changes to the ModifyPutawayZone & ModifyPickZone (CIMSV3-214)
  2018/02/12  MJ      Initial revision(CIMSV3-214)
------------------------------------------------------------------------------*/

Go

declare @FormName  TName;
/* Create Temp table */
--if (object_id('tempdb..#UIFormDetails') is null) create table #FD (FDRecordId int Identity(1,1) not null);
--exec pr_CreateObjectTable 'UIFormDetails', '#FD';

/*------------------------------------------------------------------------------*/
/* Modify Location Operations Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'Location_AllowedOperations';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
             (FieldName,           ControlName,                  FieldCaption,  IsRequired,  DefaultValue,  SortSeq,  DataTagType,  DataTagName,        FormName,  BusinessUnit)
      select 'AllowedOperations',  'LocAllowedOperations_CBDD',  null,          1,           null,          1,        'Data',       null,               @FormName, BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* Modify Location Attributes Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'Location_ChangeAttributes';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
             (FieldName,           ControlName,             FieldCaption,  IsRequired,  DefaultValue,  SortSeq,  DataTagType,  DataTagName,        FormName,  BusinessUnit)
      select 'AllowMultipleSKUs',  'YesNo_DD',              null,          1,           null,          1,        'Data',       null,               @FormName, BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* Modify Location Profile Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'Location_ChangeProfile';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
             (FieldName,           ControlName,             FieldCaption,  IsRequired,  DefaultValue,  SortSeq,  DataTagType,  DataTagName,        FormName,  BusinessUnit)
      select 'LocationClass',      'LocationClass_DD',     'Location Class',
                                                                           1,           null,          1,        'Data',       null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'MaxPallets',         'InputNumber',           null,          0,           null,          2,        'Data',       null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'MaxLPNs',            'IntegerMin0',           null,          0,           null,          3,        'Data',       null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'MaxInnerPacks',      'IntegerMin0',           null,          0,           null,          4,        'Data',       null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'MaxUnits',           'IntegerMin0',           null,          0,           null,          5,        'Data',       null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'MaxVolume',          'IntegerMin0',           null,          0,           null,          6,        'Data',       null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'MaxWeight',          'IntegerMin0',           null,          0,           null,          7,        'Data',       null,               @FormName, BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* Modify Location Type Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'Location_ChangeType';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
             (FieldName,           ControlName,             FieldCaption,  IsRequired,  DefaultValue,  SortSeq,  DataTagType,  DataTagName,        FormName,  BusinessUnit)
      select 'LocationType',       'LocationType_DD',       null,          1,           null,          1,        'Data',       'NewLocationType',  @FormName, BusinessUnit from vwBusinessUnits
union select 'StorageType',        'StorageType_DD',        null,          1,           null,          2,        'Data',       'NewStorageType',   @FormName, BusinessUnit from vwBusinessUnits
union select 'LocationSubType',    'LocationSubType_DD',    null,          0,           null,          3,        'Data',       null,               @FormName, BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* Create New Location Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'Location_CreateLocation';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
             (FieldName,           ControlName,             FieldCaption,  IsRequired,  DefaultValue,  SortSeq,  DataTagType,  DataTagName,        FormName,  BusinessUnit)
      select 'Location',           'InputText',             null,          1,           null,          1,        'Data',       null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'LocationType',       'LocationType_DD',       null,          1,           '_1',          2,        'Data',       null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'LocationSubType',    'LocationSubType_DD',    null,          1,           '_1',          3,        'Data',       null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'StorageType',        'StorageType_DD',        null,          1,           '_1',          4,        'Data',       null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'Warehouse',          'Warehouse_DD',          null,          1,           '_1',          5,        'Data',       null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'AllowMultipleSKUs',  'YesNo_DD',              null,          1,           null,          6,        'Data',       null,               @FormName, BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* Modify Pick Zone Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'Location_ModifyPickZone';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
             (FieldName,           ControlName,             FieldCaption,  IsRequired,  DefaultValue,  SortSeq,  DataTagType,  DataTagName,        FormName,  BusinessUnit)
      select 'PickingZone',        'PickZone_DD',           'Pick Zone',   1,           null,          1,        'Data',       'PickZone',         @FormName, BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* Modify Putaway Zone Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'Location_ModifyPutawayZone';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
             (FieldName,           ControlName,             FieldCaption,  IsRequired,  DefaultValue,  SortSeq,  DataTagType,  DataTagName,        FormName,  BusinessUnit)
      select 'PutawayZone',        'PutawayZone_DD',        null,          1,           null,          1,        'Data',       null,               @FormName, BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* Location_PrintLabels Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'Location_PrintLabels'; -- NOTE: CHANGING THIS WILL IMPACT THE ACTION

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
            (FieldName,               ControlName,               FieldCaption,            IsRequired, DefaultValue,       SortSeq, DataTagType, DataTagName, HandlerTagName,        FormName,  BusinessUnit)
      select 'EntityKeyName',         'HiddenInput',             null,                    1,          'Location',         1,       'Data',      null,        null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'LabelFormatName',       'EntityLabelFormat_DBDD',  'Label Format',          1,          null,               2,       'Data',      null,        null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'LabelPrinterName',      'GenericLabelPrinter_DBDD','Label Printer',         1,          '~SessionKey_DeviceLabelPrinter~',
                                                                                                                          3,       'Data',      null,        'PrinterName',         @FormName, BusinessUnit from vwBusinessUnits
union select 'NumCopies',             'IntegerMin1',             null,                    1,          '1',                4,       'Data',      null,        'NumCopies',           @FormName, BusinessUnit from vwBusinessUnits

Go
