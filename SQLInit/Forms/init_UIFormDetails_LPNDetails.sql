/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/05/20  MS      Use LPNStatusDesc (HA-604)
  2020/04/14  MS      Initial revision (HA-181)
------------------------------------------------------------------------------*/

Go

declare @FormName  TName;

/*------------------------------------------------------------------------------*/
/* ChangeLPNQuantity Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'LPNDetail_AdjustQty';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
            (FieldName,               ControlName,             FieldCaption,            IsRequired, DefaultValue, SortSeq, DataTagType, DataTagName,        FormName,  BusinessUnit)
      select 'LPNId',                 'HiddenInput',           null,                    0,          null,         1,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits 
union select 'LPNDetailId',           'HiddenInput',           null,                    0,          null,         2,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'SKUId',                 'HiddenInput',           null,                    0,          null,         2,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'LPN',                   'ReadOnlyText',          null,                    0,          null,         5,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'LPNStatusDesc',         'ReadOnlyText',          null,                    0,          null,         6,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'SKU',                   'ReadOnlyText',          null,                    0,          null,         7,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'SKUDescription',        'ReadOnlyText',          'Style-Color-Size',      0,          null,         8,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'InnerPacks',            'IntegerMin0',           null,                    0,          null,         9,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'Quantity',              'IntegerMin0',           null,                    1,          null,         10,      'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'ReasonCode',            'RC_LPNAdjust_DD',       null,                    1,          null,         11,      'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'RefNumber',             'InputText',             'Reference',             0,          null,         12,      'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits

Go
