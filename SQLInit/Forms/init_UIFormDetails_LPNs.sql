/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/24  MS      Added LPN_RegenerateTrackingNo (HA-2410)
  2020/11/11  KBB     Added LPNs_PrintPalletandLPNLabels (HA-1645)
  2020/10/08  MRK     LPNs_PrintLabels: Added NumCopies (CIMSV3-1115)
  2020/09/16  RV      Inventory_CreateInventory: Removed as required controls for LabelFormatName and PrinterName.
                       Print when user selects both label format and printer (HA-1434)
  2020/08/12  OK      Added form details for create inventory (HA-1272)
  2020/08/11  NB      LPNs_PrintLabels: defined HandlerTagName for LabelPrinter for Local Printer Support(CIMSV3-1047)
  2020/07/28  NB      LPN_ChangeLPNSKU, LPN_GenerateLPNs, LPNs_Palletize
                        changes to display Warehouse specific Printers and default Printer to Device Label Printer(HA-1229)
  2020/07/27  NB      LPNs_PrintLabels: added FormDetails for Label Format and Printer(CIMSV3-1029)
  2020/07/21  TK      LPNs_Palletize & LPNs_Move: Added ReasonCode & Reference field (HA-1186)
  2020/07/11  TK      LPN_Palletize: Added Form Details (HA-1031)
  2020/07/09  TK      LPN_Move: Added Form Details (HA-1115)
  2020/06/08  SPP     Added LPN_ChangeLPNSKU (HA-419)
  2020/05/18  RKC     Added LabelFormatName, DeviceName For LPN_GenerateLPNs (HA-445)
  2020/05/07  SV      Added ReasonCode dropdown for Update Inv Category Action (HA-420)
                      Added Reference textbox for Update Inv Category Action (HA-421)
  2020/03/31  MS      Added InventoryClass1 in form LPN_Modify action (HA-77)
  2020/03/19  RT      Changed the ControlName and FieldName for LPNType (CIMSV3-697)
  2020/02/12  RIA     LPN_GenerateLPNs: Changes to LPNType (JL-43)
  2020/01/30  AY      Added different controls for LPNType for Modify and Generate (CIMSV3-697)
  2019/05/27  RIA     Changes for Dropowns, data binding and file format (CIMSV3-211)
  2019/05/26  AY      Change to ControlName
  2019/05/23  NB      Changes to LPN_GenerateLPNs to define defaults(CIMSV3-545)
  2019/05/16  NB      Changes to LPN_ChangeOwnership, LPN_ChangeWarehouse, LPN_UpdateInvExpDate, LPN_GenerateLPNs,
                       LPN_Void to use ControlName(CIMSV3-544)
  2019/05/09  NB      LPN_ChangeOwnership: Minor changes (CIMSV3-138)
  2019/05/09  RIA     LPN_ReverseReceipt: Modified UIControl for ReceiverNumber (CIMSV3-531)
  2019/05/08  RIA     Added: LPN_ReverseReceipt
                      Included SortSeq for LPN_Modify, LPN_UpdateExpiryDate
                      LPN_ChangeOwnership, LPN_ChangeWarehouse: Added appropriate DataTagName
  2019/04/23  NB      Corrections to LPN_ModifyCartonType definition(CIMSV3-262)
  2019/04/21  RT      LPN_ModifyCartonType: Included IsRequired and SortSeq (CIMSV3-262)
  2019/04/17  RIA     Added: LPN_UpdateInvExpDate, LPN_GenerateLPNs, LPN_ModifyCartonType
  2018/06/22  NB      Init data for PrintLPNLabels(CIMSV3-152)
  2017/12/20  NB      Initial revision(CIMSV3-167)
------------------------------------------------------------------------------*/

Go

declare @FormName  TName;

/*------------------------------------------------------------------------------*/
/* LPN_ChangeLPNSKU Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'LPN_ChangeLPNSKU';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
            (FieldName,               ControlName,                   FieldCaption,            IsRequired, DefaultValue, SortSeq, DataTagType, DataTagName,        FormName,  BusinessUnit)
      select 'SKU',                   'SKU_DD',                      'Enter SKU',             0,          null,          1,      'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'ReasonCode',            'RC_UpdateInvCategories_DD',   null,                    1,          null,          2,      'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'Reference',             null,                          'Reference Number',      0,          null,          3,      'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'LabelFormatName',       'LPNLabelFormat_DD',           'Label Format',          0,          null,          4,      'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'LabelPrinterName',      'LPNLabelPrinter_DBDD',        'Label Printer',         0,          '~SessionKey_DeviceLabelPrinter~',
                                                                                                                         5,      'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
/*------------------------------------------------------------------------------*/
/* ChangeOwnership Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'LPN_ChangeOwnership';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
            (FieldName,               ControlName,             FieldCaption,            IsRequired, DefaultValue, SortSeq, DataTagType, DataTagName,        FormName,  BusinessUnit)
      select 'Ownership',             'Ownership_DD',          null,                    1,          null,         1,       'Data',      'LPNOwner',         @FormName, BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* ChangeWarehouse Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'LPN_ChangeWarehouse';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
            (FieldName,               ControlName,             FieldCaption,            IsRequired, DefaultValue, SortSeq, DataTagType, DataTagName,        FormName,  BusinessUnit)
      select 'DestWarehouse',         'Warehouse_DD',          'Warehouse',             1,          null,         1,       'Data',      'NewWarehouse',     @FormName, BusinessUnit from vwBusinessUnits
union select 'Reference',             null,                    null,                    0,          null,         2,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* ChangeWarehouse Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'LPN_GenerateLPNs';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
            (FieldName,               ControlName,             FieldCaption,            IsRequired, DefaultValue, SortSeq, DataTagType, DataTagName,        FormName,  BusinessUnit)
      select 'LPNType',               'LPNTypeGenerate_DD',    null,                    1,          '_1',         1,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'NumLPNs',               'IntegerMin1',           'Num LPNs to Create',    1,          '1',          2,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'LPNFormat',             'LPNFormat_DD',          'select LPN Format',     1,          '_1',         3,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'Warehouse',             'Warehouse_DD',          null,                    1,          '_1',         4,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'LabelFormatName',       'LPNLabelFormat_DD',     'Label Format',          0,          null,         5,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'LabelPrinterName',      'LPNLabelPrinter_DBDD',  'Label Printer',         0,          '~SessionKey_DeviceLabelPrinter~',
                                                                                                                  6,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
/*------------------------------------------------------------------------------*/
/* Modify Carton type/ weight Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'LPN_ModifyCartonType';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
            (FieldName,               ControlName,             FieldCaption,            IsRequired, DefaultValue, SortSeq, DataTagType, DataTagName,        FormName,  BusinessUnit)
      select 'CartonType',            'CartonType_DD',         null,                    1,          null,         1,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'ActualWeight',          'Decimal3',              null,                    1,          null,         2,       'Data',      'Weight',           @FormName, BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* ModifyLPNType Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'LPN_ModifyType';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
            (FieldName,               ControlName,             FieldCaption,            IsRequired, DefaultValue, SortSeq, DataTagType, DataTagName,        FormName,  BusinessUnit)
      select 'LPNType',               'LPNTypeModify_DD',      'Change to LPN Type',    1,          null,         1,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* LPNModify LPNs Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'LPN_Modify';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
            (FieldName,               ControlName,                   FieldCaption,            IsRequired, DefaultValue, SortSeq, DataTagType, DataTagName,        FormName,  BusinessUnit)
      select 'Lot',                   null,                          null,                    0,          null,          1,      'Data',      'LotNumber',        @FormName, BusinessUnit from vwBusinessUnits
union select 'ExpiryDate',            'DateFuture',                  null,                    0,          null,          2,      'Data',      'InvExpDate',       @FormName, BusinessUnit from vwBusinessUnits
union select 'InventoryClass1',       'InventoryClass1_DD',          null,                    0,          null,          3,      'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'ReasonCode',            'RC_UpdateInvCategories_DD',   null,                    1,          '_1',          4,      'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'Reference',             null,                          'Reference Number',      0,          null,          5,      'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* Form Details for Bulk Move LPNs action */
/*------------------------------------------------------------------------------*/
select @FormName = 'LPNs_BulkMove';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
            (FieldName,               ControlName,              FieldCaption,               IsRequired, DefaultValue, SortSeq, DataTagType, DataTagName,        FormName,  BusinessUnit)
      select 'Location',              'Locations_RBKS_DD',      'select Location',          0,          null,         1,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'ReasonCode',            'RC_TransferInv_DD',       null,                      0,          null,         2,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'Reference',             null,                     'Reference #',              0,          null,         3,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* Form Details for PalletizeLPNs action */
/*------------------------------------------------------------------------------*/
select @FormName = 'LPNs_Palletize';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
            (FieldName,               ControlName,              FieldCaption,               IsRequired, DefaultValue, SortSeq, DataTagType, DataTagName,        FormName,  BusinessUnit)
      select 'LPNsPerPallet',         'IntegerMin1',            '# LPNs per Pallet',        0,          '',           1,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'GroupingCriteria',      'PalletizationGroups_DD', 'select Grouping Criteria', 0,          '0',          2,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'MaxPalletsPerGroup',    'IntegerMin1',            'Max Pallets per Group',    0,          '',           3,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'RePalletize',           'YesNo_DD',               'Re-Palletize LPNs?',       0,          'N',          4,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'ReasonCode',            'RC_TransferInv_DD',       null,                      0,          null,         5,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'Reference',             null,                     'Reference #',              0,          null,         6,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'LabelFormatName',       'PalletLabelFormat_DD',   'Label Format',             0,          null,         7,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'LabelPrinterName',      'LPNLabelPrinter_DBDD',   'Label Printer',            0,          '~SessionKey_DeviceLabelPrinter~',
                                                                                                                      8,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* LPNs_PrintLabels Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'LPNs_PrintLabels'; -- NOTE: CHANGING THIS WILL IMPACT THE ACTION

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
            (FieldName,               ControlName,               FieldCaption,            IsRequired, DefaultValue,       SortSeq, DataTagType, DataTagName, HandlerTagName, FormName,  BusinessUnit)
      select 'EntityKeyName',         'HiddenInput',             null,                    1,          'LPN',              1,       'Data',      null,        null,           @FormName, BusinessUnit from vwBusinessUnits
union select 'LabelFormatName',       'EntityLabelFormat_DBDD',  'Label Format',          1,          null,               2,       'Data',      null,        null,           @FormName, BusinessUnit from vwBusinessUnits
union select 'LabelPrinterName',      'LPNLabelPrinter_DBDD',    'Label Printer',         1,          '~SessionKey_DeviceLabelPrinter~',
                                                                                                                          3,       'Data',      null,       'PrinterName',   @FormName, BusinessUnit from vwBusinessUnits
union select 'NumCopies',             'IntegerMin1',             null,                    1,          '1',                4,       'Data',      null,       'NumCopies',     @FormName, BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* Reverse receipt Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'LPN_ReverseReceipt';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
            (FieldName,               ControlName,             FieldCaption,            IsRequired, DefaultValue, SortSeq, DataTagType, DataTagName,        FormName,  BusinessUnit)
      select 'ReasonCode',           'RC_RevReceipt_DD',       null,                    1,          null,         1,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'ReceiverNumber',        null,                    'Reference Number',      1,          null,         2,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* RegenerateTrackingNo Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'LPN_RegenerateTrackingNo';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
            (FieldName,                   ControlName,               FieldCaption,            IsRequired, DefaultValue, SortSeq, DataTagType, DataTagName,        FormName,  BusinessUnit)
      select 'RegenTrackingNoCriteria',  'RegenerateTrackingNo_DD',  'Options',               1,          '_1',         1,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* UpdateExpiryDate Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'LPN_UpdateInvExpDate';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
            (FieldName,               ControlName,             FieldCaption,            IsRequired, DefaultValue, SortSeq, DataTagType, DataTagName,        FormName,  BusinessUnit)
      select 'ExpiryDate',            'DateFuture',            null,                    1,          null,         1,       'Data',      'InvExpDate',       @FormName, BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* VoidLPNs Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'LPN_Void';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
            (FieldName,               ControlName,             FieldCaption,            IsRequired, DefaultValue, SortSeq, DataTagType, DataTagName,        FormName,  BusinessUnit)
      select 'ReasonCode',            'RC_LPNVoid_DD',         null,                    1,          null,         1,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'Reference',             null,                    null,                    0,          null,         2,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* Create Inventory Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'Inventory_CreateInventory'; /* Imp Note: This form name shouldn't be changed as it is being used in js handler tags */

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
            (FieldName,               ControlName,               FieldCaption,            IsRequired, Visible, DefaultValue, SortSeq, DataTagType, DataTagName, HandlerTagName,        FormName,  BusinessUnit)
      select 'SKU',                  'CreateInvSKU_DD',          null,                    1,          1,       null,          1,       'Data',      'SKUId',    'SKUSelection',         @FormName, BusinessUnit from vwBusinessUnits
union select 'SKUDescription',       'ReadonlyText',             null,                    0,          1,       null,          2,       'Display',   null,        null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'SKU1',                 'ReadonlyText',             null,                    0,          1,       null,          3,       'Display',   null,        null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'SKU1Description',      'ReadonlyText',             null,                    0,          1,       null,          4,       'Display',   null,        null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'SKU2',                 'ReadonlyText',             null,                    0,          1,       null,          5,       'Display',   null,        null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'SKU2Description',      'ReadonlyText',             null,                    0,          1,       null,          6,       'Display',   null,        null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'SKU3',                 'ReadonlyText',             null,                    0,          0,       null,          7,       'Display',   null,        null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'SKU3Description',      'ReadonlyText',             null,                    0,          0,       null,          8,       'Display',   null,        null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'SKU4',                 'ReadonlyText',             null,                    0,          0,       null,          9,       'Display',   null,        null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'SKU4Description',      'ReadonlyText',             null,                    0,          0,       null,         10,       'Display',   null,        null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'SKU5',                 'ReadonlyText',             null,                    0,          0,       null,         11,       'Display',   null,        null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'SKU5Description',      'ReadonlyText',             null,                    0,          0,       null,         12,       'Display',   null,        null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'UoM',                  'UoM_DD',                   null,                    1,          1,       null,         13,       'Data',      null,        'CreationUoM',         @FormName, BusinessUnit from vwBusinessUnits
union select 'UnitsPerInnerPack',    'IntegerMin0',              'Units per Case',        1,          1,        '0',         14,       'Data',      null,        'UnitsPerInnerPack',   @FormName, BusinessUnit from vwBusinessUnits
union select 'InnerPacksPerLPN',     'IntegerMin0',              'Cases per LPN',         1,          1,        '0',         15,       'Data',      null,        'InnerPacksPerLPN',    @FormName, BusinessUnit from vwBusinessUnits
union select 'UnitsPerLPN',          'IntegerMin0',              'Qty per LPN',           1,          1,        '0',         16,       'Data',      null,        'UnitsPerLPN',         @FormName, BusinessUnit from vwBusinessUnits
union select 'NumLPNsToCreate',      'IntegerMin1',              '# LPNs to create',      0,          1,        '1',         17,       'Data',      null,        null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'LotNumber',            'InputText',                'Lot',                   0,          0,       null,         18,       'Data',      null,        null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'ReasonCode',           'RC_LPNCreateInv_DD',       null,                    1,          1,       null,         19,       'Data',      null,        null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'InventoryClass1',      'InventoryClass1_DD',       'Label Code',            0,          1,       null,         20,       'Data',      null,        null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'Reference',            'InputText',                null,                    0,          1,       null,         21,       'Data',      null,        null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'Warehouse',            'DestWarehouse_DBDD',       'Warehouse',             0,          1,       null,         22,       'Data',      null,        null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'Owner',                'Ownership_DD',             'Owner',                 1,          1,       null,         23,       'Data',      null,        null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'CoO',                  'CoO_DD',                   null,                    1,          0,       null,         24,       'Data',      null,        null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'ExpiryDate',           'DateFuture',               null,                    0,          0,       null,         25,       'Data',      null,        null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'CreateDate',           'DateFuture',               'Create Date',           0,          1,       null,         26,       'Data',      null,        null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'LPNType',              'LPNTypeCreateInv_DD',      'LPN Type',              1,          1,       null,         27,       'Data',      null,        null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'GeneratePallet',       'GeneratePalletOptions_DD', 'Palletization',         1,          1,       null,         28,       'Data',      null,        'GeneratePalletOption',@FormName, BusinessUnit from vwBusinessUnits
union select 'Pallet',               'InputText',                null,                    1,          1,       null,         29,       'Data',      null,        null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'LabelFormatName',      'LPNLabelFormat_DD',        'Label Format',          0,          1,       null,         30,       'Data',      null,        null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'PrinterName',          'LPNLabelPrinter_DBDD',     'Printer',               0,          1,       '~SessionKey_DeviceLabelPrinter~',
                                                                                                                             31,       'Data',     null,         null,                  @FormName, BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* LPNs_PrintPalletandLPNLabels Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'LPNs_PrintPalletandLPNLabels';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
            (FieldName,               ControlName,               FieldCaption,            IsRequired, DefaultValue,       SortSeq, DataTagType, DataTagName, HandlerTagName,        FormName,  BusinessUnit)
      select 'EntityKeyName',         'HiddenInput',             null,                    1,          'Pallet',           1,       'Data',      null,        null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'PalletLabelFormatName', 'PalletLabelFormat_DD',    'Pallet Label Format',   1,          null,               2,       'Data',      null,        null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'LPNLabelFormatName',    'EntityLabelFormat_DBDD',  'Lpn Label Format',      1,          null,               3,       'Data',      null,        null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'LabelPrinterName',      'GenericLabelPrinter_DBDD','Label Printer',         1,          '~SessionKey_DeviceLabelPrinter~',
                                                                                                                          4,       'Data',      null,        'PrinterName',         @FormName, BusinessUnit from vwBusinessUnits

Go
