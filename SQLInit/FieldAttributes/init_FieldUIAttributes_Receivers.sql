/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/10/01  RV      Added OpenReceivers_DD (FBV3-265)
  2020/04/20  MS      Added DetailLink for ReceiverNumber (HA-202)
  2020/03/12  MS      Initial Revision (CIMSV3-750)
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

select @ContextName = 'List.Receivers',
       @Category    = 'SF', /* Selection */
       @UIControl   = 'DropDown' ;

/*------------------------------------------------------------------------------*/
/* Statuses */
/*------------------------------------------------------------------------------*/
delete from @ttFieldUIAttributes;

insert into @ttFieldUIAttributes
            (FieldName,         ControlName,             ReferenceCategory, AllowMultiSelect, AttributeType)
      select 'ReceiverStatus',  'ReceiverStatus_DDMS',   'Receiver',        'Y',              'S'

exec pr_Setup_FieldUIAttributes null, @Category, @ttFieldUIAttributes, 'DI' /* Action - Insert */, 'S' /* Reference: Status */;

/*------------------------------------------------------------------------------*/
/* Mapped Fields */
/*------------------------------------------------------------------------------*/
delete from @ttFieldUIAttributes;

/* Type description columns - at times user add filters from the column filters
   In this case, the column filter must be added with the respective code field, instead of description field
   The solution is to identify the mapped field name of the description column and add filter for the actual field */

insert into @ttFieldUIAttributes
             (FieldName,              ReferenceCategory,  ReferenceValueField)
      select 'ReceiverStatusDesc',    '_MAPPEDFIELD_',    'ReceiverStatus'

exec pr_Setup_FieldUIAttributes @ContextName, @Category, @ttFieldUIAttributes, 'DI' /* Action - Insert */, 'M' /* Reference: Mapped Fields */;

/*------------------------------------------------------------------------------*/
/* Field Attributes only for Forms */
/*------------------------------------------------------------------------------*/
select @Category    = 'F' /* Form */;

delete from @ttFieldUIAttributes;

insert into @ttFieldUIAttributes
             (ControlName,             UIControl,           DbSource,           DbsourceFilter,                     DbLookUpFieldName,    ReferenceValueField,  ReferenceDescriptionField, DbLookUpFieldList, AllowMultiSelect, DestinationContextName,            DestinationLayoutName)
      select 'OpenReceivers_DD',       'DBLookupDropDown',  'vwReceivers',      '(~INPUTFILTER_Warehouse~) and Status = ''O''',
                                                                                                                    'ReceiverNumber',     'ReceiverId',         'ReceiverNumber',          null,              'N',              'UserControl.SelectReceiver',      'Standard'
exec pr_Setup_FieldUIAttributes null, @Category, @ttFieldUIAttributes, 'DI' /* Action - Insert */;

/*------------------------------------------------------------------------------*/
/* Detail Links */
/*------------------------------------------------------------------------------*/
delete from @ttFieldUIAttributes;

select @UIControl        = 'DetailLink',
       @ReferenceContext = '/Home/EntityInfo';

insert into @ttFieldUIAttributes
             (FieldName,       ReferenceCategory,   UIControl,  ReferenceContext,  ReferenceValueField)
      select 'ReceiverNumber', 'RCV_EntityInfo',    @UIControl, @ReferenceContext, 'ReceiverId'

exec pr_Setup_FieldUIAttributes @ContextName, 'A' /* Category - Hyper link */, @ttFieldUIAttributes, 'ID' /* Action - Insert */, 'DL' /* Reference: Detail Links */;

Go
