/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/06/06  PKK      Initial Revision (BK-852)
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

select @ContextName = 'List.CIMSDE_ExportInvSnapshot',
       @Category    = 'SF', /* Selection & Forms */
       @UIControl   = 'DropDown';

/*------------------------------------------------------------------------------*/
/* Links to Lists */
/*------------------------------------------------------------------------------*/
delete from @ttFieldUIAttributes;

select @UIControl        = 'ListLink',
       @ReferenceContext = '/Home/List';

insert into @ttFieldUIAttributes
            (FieldName,        DestinationContextName, DestinationLayoutName, DestinationSelectionName,      DestinationFilter,                      ReferenceValueField,  ReferenceDescriptionField,  UIControl,  ReferenceContext)
      select 'OnhandQty',      'List.OnhandInventory', 'Standard',            null,                          null,                                   'SKU',                null,                       @UIControl, @ReferenceContext
union select 'ToShipQty',      'List.OrderDetails',    'Standard',            null,                          'UnitsToAllocate > 0 and Status not in (''S'', ''X'') |',
                                                                                                                                                     'SKU',                null,                       @UIControl, @ReferenceContext

exec pr_Setup_FieldUIAttributes @ContextName, 'A' /* Category - Hyper link */, @ttFieldUIAttributes, 'DI' /* Action - Insert */, 'LL' /* Reference: Detail Links */;

Go
