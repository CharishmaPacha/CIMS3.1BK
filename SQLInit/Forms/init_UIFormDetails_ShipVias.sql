/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/23  SJ      Added SCAC for ShipVias_LTLCarrierAdd & ShipVias_LTLCarrierEdit (HA-2693)
  2020/11/23  KBB     Initial revision (HA-1670)
------------------------------------------------------------------------------*/

Go

declare @FormName  TName;

/*------------------------------------------------------------------------------*/
/* ShipVias_LTLCarrierAdd Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'ShipVias_LTLCarrierAdd';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
              (FieldName,              ControlName,       FieldCaption,               IsRequired,  DefaultValue,  SortSeq, DataTagType,  DataTagName,   FormName,   BusinessUnit)
      select  'ShipVia',               'Text',            null,                       1,           null,          1,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'Carrier',               'Text',            null,                       1,           'LTL',         2,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'Description',           'Text',            null,                       1,           null,          3,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'ServiceClass',          'Text',            null,                       0,           'GND',         4,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'ServiceClassDesc',      'Text',            null,                       0,           'Ground',      5,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'SCAC',                  'Text',            null,                       1,           null,          6,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'CarrierServiceCode',    'HiddenInput',     null,                       0,           'M',           7,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'IsSmallPackageCarrier', 'HiddenInput',     null,                       0,           'N',           8,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'Status',                'Status_DD',       null,                       1,           'A',           9,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* ShipVias_LTLCarrierEdit Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'ShipVias_LTLCarrierEdit';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
              (FieldName,              ControlName,       FieldCaption,               IsRequired,  DefaultValue,  SortSeq, DataTagType,  DataTagName,   FormName,   BusinessUnit)
      select  'RecordId',              'HiddenInput',     null,                       0,           null,          0,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'ShipVia',               'Text',            null,                       1,           null,          1,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'Carrier',               'Text',            null,                       1,           null,          2,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'Description',           'Text',            null,                       1,           null,          3,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'ServiceClass',          'Text',            null,                       0,           null,          4,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'ServiceClassDesc',      'Text',            null,                       0,           null,          5,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'SCAC',                  'Text',            null,                       1,           null,          6,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'CarrierServiceCode',    'HiddenInput',     null,                       0,           null,          7,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'IsSmallPackageCarrier', 'HiddenInput',     null,                       1,           null,          8,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'Status',                'Status_DD',       null,                       1,           null,          9,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits

Go
