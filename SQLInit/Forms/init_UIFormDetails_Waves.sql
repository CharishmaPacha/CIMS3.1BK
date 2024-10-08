/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/07  AY      Changed to use generic control for priority (HA-2018)
  2021/02/10  OK      GenerateWavesCustomSetings: Changes to display empty by default for Per Wave counts (HA-1930)
  2021/01/22  OK      Added form details for GenerateWavesCustomSetings (HA-1910)
  2020/10/08  MRK     Waves_PrintLabels: Added NumCopies (CIMSV3-1115)
  2020/07/29  NB      Wave_ReleaseForAllocation..added form details fow WaveType and Warehouse. these
                        are used in processing form detail attributes (HA-1242)
  2020/07/28  NB      Added Waves_PrintLabels form details (CIMSV3-1029)
  2020/06/10  KBB     Wave_ReleaseForAllocation: Included Priority(HA-792)
  2020/05/27  AJ      Wave_ReleaseForAllocation: Changes to display currentdate for ShipDate field (CIMSV3-937)
  2020/05/06  RT      DropLocation: Changed ControlName to WaveDropLocation_DD (HA-437)
  2020/05/05  RT      Wave_ReleaseForAllocation: Included InvAllocationModel (HA-312)
  2019/05/08  RIA     Rename ModifyWave as Wave_Modify
                      Changed FieldCaptions, DataTagName for Wave_Modify, Wave_ReleaseForAllocation
  2019/04/24  VS      Corrections to ModifyWave Action (cIMSV3-443)
  2019/04/23  NB      corrections to Wave_ReleaseForAllocation definition(CIMSV3-416)
  2018/01/17  RA      Added Release for allocation for PickBatches Page(CIMSV3-218)
  2018/01/17  RA      Initial revision(CIMSV3-217)
------------------------------------------------------------------------------*/

Go

declare @FormName  TName;

/*------------------------------------------------------------------------------*/
/* ModifyWave Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'Waves_Modify';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
            (FieldName,               ControlName,             FieldCaption,            IsRequired, DefaultValue, SortSeq, DataTagType, DataTagName,        FormName,  BusinessUnit)
      select 'WaveNo',                'ReadOnlyText',          null,                    0,          null,         1,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'Priority',              'Integer1-100',          null,                    1,          null,         2,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'DropLocation',          'WaveDropLocation_DD',   null,                    0,          null,         3,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'ShipDate',              'DateFuture',            null,                    0,          'Today',      4,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'CancelDate',            'DateFuture',            null,                    0,          'Today',      5,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* ReleaseForAllocation Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'Wave_ReleaseForAllocation';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
            (FieldName,               ControlName,                FieldCaption,            IsRequired, DefaultValue, SortSeq, DataTagType, DataTagName,        FormName,  BusinessUnit)
      select 'DropLocation',          'WaveDropLocation_DD',      null,                    0,          null,         1,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'ShipDate',              'DateFuture',               null,                    0,          'Today',      2,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'Priority',              'Integer1-100',             null,                    0,          null,         3,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'InvAllocationModel',    'InvAllocationModel_DD',    null,                    0,          '_1',         4,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
/* Below fields are added purely for Data Placeholders of DropLocation such that relevant Drop Locations are displayed in action form */
union select 'Warehouse',             'HiddenInput',              null,                    1,          null,         8,       null,        null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'WaveType',              'HiddenInput',              null,                    1,          null,         9,       null,        null,               @FormName, BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* Waves_PrintLabels Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'Waves_PrintLabels'; -- NOTE: CHANGING THIS WILL IMPACT THE ACTION

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
            (FieldName,               ControlName,               FieldCaption,            IsRequired, DefaultValue,       SortSeq, DataTagType, DataTagName,        FormName,  BusinessUnit)
      select 'EntityKeyName',         'HiddenInput',             null,                    1,          'WaveNo',           1,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'LabelFormatName',       'EntityLabelFormat_DBDD',  'Label Format',          1,          null,               2,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'LabelPrinterName',      'GenericLabelPrinter_DBDD','Label Printer',         1,          '~SessionKey_DeviceLabelPrinter~',
                                                                                                                          3,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'NumCopies',             'IntegerMin1',             null,                    1,          '1',                4,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* GenerateWavesCustomSetings Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'GenerateWavesCustomSetings ';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
            (FieldName,               ControlName,               FieldCaption,            IsRequired, DefaultValue,       SortSeq, DataTagType, DataTagName,     HandlerTagName,        FormName,  BusinessUnit)
      select 'WaveType',              'WaveTypeToCreate_DD',     'Wave Type',             1,          null,               1,       'Data',      null,            null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'WavePriority',          'Integer1-100',            'Priority',              1,          '5',                2,       'Data',      null,            null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'WaveStatus',            'WaveStatusToCreate_DD',   'Status',                1,          'N',                3,       'Data',      'NewWaveStatus', null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'AddToExistingWave',     'YesNo_DD',                'Add to existing wave',  1,          'N',                4,       'Data',      null,            null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'OrdersPerWave',         'IntegerMin1',             'Orders Per Wave',       0,          '',                 5,       'Data',      'OrdersPerWave', null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'SKUsPerWave',           'IntegerMin1',             'SKUs Per Wave',         0,          '',                 6,       'Data',      'SKUsPerWave',   null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'LinesPerWave',          'IntegerMin1',             'Lines Per Wave',        0,          '',                 7,       'Data',      'LinesPerWave',  null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'UnitsPerWave',          'IntegerMin1',             'Units Per Wave',        0,          '',                 8,       'Data',      'UnitsPerWave',  null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'TotalOrders',           'ReadOnlyText',            'Total Orders',          1,          '1',                9,       'Data',      'TotalOrders',   null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'TotalSKUs',             'ReadOnlyText',            'Total SKUs',            1,          '1',               10,       'Data',      'TotalSKUs',     null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'TotalLines',            'ReadOnlyText',            'Total Lines',           1,          '1',               11,       'Data',      'TotalLines',    null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'TotalUnits',            'ReadOnlyText',            'Total Units',           1,          '1',               12,       'Data',      'TotalUnits',    null,                  @FormName, BusinessUnit from vwBusinessUnits

Go
