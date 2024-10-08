/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/05/26  RV      Inventory_CreateInventory: Corrected field name LPNLabelFormatName to LabelFormatName (BK-1057)
  2021/12/10  RV      Inventory_CreateInventory: Renamed from LPNLabelFormatName to LabelFormatName (FB Golive)
  2021/11/29  RV      Receiving_CreateReceiptInventory: Default value set for Palletization (FBV3-522)
  2021/11/22  RV      Receiving_CreateReceiptInventory: Added InventoryClass1 and Reference (FBV3-468)
  2021/11/11  SV      Receiving_CreateReceiptInventory: Made ReceiverNumber selection optional (FBV3-440)
  2021/10/05  RV      Receiving_CreateReceiptInventory: Initial revision(FBV3-265)
------------------------------------------------------------------------------*/

Go

declare @FormName  TName;

/*------------------------------------------------------------------------------*/
/* Create LPNs to Receive Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'Receiving_CreateReceiptInventory'; /* Imp Note: This form name shouldn't be changed as it is being used in js handler tags */

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
            (FieldName,               ControlName,               FieldCaption,            UIControl,         IsRequired, Visible, DefaultValue, SortSeq,  DataTagType, DataTagName,  HandlerTagName,        FormName,  BusinessUnit)
      select 'ReceiverNumber',       'OpenReceivers_DD',         null,                    null,              0,          1,       null,          1,       'Data',      'ReceiverId', 'Receiver',            @FormName, BusinessUnit from vwBusinessUnits
union select 'ReceiptNumber',        'OpenReceipts_DD',          null,                    null,              1,          1,       null,          2,       'Data',      'ReceiptId',  'Receipt',             @FormName, BusinessUnit from vwBusinessUnits

union select 'CoO',                  'ReadonlyText',             null,                    null,              0,          1,       null,         10,       'Data',      null,         null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'Ownership',            'ReadonlyText',             null,                    null,              0,          1,       null,         11,       'Data',      'Owner',      null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'Warehouse',            'ReadonlyText',             null,                    null,              0,          1,       null,         12,       'Data',      null,         null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'VendorName',           'ReadonlyText',             null,                    null,              0,          1,       null,         13,       'Data',      null,         null,                  @FormName, BusinessUnit from vwBusinessUnits

union select 'SKU',                  'CreateReceiptInvSKU_DD',   null,                    null,              0,          1,       null,         20,       'Data',      'SKUId',      'SKUSelection',        @FormName, BusinessUnit from vwBusinessUnits
union select 'SKUDescription',       'ReadonlyText',             null,                    null,              0,          1,       null,         21,       'Display',   null,         null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'SKU1',                 'ReadonlyText',             null,                    null,              0,          1,       null,         22,       'Display',   null,         null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'SKU1Description',      'ReadonlyText',             null,                    null,              0,          1,       null,         23,       'Display',   null,         null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'SKU2',                 'ReadonlyText',             null,                    null,              0,          1,       null,         24,       'Display',   null,         null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'SKU2Description',      'ReadonlyText',             null,                    null,              0,          1,       null,         25,       'Display',   null,         null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'SKU3',                 'ReadonlyText',             null,                    null,              0,          0,       null,         26,       'Display',   null,         null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'SKU3Description',      'ReadonlyText',             null,                    null,              0,          0,       null,         27,       'Display',   null,         null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'SKU4',                 'ReadonlyText',             null,                    null,              0,          0,       null,         28,       'Display',   null,         null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'SKU4Description',      'ReadonlyText',             null,                    null,              0,          0,       null,         29,       'Display',   null,         null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'SKU5',                 'ReadonlyText',             null,                    null,              0,          0,       null,         30,       'Display',   null,         null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'SKU5Description',      'ReadonlyText',             null,                    null,              0,          0,       null,         31,       'Display',   null,         null,                  @FormName, BusinessUnit from vwBusinessUnits

union select 'SKUDetail',             null,                      null,                    'InputSKUDetail',  1,          1,       null,         40,       'Data',      null,         'SKUDetail',           @FormName, BusinessUnit from vwBusinessUnits

union select 'InventoryClass1',      'InventoryClass1_DD',       null,                    null,              0,          1,       null,         50,       'Data',      null,        null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'Reference',            'InputText',                null,                    null,              0,          1,       null,         51,       'Data',      null,        null,                  @FormName, BusinessUnit from vwBusinessUnits

union select 'NumLPNsToCreate',      'IntegerMin1',              '# LPNs to create',      null,              0,          1,        '1',         60,       'Data',      null,         null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'QtyToLabel',           'ReadOnlyText',             null,                    null,              0,          1,        '0',         61,        null,       null,         null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'QtyLabelling',         'ReadOnlyText',             '# Labelling',           null,              0,          1,        '0',         62,        null,       null,         null,                  @FormName, BusinessUnit from vwBusinessUnits

union select 'GeneratePallet',       'GeneratePalletOptions_DD', 'Palletization',         null,              1,          1,       '_1',         70,       'Data',      null,         'GeneratePalletOption',@FormName, BusinessUnit from vwBusinessUnits
union select 'Pallet',               'InputText',                null,                    null,              1,          1,       null,         71,       'Data',      null,         null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'NumLPNsPerPallet',     'IntegerMin1',              'LPNs per Pallet',       null,              0,          1,        '1',         72,       'Data',      null,         null,                  @FormName, BusinessUnit from vwBusinessUnits

union select 'LabelFormatName',      'LPNLabelFormat_DD',        'LPN Label Format',      null,              0,          1,       null,         80,       'Data',      null,         null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'PrinterName',          'LPNLabelPrinter_DBDD',     'Printer',               null,              0,          1,       '~SessionKey_DeviceLabelPrinter~',
                                                                                                                                                81,       'Data',      null,         null,                  @FormName, BusinessUnit from vwBusinessUnits
select @FormName = @FormName + '_SKUDetail';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
            (FieldName,               ControlName,               FieldCaption,            IsRequired, Visible, DefaultValue, SortSeq, DataTagType,  DataTagName, HandlerTagName,        FormName,  BusinessUnit)
      select 'UoM',                  'UoM_DD',                   null,                    0,          1,        null,        1,       null,         null,        'CreationUoM',         @FormName, BusinessUnit from vwBusinessUnits
union select 'UnitsPerInnerPack',    'IntegerMin0',              'Units per Case',        0,          1,        '0',         2,       null,         null,        'UnitsPerInnerPack',   @FormName, BusinessUnit from vwBusinessUnits
union select 'InnerPacksPerLPN',     'IntegerMin0',              'Cases per LPN',         0,          1,        '0',         3,       null,         null,        'InnerPacksPerLPN',    @FormName, BusinessUnit from vwBusinessUnits
union select 'UnitsPerLPN',          'IntegerMin0',              'Units per LPN',         0,          1,        '0',         4,       null,         null,        'UnitsPerLPN',         @FormName, BusinessUnit from vwBusinessUnits
union select 'NumSKUs',              'ReadonlyText',             null,                    0,          1,        '0',         5,       null,         null,        'NumSKUs',             @FormName, BusinessUnit from vwBusinessUnits
union select 'QuantityPerLPN',       'ReadonlyText',             'Qty per LPN',           0,          1,        '0',         6,       null,         null,        'TotalQuantityPerLPN', @FormName, BusinessUnit from vwBusinessUnits
union select 'CurrentSelectedSKU',   'HiddenInput',              null,                    0,          1,        null,        7,       null,         null,        'CurrentSelectedSKU',  @FormName, BusinessUnit from vwBusinessUnits

Go
