/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/01/19  PKK     Corrected the file as per the template(CIMSV3-1282)
  2020/10/08  AY      Corrections to not show deprecated fields, removed Ownership & WH (HA-1553)
  2020/10/08  MRK     Added missing fields (HA-1430)
  2018/01/31  RT      Initial revision (CIMSV3-231)
------------------------------------------------------------------------------*/

Go

declare @ContextName    TName,
        @DataSetName    TName,

        @Layouts        TLayoutTable,
        @ttLF           TLayoutFieldsTable,
        @ttLSF          TLayoutSummaryFields,
        @BusinessUnit   TBusinessUnit;

select @ContextName = 'List.CartonTypes',
       @DataSetName = 'vwCartonTypes';

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
insert into @ttLF select 'CartonType',                  null,      1,   null,               null, null
insert into @ttLF select 'Description',                 null,   null,   null,               null, null

insert into @ttLF select 'EmptyWeight',                 null,   null,   null,               null, null

insert into @ttLF select 'InnerLength',                 null,   null,   null,               null, null
insert into @ttLF select 'InnerWidth',                  null,   null,   null,               null, null
insert into @ttLF select 'InnerHeight',                 null,   null,   null,               null, null
insert into @ttLF select 'InnerVolume',                 null,   null,   null,               null, null
insert into @ttLF select 'OuterLength',                 null,   null,   null,               null, null
insert into @ttLF select 'OuterWidth',                  null,   null,   null,               null, null
insert into @ttLF select 'OuterHeight',                 null,   null,   null,               null, null
insert into @ttLF select 'OuterVolume',                 null,   null,   null,               null, null

insert into @ttLF select 'AvailableSpace',              null,   null,   null,               null, null
insert into @ttLF select 'MaxWeight',                   null,     -1,   null,               null, null
insert into @ttLF select 'MaxUnits',                    null,     -1,   null,               null, null

-- insert into @ttLF select 'Ownership',                null,   null,   null,               null, null
-- insert into @ttLF select 'Warehouse',                null,     -2,   null,               null, null

insert into @ttLF select 'Status',                      null,      1,   null,               null, null
insert into @ttLF select 'SortSeq',                     null,   null,   null,               null, null
insert into @ttLF select 'Visible',                     null,   null,   null,               null, null

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

insert into @ttLF select 'DisplayDescription',          null,   null,   null,               null, null
insert into @ttLF select 'MaxInnerDimension',           null,   null,   null,               null, null
insert into @ttLF select 'CarrierPackagingType',        null,     -1,   null,               null, null

/* Deprecated fields */
insert into @ttLF select 'CartonTypeFilter',            null,     -2,   null,               null, null
insert into @ttLF select 'Account',                     null,     -2,   null,               null, null
insert into @ttLF select 'SoldToId',                    null,     -2,   null,               null, null
insert into @ttLF select 'ShipToId',                    null,     -2,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'RecordId;CartonType' /* KeyFields */;

Go
