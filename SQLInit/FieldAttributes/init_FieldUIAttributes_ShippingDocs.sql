/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/03  NB      Added Warehouse Filter to Label and Document Printer Dropdowns(HA-2114)
  2021/02/08  RV      Made changes to show only active printers (BK-167)
  2020/05/29  RV      Made changes to load pritner with respect to the label/document printer (HA-687)
  2020/05/28  RV      Made changes to send printer unified name instead of printer port to print (HA-674)
  2020/05/03  NB      Initial Revision(CIMSV3-221)
------------------------------------------------------------------------------*/

Go

declare @ContextName                TName,                                         /* Name of DB View, DB Table, Layout Context */
        @ttFieldUIAttributes        TFieldUIAttributes,
        @FieldName                  TName,                                         /* Name of Field in the DB View, DB Table, Layout Context */
        @Category                   TTypeCode,
        @ReferenceContext           TName,
        @ReferenceCategory          TName,
        @ReferenceCategoryField     TName,
        @ReferenceValueField        TName,
        @ReferenceDescriptionField  TName,
        @AllowMultiSelect           TFlag,
        @UIControl                  TName;

select @ContextName      = 'Shipping_ShippingDocs',
       @Category         = 'F', /* Form */
       @UIControl        = 'DBLookupDropDown';

delete from @ttFieldUIAttributes;

insert into @ttFieldUIAttributes
             (FieldName,             ControlName,            UIControl,      DbSource,          DbsourceFilter,                                DbLookUpFieldName,  ReferenceValueField,  ReferenceDescriptionField,  DbLookUpFieldList)
      select 'LabelPrinterName',     null,                   @UIControl,     'vwPrinters',      '((Warehouse is null) or ~INPUTFILTER_Warehouse~) and Status = ''A'' and PrinterType = ''Label''',  'DeviceName',       'PrinterNameUnified', 'DeviceName',               'PrinterNameUnified,DeviceName'
union select 'DocumentPrinterName',  null,                   @UIControl,     'vwPrinters',      '((Warehouse is null) or ~INPUTFILTER_Warehouse~) and Status = ''A'' and PrinterType = ''Report''', 'DeviceName',       'PrinterNameUnified', 'DeviceName',               'PrinterNameUnified,DeviceName'

exec pr_Setup_FieldUIAttributes @ContextName, @Category, @ttFieldUIAttributes, 'DI' /* Action - Insert */;

Go
