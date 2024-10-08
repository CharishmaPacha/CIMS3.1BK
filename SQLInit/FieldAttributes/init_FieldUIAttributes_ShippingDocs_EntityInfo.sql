/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/06/30  NB      Initial Revision(CIMSV3-963)
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

select @ContextName = null,
       @Category    = 'A', /* Links */
       @UIControl   = null;

/*------------------------------------------------------------------------------*/
/* Detail Links */
/*------------------------------------------------------------------------------*/
delete from @ttFieldUIAttributes;

select @ContextName      = 'ShippingDocs_EntityInfo_LPN',
       @UIControl        = 'DetailLink',
       @ReferenceContext = '/Home/EntityInfo';

insert into @ttFieldUIAttributes
             (FieldName,   ReferenceCategory, UIControl,  ReferenceContext,  ReferenceValueField)
      select 'LPN',        @ContextName,      @UIControl, @ReferenceContext, 'LPNId'

exec pr_Setup_FieldUIAttributes @ContextName/* Context */, @Category /* Category - Hyper link */, @ttFieldUIAttributes, 'ID' /* Action - Insert */, 'DL' /* Reference: Detail Links */;
/*------------------------------------------------------------------------------*/
delete from @ttFieldUIAttributes;
select @ContextName      = 'ShippingDocs_EntityInfo_Pallet',
       @UIControl        = 'DetailLink',
       @ReferenceContext = '/Home/EntityInfo';

insert into @ttFieldUIAttributes
             (FieldName,   ReferenceCategory, UIControl,  ReferenceContext,  ReferenceValueField)
      select 'Pallet',     @ContextName,      @UIControl, @ReferenceContext, 'PalletId'

exec pr_Setup_FieldUIAttributes @ContextName/* Context */, @Category /* Category - Hyper link */, @ttFieldUIAttributes, 'ID' /* Action - Insert */, 'DL' /* Reference: Detail Links */;
/*------------------------------------------------------------------------------*/
delete from @ttFieldUIAttributes;
select @ContextName      = 'ShippingDocs_EntityInfo_Order',
       @UIControl        = 'DetailLink',
       @ReferenceContext = '/Home/EntityInfo';

insert into @ttFieldUIAttributes
             (FieldName,   ReferenceCategory, UIControl,  ReferenceContext,  ReferenceValueField)
      select 'Order',     @ContextName,      @UIControl, @ReferenceContext, 'OrderId'

exec pr_Setup_FieldUIAttributes @ContextName/* Context */, @Category /* Category - Hyper link */, @ttFieldUIAttributes, 'ID' /* Action - Insert */, 'DL' /* Reference: Detail Links */;
/*------------------------------------------------------------------------------*/
delete from @ttFieldUIAttributes;
select @ContextName      = 'ShippingDocs_EntityInfo_Wave',
       @UIControl        = 'DetailLink',
       @ReferenceContext = '/Home/EntityInfo';

insert into @ttFieldUIAttributes
             (FieldName,   ReferenceCategory, UIControl,  ReferenceContext,  ReferenceValueField)
      select 'WaveNo',     @ContextName,      @UIControl, @ReferenceContext, 'WaveId'

exec pr_Setup_FieldUIAttributes @ContextName/* Context */, @Category /* Category - Hyper link */, @ttFieldUIAttributes, 'ID' /* Action - Insert */, 'DL' /* Reference: Detail Links */;
/*------------------------------------------------------------------------------*/
delete from @ttFieldUIAttributes;
select @ContextName      = 'ShippingDocs_EntityInfo_Load',
       @UIControl        = 'DetailLink',
       @ReferenceContext = '/Home/EntityInfo';

insert into @ttFieldUIAttributes
             (FieldName,   ReferenceCategory, UIControl,  ReferenceContext,      ReferenceValueField)
      select 'LoadNumber',     @ContextName,      @UIControl, @ReferenceContext, 'LoadId'

exec pr_Setup_FieldUIAttributes @ContextName/* Context */, @Category /* Category - Hyper link */, @ttFieldUIAttributes, 'ID' /* Action - Insert */, 'DL' /* Reference: Detail Links */;

Go
