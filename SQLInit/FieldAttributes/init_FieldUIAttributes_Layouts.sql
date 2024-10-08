/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/16  NB      Initial Revision(HA-2271)
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

select @ContextName = 'List.Layouts',
       @Category    = 'SF', /* Selection */
       @UIControl   = 'DropDown' ;
/*------------------------------------------------------------------------------*/
/* Links to Lists */
/*------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------*/
/* Layouts_Modify Action Form Field UI Attributes */
/*------------------------------------------------------------------------------*/
select @ContextName = 'Layouts_Modify',
       @Category    = 'F' /* Form */;

delete from @ttFieldUIAttributes;

insert into @ttFieldUIAttributes
             (FieldName,             ControlName,  UIControl,              DbSource,          DbsourceFilter,                                            DbLookUpFieldName,     DBLookupFieldList,                      DestinationContextName,  DestinationLayoutName, ReferenceValueField,  ReferenceDescriptionField)
      select 'DefaultSelectionName', null,         'DBLookupDropDown',     'Selections',     '(ContextName = ''~SELECTEDRECORDVALUE_ContextName~'') and (Status = ''A'') and ((UserName is null) or (UserName = ''~INPUTSESSIONINFO_UserId~''))',
                                                                                                                                                         'SelectionDescription','SelectionDescription, SelectionName',   null,                   null,                 'SelectionName',      'SelectionDescription'

exec pr_Setup_FieldUIAttributes @ContextName, @Category, @ttFieldUIAttributes, 'DI' /* Action - Insert */;

Go
