/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/02/15  SJ      Setup hyperlink for fields LPN, Load, Pallet, Location (BK-176)
  2020/04/20  MS      Initial Revision(HA-232)
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
        @UIControl                  TTypeCode;

select @ContextName      = 'List.Exports',
       @Category         = 'SF', /* Selection */
       @UIControl        = 'DropDown';

/*------------------------------------------------------------------------------*/
/* Field Atributes for Selection and Forms */
/*------------------------------------------------------------------------------*/
insert into @ttFieldUIAttributes
            (FieldName,               ControlName,             ReferenceCategory,        AllowMultiSelect, AttributeType)
      select 'ExportStatus',          'ExportStatus_DDMS',     'ProcessedFlag',          'Y',              'L'
union select 'TransType',             'TransType_DDMS',        'Transaction',            'Y',              'E'
union select 'TransEntity',           'TransEntity_DDMS',      'TransEntity',            'Y',              'E'

exec pr_Setup_FieldUIAttributes null, @Category, @ttFieldUIAttributes, 'DI' /* Action - Insert */;

/*------------------------------------------------------------------------------*/
/* Mapped Fields */
/*------------------------------------------------------------------------------*/
delete from @ttFieldUIAttributes;

/* Type description columns - at times user add filters from the column filters
   In this case, the column filter must be added with the respective code field, instead of description field
   The solution is to identify the mapped field name of the description column and add filter for the actual field */

insert into @ttFieldUIAttributes
            (FieldName,               ReferenceCategory,  ReferenceValueField)
      select 'ExportStatusDesc',      '_MAPPEDFIELD_',    'ExportStatus'
union select 'TransTypeDescription',  '_MAPPEDFIELD_',    'TransType'
union select 'TransEntityDescription','_MAPPEDFIELD_',    'TransEntity'

exec pr_Setup_FieldUIAttributes @ContextName, @Category, @ttFieldUIAttributes, 'DI' /* Action - Insert */, 'M' /* Reference: Mapped Fields */;

/*------------------------------------------------------------------------------*/
/* Links to Lists */
/*------------------------------------------------------------------------------*/
delete from @ttFieldUIAttributes;
select @ContextName      = 'List.Exports',
       @UIControl        = 'ListLink',
       @ReferenceContext = '/Home/List';

insert into @ttFieldUIAttributes
               (FieldName,        DestinationContextName,        DestinationLayoutName,  DestinationSelectionName,  DestinationFilter,                      ReferenceValueField,    ReferenceDescriptionField,  UIControl,   ReferenceContext)
       select  'LPN',             'List.LPNs',                   'Standard',             null,                      null,                                   'LPNId',                null,                       @UIControl,  @ReferenceContext
union  select  'Pallet',          'List.Pallets',                'Standard',             null,                      null,                                   'PalletId',             null,                       @UIControl,  @ReferenceContext
union  select  'Location',        'List.Locations',              'Standard',             null,                      null,                                   'LocationId',           null,                       @UIControl,  @ReferenceContext

exec pr_Setup_FieldUIAttributes @ContextName, 'A' /* Category - Hyper link */, @ttFieldUIAttributes, 'DI' /* Action - Insert */, 'LL' /* Reference: List Links */;

Go
