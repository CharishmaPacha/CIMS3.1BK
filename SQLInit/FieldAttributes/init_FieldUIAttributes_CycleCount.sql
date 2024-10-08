/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/04  KBB     Added new Hyperlink for CycleCountStatistics (HA-2003)
  2020/12/18  KBB     Added New ControlName for CCUsers_DD (HA-1792)
  2020/11/17  SK      Added new field attribute CC_Process_DD (HA-1657)
  2020/09/18  MS      Bug fix for Location HyperLink in CCLocations page (HA-1445)
  2020/09/09  KBB     Added new Hyperlink for CycleCountLocations (HA-1406)
  2020/07/17  KBB     Added Hyper Link (CIMSV3-1024)
              KBB     Added New Selection's for TaskSubTypeDescription (CIMSV3-1023)
  2020/07/08  MS      Initial Revision (CIMSV3-548)
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

select @ContextName = 'List.CycleCountLocations',
       @Category    = 'SF', /* Selection */
       @UIControl   = 'DropDown' ;

/*------------------------------------------------------------------------------*/
/* Field Attributes for CycleCounts Selections & Forms */
/*------------------------------------------------------------------------------*/
delete from @ttFieldUIAttributes;

insert into @ttFieldUIAttributes
            (FieldName,                    ControlName,           ReferenceCategory,      AllowMultiSelect, AttributeType)
      select null,                         'CC_Process_DD',       'CC_Process',           'N',              'L'
union select null,                         'CC_Level_DD',         'CC_Level',             'N',              'L'
union select null,                         'CC_LocationDetail_DD','CC_LocationDetail',    'N',              'L'
union select 'TaskSubType',                'TaskSubType_DD',      'CC_SubTask',           'Y',              'E'

exec pr_Setup_FieldUIAttributes null, @Category, @ttFieldUIAttributes, 'DI' /* Action - Insert */;

/*------------------------------------------------------------------------------*/
/* Mapped Fields */
/*------------------------------------------------------------------------------*/
select @Category    = 'SF', /* Forms */
       @UIControl   = 'DropDown' ;
delete from @ttFieldUIAttributes;

/* Type description columns - at times user add filters from the column filters
   In this case, the column filter must be added with the respective code field, instead of description field
   The solution is to identify the mapped field name of the description column and add filter for the actual field */

insert into @ttFieldUIAttributes
             (FieldName,                   ReferenceCategory,   ReferenceValueField)
      select 'TaskSubTypeDesc',            '_MAPPEDFIELD_',     'TaskSubType'

/* Context for mapped fields should be null so that they are applicable in all contexts */
exec pr_Setup_FieldUIAttributes null, @Category, @ttFieldUIAttributes, 'DI' /* Action - Insert */, 'M' /* Reference: Mapped Fields */;

/*------------------------------------------------------------------------------*/
/* CCtasks Assign To User Form Field UI Attributes*/
/*------------------------------------------------------------------------------*/
select @Category = 'F'; /* Forms */

delete from @ttFieldUIAttributes;

insert into @ttFieldUIAttributes
             (ControlName,             UIControl,           DbSource,           DbsourceFilter,     DbLookUpFieldName,    DBLookupFieldList,               DestinationContextName,          DestinationLayoutName,  ReferenceValueField,  ReferenceDescriptionField)
      select  'CCUsers_DD',            'DBLookupDropDown',  'vwUserRolePermissions',
                                                                                'PermissionName = ''RFCycleCounting'' and IsAllowed = 1',
                                                                                                    'Name',              'Name,UserName',                  null,                             null,                  'UserName',           'Name'

exec pr_Setup_FieldUIAttributes null, @Category, @ttFieldUIAttributes, 'DI' /* Action - Insert */;

/*------------------------------------------------------------------------------*/
/* Links to Lists */
/*------------------------------------------------------------------------------*/
delete from @ttFieldUIAttributes;
select @ContextName      = 'List.CycleCountTasks',
       @UIControl        = 'ListLink',
       @ReferenceContext = '/Home/List';

insert into @ttFieldUIAttributes
               (FieldName,        DestinationContextName,        DestinationLayoutName,  DestinationSelectionName,  DestinationFilter,                      ReferenceValueField,    ReferenceDescriptionField,  UIControl,   ReferenceContext)
       select  'DetailCount',     'List.CycleCountTaskDetails',  'Standard',             null,                      null,                                   'TaskId',               null,                       @UIControl,  @ReferenceContext
union  select  'BatchNo',         'List.CycleCountStatistics',   'Standard',             null,                      null,                                   'TaskId',               null,                       @UIControl,  @ReferenceContext

exec pr_Setup_FieldUIAttributes @ContextName, 'A' /* Category - Hyper link */, @ttFieldUIAttributes, 'DI' /* Action - Insert */, 'LL' /* Reference: List Links */;

/*------------------------------------------------------------------------------*/
/* Links to Lists */
/*------------------------------------------------------------------------------*/
delete from @ttFieldUIAttributes;
select @ContextName      = 'List.CycleCountLocations',
       @UIControl        = 'ListLink',
       @ReferenceContext = '/Home/List';

insert into @ttFieldUIAttributes
               (FieldName,        DestinationContextName,        DestinationLayoutName,  DestinationSelectionName,  DestinationFilter,                      ReferenceValueField,    ReferenceDescriptionField,  UIControl,   ReferenceContext)
       select  'Location',       'List.Locations',               'Standard',             null,                      null,                                   'LocationId',           null,                       @UIControl,  @ReferenceContext

exec pr_Setup_FieldUIAttributes @ContextName, 'A' /* Category - Hyper link */, @ttFieldUIAttributes, 'DI' /* Action - Insert */, 'LL' /* Reference: List Links */;

/*------------------------------------------------------------------------------*/
/* Links to Lists */
/*------------------------------------------------------------------------------*/
delete from @ttFieldUIAttributes;
select @ContextName      = 'List.CycleCountStatistics',
       @UIControl        = 'ListLink',
       @ReferenceContext = '/Home/List';

/* This is a hyperlink on Locations on CC statistics page to show summary of the Location after cycle count  */

insert into @ttFieldUIAttributes
             (FieldName,              DestinationContextName,            DestinationLayoutName,  DestinationSelectionName,  DestinationFilter,              ReferenceValueField,    ReferenceDescriptionField,  UIControl,  ReferenceContext)
      select 'Location',              'List.CycleCountResults',          'Standard',             null,                      null,                           'TaskDetailId',         null,                       @UIControl, @ReferenceContext

exec pr_Setup_FieldUIAttributes @ContextName, 'A' /* Category - Hyper link */, @ttFieldUIAttributes, 'DI' /* Action - Insert */, 'LL' /* Reference: List Links */;

Go
