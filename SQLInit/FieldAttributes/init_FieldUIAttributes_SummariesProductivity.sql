/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/07/09  SK      Initial Revision (HA-2972)
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

select @ContextName = 'List.SummaryProductivity',
       @Category    = 'SF', /* Selection */
       @UIControl   = 'DropDown';

/*------------------------------------------------------------------------------*/
/* Field Atributes for Selection and Forms */
/*------------------------------------------------------------------------------*/
delete from @ttFieldUIAttributes;

/*------------------------------------------------------------------------------*/
/* Summarize related controls for forms */
/*------------------------------------------------------------------------------*/
select @Category    = 'F', /* Forms */
       @UIControl   = 'DropDown' ;

delete from @ttFieldUIAttributes;

insert into @ttFieldUIAttributes
             (ControlName,               ReferenceCategory,        ReferenceDescriptionField,   AllowMultiSelect,  AttributeType)
      select  'ProdSumBy_DD',            'UserProductivitySumBy',  null,                        'N',               'L'

exec pr_Setup_FieldUIAttributes null, @Category, @ttFieldUIAttributes, 'DI' /* Action - Delete and  Insert */;


/*------------------------------------------------------------------------------*/
/* Links to Lists */
/*------------------------------------------------------------------------------*/
delete from @ttFieldUIAttributes;

select @UIControl        = 'ListLink',
       @ReferenceContext = '/Home/List';

insert into @ttFieldUIAttributes
            (FieldName,        DestinationContextName,  DestinationLayoutName, DestinationSelectionName,  DestinationFilter,                       ReferenceValueField,    ReferenceDescriptionField,  UIControl,   ReferenceContext)
      select 'NumAssignments', 'List.UserProductivity', 'Standard',            null,                      null,                                    'UserId',               null,                       @UIControl,  @ReferenceContext

exec pr_Setup_FieldUIAttributes @ContextName, 'A' /* Category - Hyper link */, @ttFieldUIAttributes, 'DI' /* Action - Insert */, 'LL' /* Reference: List Links */;


Go
