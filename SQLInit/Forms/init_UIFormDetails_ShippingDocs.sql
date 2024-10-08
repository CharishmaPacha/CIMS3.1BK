/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/07/14  NB      Defined default values with sessionkey placeholders (CIMSV3-935)
  2020/05/03  NB      Initial revision (CIMSV3-221)
------------------------------------------------------------------------------*/

Go

declare @FormName  TName;

/*------------------------------------------------------------------------------*/
/* ShippingDocs Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'Shipping_ShippingDocs';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
             (FieldName,               UIControl,             FieldCaption,            IsRequired, DefaultValue,                                 SortSeq, DataTagType, DataTagName, FieldHint,                  FormName,  BusinessUnit)
      select 'LabelPrinterName',       'DBLookupDropDown',    'Label Printer',         1,          '~SessionKey_DeviceLabelPrinterUnified~',     1,       'Data',      null,        'select label printer',     @FormName, BusinessUnit from vwBusinessUnits
union select 'DocumentPrinterName',    'DBLookupDropDown',    'Document Printer',      1,          '~SessionKey_DeviceDocumentPrinterUnified~',  2,       'Data',      null,        'select document printer',  @FormName, BusinessUnit from vwBusinessUnits

Go
