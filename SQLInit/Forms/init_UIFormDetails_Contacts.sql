/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/12  AJM     Added new form Contacts_Add (HA-2583)
  2021/03/18  OK      Initial revision (HA-2317)
------------------------------------------------------------------------------*/

Go

declare @FormName  TName;

/*------------------------------------------------------------------------------*/
/* Add Contact */
/*------------------------------------------------------------------------------*/
select @FormName = 'Contacts_Add';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
              (FieldName,              ControlName,             FieldCaption,  IsRequired,  DefaultValue,  SortSeq, DataTagType,  DataTagName,   FormName,   BusinessUnit)
      select  'ContactId',             'HiddenInput',           null,          0,           null,          1,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'ContactRefId',          'Text',                  null,          1,           null,          1,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'ContactType',           'Contact_DD',            null,          1,           null,          2,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'Name',                  'Text',                  null,          1,           null,          3,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'AddressLine1',          'Text',                  null,          1,           null,          4,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'AddressLine2',          'Text',                  null,          0,           null,          5,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'AddressLine3',          'Text',                  null,          0,           null,          6,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'City',                  'Text',                  null,          1,           null,          7,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'State',                 'Text',                  null,          1,           null,          8,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'Zip',                   'Text',                  null,          1,           null,          9,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'Country',               'Text',                  null,          1,           null,          10,      'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'PhoneNo',               'Text',                  null,          0,           null,          11,      'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'ContactPerson',         'Text',                  null,          0,           null,          12,      'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* Edit Contact */
/*------------------------------------------------------------------------------*/
select @FormName = 'Contacts_Edit';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
              (FieldName,              ControlName,             FieldCaption,  IsRequired,  DefaultValue,  SortSeq, DataTagType,  DataTagName,   FormName,   BusinessUnit)
      select  'ContactId',             'HiddenInput',           null,          1,           null,          1,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'ContactRefId',          'ReadOnlyText',          null,          1,           null,          1,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'ContactType',           'Contact_DD',            null,          1,           null,          2,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'Name',                  'Text',                  null,          1,           null,          3,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'AddressLine1',          'Text',                  null,          1,           null,          4,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'AddressLine2',          'Text',                  null,          0,           null,          5,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'AddressLine3',          'Text',                  null,          0,           null,          6,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'City',                  'Text',                  null,          1,           null,          7,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'State',                 'Text',                  null,          1,           null,          8,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'Zip',                   'Text',                  null,          1,           null,          9,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'Country',               'Text',                  null,          1,           null,          10,      'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'PhoneNo',               'Text',                  null,          0,           null,          11,      'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'ContactPerson',         'Text',                  null,          0,           null,          12,      'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits

Go
