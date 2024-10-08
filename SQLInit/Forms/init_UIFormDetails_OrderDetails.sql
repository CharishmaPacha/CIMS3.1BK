/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/06/15  AY      OrderDetails_ModifyOrderDetails renamed to OrderDetails_Modify (CIMSV3-1515)
  2020/06/16  AJM     Included OrderDetails_ModifyReworkInfo (HA-1059)
  2020/05/26  SAK     Added action ModifyPackCombination (HA-644)
  2020/05/15  RT      ModifyOrderDetails: Included PackingGroup (HA-382)
  2020/04/23  RT      ModifyOrderDetails: Included UnitsPerCarton (HA-287)
  2019/06/14  MS      Changes to use controls (cIMSV3-424)
  2019/05/13  MS      Added CancelPTLine Form Attributes (CIMSV3-429)
  2019/05/08  RIA     Changes for field captions and DataTagName (CIMSV3-429)
  2019/04/21  MS      Initial revision (CIMSV3-429)
------------------------------------------------------------------------------*/

Go

declare @FormName  TName;

/*------------------------------------------------------------------------------*/
/* ModifyOrderDetails Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'OrderDetails_Modify';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
             (FieldName,                 ControlName,     FieldCaption,  IsRequired,  DataTagType,  DataTagName,  SortSeq,  DefaultValue,  FormName,   BusinessUnit)
      select  'PickTicket',              'ReadOnlyText',  null,          0,           'Data',       null,         1,        null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'CustPO',                  'ReadOnlyText',  null,          0,           'Data',       null,         2,        null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'ShipToStore',             'ReadOnlyText',  null,          0,           'Data',       null,         3,        null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'SKU',                     'ReadOnlyText',  null,          0,           'Data',       null,         4,        null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'SKU1',                    'ReadOnlyText',  null,          0,           'Data',       null,         5,        null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'SKU2',                    'ReadOnlyText',  null,          0,           'Data',       null,         6,        null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'SKU3',                    'ReadOnlyText',  null,          0,           'Data',       null,         7,        null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'UnitsOrdered',            'ReadOnlyText',  null,          0,           'Data',       null,         8,        null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'UnitsAssigned',           'ReadOnlyText',  null,          0,           'Data',       null,         9,        null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'UnitsAuthorizedToShip',   'IntegerMin0',   null,          0,           'Data',       null,         10,       null,          @FormName,  BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* ModifyPackCombination Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'OrderDetails_ModifyPackCombination';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
             (FieldName,                 ControlName,     FieldCaption,  IsRequired,  DataTagType,  DataTagName,  SortSeq,  DefaultValue,  FormName,   BusinessUnit)
      select  'UnitsPerCarton',          'IntegerMin0',   null,          0,           'Data',       null,         1,        null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'PackingGroup',            'Text',          null,          0,           'Data',       null,         2,        null,          @FormName,  BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* ModifyReworkInfo Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'OrderDetails_ModifyReworkInfo';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
             (FieldName,                 ControlName,              FieldCaption,       IsRequired,  DataTagType,  DataTagName,  SortSeq,  DefaultValue,  FormName,   BusinessUnit)
      select  'PickTicket',              'ReadOnlyText',           null,               0,           'Data',       null,         1,        null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'SKU',                     'ReadOnlyText',           null,               0,           'Data',       null,         2,        null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'NewSKU',                  'SKU_DD',                 null,               0,           'Data',       null,         3,        null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'InventoryClass1',         'ReadOnlyText',           null,               0,           'Data',       null,         4,        null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'NewInventoryClass1',      'InventoryClass1_DD',     null,               0,           'Data',       null,         5,        null,          @FormName,  BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* CancelPTLine Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'OrderDetails_CancelPTLine';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
             (FieldName,                 ControlName,     FieldCaption,  IsRequired,  DataTagType,  DataTagName,  SortSeq,  DefaultValue,  FormName,   BusinessUnit)
      select  'PickTicket',              'ReadOnlyText',  null,          0,           'Data',       null,         1,        null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'UnitsOrdered',            'ReadOnlyText',  null,          0,           'Data',       null,         2,        null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'SKU',                     'ReadOnlyText',  null,          0,           'Data',       null,         3,        null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'SKUDesc',                 'ReadOnlyText',  null,          0,           'Data',       null,         4,        null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'UnitsAuthorizedToShip',   'ReadOnlyText',  null,          0,           'Data',       null,         5,        null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'UnitsAssigned',           'ReadOnlyText',  null,          0,           'Data',       null,         6,        null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'UnitsToAllocate',         'IntegerMin0',   null,          0,           'Data',       null,         7,        null,          @FormName,  BusinessUnit from vwBusinessUnits

Go