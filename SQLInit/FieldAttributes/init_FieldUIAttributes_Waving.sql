/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/05/29  AY      Initial Revision
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

select @ContextName      = 'Waving.Waves',
       @Category         = 'SF', /* Selection & Forms */
       @UIControl        = 'DropDown';

/*------------------------------------------------------------------------------*/
/* Field Attributes for Wave Selections & Forms */
/*------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------*/
/* Mapped Fields */
/*------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------*/
/* Wave ReleaseForAllocation Form Field UI Attributes */
/*------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------*/
/* Detail Links */
/*------------------------------------------------------------------------------*/
delete from @ttFieldUIAttributes;

select @UIControl        = 'DetailLink',
       @ReferenceContext = '/Home/EntityDetail';

-- insert into @ttFieldUIAttributes
--              (FieldName,   ReferenceCategory, ReferenceValueField, UIControl,  ReferenceContext)
--       select 'PickTicket', 'Order',           'OrderId',             @UIControl, @ReferenceContext
-- union select 'Pallet',     'PAL',             'PalletId',          @UIControl, @ReferenceContext
-- union select 'Location',   'LOC',             'LocationId',        @UIControl, @ReferenceContext

-- exec pr_Setup_FieldUIAttributes @ContextName, 'A' /* Category - Hyper link */, @ttFieldUIAttributes, 'ID' /* Action - Insert */, 'DL' /* Reference: Detail Links */;

/*------------------------------------------------------------------------------*/
/* Detail Links */
/*------------------------------------------------------------------------------*/
delete from @ttFieldUIAttributes;

select @UIControl        = 'DetailLink',
       @ReferenceContext = '/Home/EntityInfo';

insert into @ttFieldUIAttributes
             (FieldName,   ReferenceCategory, UIControl,  ReferenceContext,  ReferenceValueField)
      select 'WaveNo',     'Wave_EntityInfo', @UIControl, @ReferenceContext, 'WaveId'

exec pr_Setup_FieldUIAttributes @ContextName, 'A' /* Category - Hyper link */, @ttFieldUIAttributes, 'ID' /* Action - Insert */, 'DL' /* Reference: Detail Links */;

/*------------------------------------------------------------------------------*/
/* Links to Lists */
/*------------------------------------------------------------------------------*/
delete from @ttFieldUIAttributes;

select @UIControl        = 'ListLink',
       @ReferenceContext = '/Home/List';

/* For the record with WaveNo as FieldName, we can use WaveId/PickBatchId as ReferenceValueField rather than RecordId.
   But the functionality of linked list is purily depedens over the FieldVisibility value in the LayoutFields and Visible value
   in the Fields table. For the current configuration of the respective field visibilities taken RecordId into consideration. */

insert into @ttFieldUIAttributes
             (FieldName,              DestinationContextName, DestinationLayoutName,  DestinationSelectionName,  DestinationFilter,                       ReferenceValueField, ReferenceDescriptionField,  UIControl,  ReferenceContext)
      select 'NumOrders',             'List.Orders',          'Standard',             null,                      null,                                    'PickBatchNo',       null,                       @UIControl, @ReferenceContext
union select 'NumLines',              'List.OrderDetails',    'Standard',             null,                      null,                                    'PickBatchNo',       null,                       @UIControl, @ReferenceContext
union select 'NumUnits',              'List.WaveSummary',     'Standard',             null,                      null,                                    'WaveNo',            null,                       @UIControl, @ReferenceContext

exec pr_Setup_FieldUIAttributes @ContextName, 'A' /* Category - Hyper link */, @ttFieldUIAttributes, 'DI' /* Action - Insert */, 'LL' /* Reference: List Links */;

/******************************************************************************/
/******************************************************************************/
select @ContextName      = 'Waving.Orders',
       @Category         = 'SF', /* Selection & Forms */
       @UIControl        = 'DropDown';

/*------------------------------------------------------------------------------*/
/* Field Attributes for Wave Selections & Forms */
/*------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------*/
/* Mapped Fields */
/*------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------*/
/* Wave ReleaseForAllocation Form Field UI Attributes */
/*------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------*/
/* Detail Links */
/*------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------*/
/* Links to Lists */
/*------------------------------------------------------------------------------*/
delete from @ttFieldUIAttributes;

select @UIControl        = 'ListLink',
       @ReferenceContext = '/Home/List';

insert into @ttFieldUIAttributes
            (FieldName,        DestinationContextName, DestinationLayoutName, DestinationSelectionName,      DestinationFilter,                            ReferenceValueField,    ReferenceDescriptionField,  UIControl,  ReferenceContext)
      select 'NumUnits',       'List.OrderDetails',    'Standard',            null,                          null,                                         'OrderId',              null,                       @UIControl, @ReferenceContext

exec pr_Setup_FieldUIAttributes @ContextName, 'A' /* Category - Hyper link */, @ttFieldUIAttributes, 'DI' /* Action - Insert */, 'LL' /* Reference: Detail Links */;

Go
