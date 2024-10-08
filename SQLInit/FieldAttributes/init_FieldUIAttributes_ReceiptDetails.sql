/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/05/04  VS      Added SKUImageURL to Preview the SKUImage (BK-1053)
  2020/06/19  SAK     Initial Revision (HA-149)
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

select @ContextName = 'List.ReceiptDetails',
       @Category    = 'SF', /* Selection */
       @UIControl   = 'DropDown' ;

/*------------------------------------------------------------------------------*/
/* Mapped Fields */
/*------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------*/
/* Links to preview sku image */
/*------------------------------------------------------------------------------*/
delete from @ttFieldUIAttributes;
select @Category  = 'A', /* Hyperlink */
       @UIControl = 'PreviewLink';

insert into @ttFieldUIAttributes
               (FieldName,        ReferenceValueField,    ReferenceDescriptionField,  UIControl,   ReferenceContext)
       select  'SKUImageURL',     null,                   null,                       @UIControl,  dbo.fn_Controls_GetAsString('SKU', 'ImageURLPath', '', BusinessUnit, '' /* UserId */) from vwBusinessUnits

exec pr_Setup_FieldUIAttributes @ContextName, @Category /* Category - Hyper link */, @ttFieldUIAttributes, 'DI' /* Action - Insert */, 'PL' /* Reference: Preview Links */;

Go
