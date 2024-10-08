/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/03  NB      Initial Revision (CIMSV3-1184)
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

select @ContextName = 'List.LabelFormats';

/*------------------------------------------------------------------------------*/
/* Links to preview data */
/*------------------------------------------------------------------------------*/
delete from @ttFieldUIAttributes;
select @Category  = 'A', /* Hyperlink */
       @UIControl = 'PreviewLink';

insert into @ttFieldUIAttributes
               (FieldName,        ReferenceValueField,    ReferenceDescriptionField,  UIControl,   ReferenceContext)
       select  'LabelFormatName', 'ZPLLink',              null,                       @UIControl,  'http://labelary.com/viewer.html'


exec pr_Setup_FieldUIAttributes @ContextName, @Category /* Category - Hyper link */, @ttFieldUIAttributes, 'DI' /* Action - Insert */, 'PL' /* Reference: Preview Links */;

/*------------------------------------------------------------------------------*/
/* Links to download files */
/*------------------------------------------------------------------------------*/
delete from @ttFieldUIAttributes;
select @Category  = 'A', /* Hyperlink */
       @UIControl = 'FileLink';

insert into @ttFieldUIAttributes
               (FieldName,          ReferenceValueField,    ReferenceDescriptionField,  UIControl,   ReferenceContext,         ReferenceCategory)
       select  'ZPLTemplate',       'ZPLFile',              null,                       @UIControl,  'Documents/GetDocument',  '~CONFIG_ZPLTEMPLATEDIRECTORYPATH~'

exec pr_Setup_FieldUIAttributes @ContextName, @Category /* Category - Hyper link */, @ttFieldUIAttributes, 'DI' /* Action - Insert */, 'FL' /* Reference: File Links */;

Go
