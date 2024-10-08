/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/04  RBV     Chaged the ControlName (HA-1654)
  2020/08/26  RBV     Initial revision (HA-1110)
------------------------------------------------------------------------------*/

Go

declare @FormName  TName;

/*------------------------------------------------------------------------------*/
/* ModifyFields Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'CartonType_Add';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
              (FieldName,              ControlName,       FieldCaption,               IsRequired,  DefaultValue,  SortSeq, DataTagType,  DataTagName,   FormName,   BusinessUnit)
      select  'CartonType',            'Text',            null,                       1,           null,          1,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'Description',           'Text',            null,                       1,           null,          2,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'EmptyWeight',           'Decimal1',        null,                       1,           null,          3,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'InnerLength',           'Decimal1',        null,                       1,           null,          4,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'InnerWidth',            'Decimal1',        null,                       1,           null,          5,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'InnerHeight',           'Decimal1',        null,                       1,           null,          6,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'AvailableSpace',        'IntegerMin1',     null,                       1,           null,          11,      'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'MaxWeight',             'IntegerMin0',     null,                       0,           null,          12,      'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'MaxUnits',              'IntegerMin0',     null,                       0,           null,          13,      'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
--union select  'CarrierPackagingType',  'Text',            null,                       0,           null,          14,      'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'SortSeq',               'IntegerMin0',     null,                       1,           null,          20,      'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'Status',                'Status_DD',       null,                       1,           null,          21,      'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* ModifyFields Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'CartonType_Edit';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
              (FieldName,              ControlName,       FieldCaption,               IsRequired,  DefaultValue,  SortSeq, DataTagType,  DataTagName,   FormName,   BusinessUnit)
      select  'CartonType',            'ReadOnlyText',    null,                       1,           null,          1,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'Description',           'Text',            null,                       1,           null,          2,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'EmptyWeight',           'Decimal1',        null,                       1,           null,          3,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'InnerLength',           'Decimal1',        null,                       1,           null,          4,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'InnerWidth',            'Decimal1',        null,                       1,           null,          5,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'InnerHeight',           'Decimal1',        null,                       1,           null,          6,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'AvailableSpace',        'IntegerMin1',     null,                       1,           null,          11,      'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'MaxWeight',             'IntegerMin0',     null,                       0,           null,          12,      'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'MaxUnits',              'IntegerMin0',     null,                       0,           null,          13,      'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
--union select  'CarrierPackagingType',  'Text',            null,                       0,           null,          14,      'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'SortSeq',               'IntegerMin0',     null,                       1,           null,          20,      'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'Status',                'Status_DD',       null,                       1,           null,          21,      'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits

Go
