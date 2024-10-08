/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/01/19  PKK      Corrected the file as per the template(CIMSV3-1282)
  2020/09/15  HYP      Added missing fields in the Layout that exists in the Data set (HA-796)
  2020/07/01  HYP      Added Fields (HA-796)
  2020/06/29  HYP      Removed the fields (HA-796)
  2020/06/23  HYP      Initial revision (HA-796)
------------------------------------------------------------------------------*/

Go

declare @ContextName    TName,
        @DataSetName    TName,

        @Layouts        TLayoutTable,
        @ttLF           TLayoutFieldsTable,
        @ttLSF          TLayoutSummaryFields,
        @BusinessUnit   TBusinessUnit;

select @ContextName = 'List.CartonGroups',
       @DataSetName = 'vwCartonGroupsAndTypes';

/******************************************************************************/
/* Layouts */
/******************************************************************************/
delete from @Layouts;

/*                            Layout  Default  Layout                        Default        Status Visible SortSeq ShowExpanded
                              Type    Layout   Description                   SelectionName                                      */
insert into @Layouts select 'L',    'N',     'Standard',                   null,          null,  null,   0,      null

exec pr_Setup_Layout @ContextName, @DataSetName, @Layouts, 'DI' /* Delete & Insert */, 'cimsdba', @BusinessUnit;

/******************************************************************************/
/* Listing Layouts Details */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
/* Layout Fields for Standard Layout */
/*----------------------------------------------------------------------------*/
delete from @ttLF;

/*                        Field                         Visible Visible Field               Width Display
                          Name                          Index           Caption                   Format */
insert into @ttLF select 'RecordId',                    null,   null,   null,               null, null
insert into @ttLF select 'CartonGroup',                 null,      1,   null,               null, null
insert into @ttLF select 'CartonType',                  null,      1,   null,               null, null
insert into @ttLF select 'CartonGroupDesc',             null,     -2,   null,               null, null
insert into @ttLF select 'CartonTypeDesc',              null,   null,   null,               null, null
insert into @ttLF select 'CartonGroupDisplayDesc',      null,     -2,   null,               null, null
insert into @ttLF select 'CartonTypeDisplayDesc',       null,   null,   null,               null, null

insert into @ttLF select 'AvailableSpace',              null,   null,   null,               null, null
insert into @ttLF select 'MaxWeight',                   null,   null,   null,               null, null
insert into @ttLF select 'MaxUnits',                    null,      1,   null,               null, null

insert into @ttLF select 'CG_AvailableSpace',           null,   null,   null,               null, null
insert into @ttLF select 'CG_MaxWeight',                null,   null,   null,               null, null
insert into @ttLF select 'CG_MaxUnits',                 null,   null,   null,               null, null

insert into @ttLF select 'CT_AvailableSpace',           null,   null,   null,               null, null
insert into @ttLF select 'CT_MaxWeight',                null,   null,   null,               null, null
insert into @ttLF select 'CT_MaxUnits',                 null,   null,   null,               null, null

insert into @ttLF select 'CT_InnerDimensions',          null,      1,   null,               null, null
insert into @ttLF select 'MaxInnerDimension',           null,   null,   null,               null, null
insert into @ttLF select 'FirstDimension',              null,   null,   null,               null, null
insert into @ttLF select 'SecondDimension',             null,   null,   null,               null, null
insert into @ttLF select 'ThirdDimension',              null,   null,   null,               null, null

insert into @ttLF select 'InnerLength',                 null,     -1,   null,               null, null
insert into @ttLF select 'InnerWidth',                  null,     -1,   null,               null, null
insert into @ttLF select 'InnerHeight',                 null,     -1,   null,               null, null
insert into @ttLF select 'InnerVolume',                 null,     -1,   null,               null, null
insert into @ttLF select 'EmptyWeight',                 null,     -1,   null,               null, null

insert into @ttLF select 'CT_OuterDimensions',          null,     -2,   null,               null, null
insert into @ttLF select 'OuterLength',                 null,     -2,   null,               null, null
insert into @ttLF select 'OuterWidth',                  null,     -2,   null,               null, null
insert into @ttLF select 'OuterHeight',                 null,     -2,   null,               null, null
insert into @ttLF select 'OuterVolume',                 null,     -2,   null,               null, null

insert into @ttLF select 'CGT_Status',                  null,   null,   null,               null, null
insert into @ttLF select 'CG_Status',                   null,   null,   null,               null, null
insert into @ttLF select 'CG_SortSeq',                  null,   null,   null,               null, null
insert into @ttLF select 'CG_Visible',                  null,   null,   null,               null, null

insert into @ttLF select 'CT_Status',                   null,   null,   null,               null, null
insert into @ttLF select 'CT_SortSeq',                  null,   null,   null,               null, null
insert into @ttLF select 'CT_Visible',                  null,   null,   null,               null, null

insert into @ttLF select 'CG_UDF1',                     null,   null,   null,               null, null
insert into @ttLF select 'CG_UDF2',                     null,   null,   null,               null, null
insert into @ttLF select 'CG_UDF3',                     null,   null,   null,               null, null
insert into @ttLF select 'CG_UDF4',                     null,   null,   null,               null, null
insert into @ttLF select 'CG_UDF5',                     null,   null,   null,               null, null

insert into @ttLF select 'CT_UDF1',                     null,   null,   null,               null, null
insert into @ttLF select 'CT_UDF2',                     null,   null,   null,               null, null
insert into @ttLF select 'CT_UDF3',                     null,   null,   null,               null, null
insert into @ttLF select 'CT_UDF4',                     null,   null,   null,               null, null
insert into @ttLF select 'CT_UDF5',                     null,   null,   null,               null, null

insert into @ttLF select 'BusinessUnit',                null,   null,   null,               null, null
insert into @ttLF select 'CreatedDate',                 null,   null,   null,               null, null
insert into @ttLF select 'ModifiedDate',                null,   null,   null,               null, null
insert into @ttLF select 'CreatedBy',                   null,   null,   null,               null, null
insert into @ttLF select 'ModifiedBy',                  null,   null,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'RecordId;' /* KeyFields */;

Go