/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/05/10  RKC     Initial revision (CIMSV3-550).
------------------------------------------------------------------------------*/
Go

declare @ContextName         TName,
        @DataSetName         TName,

        @Layouts             TLayoutTable,
        @LayoutDescription   TDescription,

        @ttLF                TLayoutFieldsTable,
        @ttLFE               TLayoutFieldsExpandedTable,
        @ttLSF               TLayoutSummaryFields,
        @BusinessUnit        TBusinessUnit;

select @ContextName = 'List.CIMSDE_ImportCartonTypes',
       @DataSetName = 'vwCIMSDE_ImportCartonTypes';

/******************************************************************************/
/* Layouts */
/******************************************************************************/
delete from @Layouts;

/*                          Layout  Default  Layout                           Default               Status Visible SortSeq ShowExpanded
                            Type    Layout   Description                      SelectionName                                   */
insert into @Layouts select 'L',    'N',     'Standard',                      null,                 null,  null,   0,      null

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
insert into @ttLF select 'RecordType',                  null,     -1,   null,               null, null
insert into @ttLF select 'RecordAction',                null,   null,   null,               null, null

insert into @ttLF select 'CartonType',                  null,   null,   null,               null, null
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

insert into @ttLF select 'CarrierPackagingType',        null,   null,   null,               null, null
insert into @ttLF select 'EntityKey',                   null,   null,   null,               null, null

insert into @ttLF select 'SoldToId',                    null,   null,   null,               null, null
insert into @ttLF select 'ShipToId',                    null,   null,   null,               null, null

insert into @ttLF select 'AvailableSpace',              null,   null,   null,               null, null
insert into @ttLF select 'MaxWeight',                   null,   null,   null,               null, null

insert into @ttLF select 'Status',                      null,      1,   null,               null, null
insert into @ttLF select 'SortSeq',                     null,   null,   null,               null, null
insert into @ttLF select 'Visible',                     null,   null,   null,               null, null

insert into @ttLF select 'CT_UDF1',                     null,   null,   null,               null, null
insert into @ttLF select 'CT_UDF2',                     null,   null,   null,               null, null
insert into @ttLF select 'CT_UDF3',                     null,   null,   null,               null, null
insert into @ttLF select 'CT_UDF4',                     null,   null,   null,               null, null
insert into @ttLF select 'CT_UDF5',                     null,   null,   null,               null, null

insert into @ttLF select 'BusinessUnit',                null,   null,   null,               null, null
insert into @ttLF select 'CartonTypeId',                null,   null,   null,               null, null
insert into @ttLF select 'CreatedDate',                 null,   null,   null,               null, null
insert into @ttLF select 'ModifiedDate',                null,   null,   null,               null, null
insert into @ttLF select 'CreatedBy',                   null,   null,   null,               null, null
insert into @ttLF select 'ModifiedBy',                  null,   null,   null,               null, null

insert into @ttLF select 'InputXML',                    null,   null,   null,               null, null
insert into @ttLF select 'ResultXML',                   null,   null,   null,               null, null

insert into @ttLF select 'HostRecId',                   null,      1,   null,               null, null
insert into @ttLF select 'RecordId',                    null,      1,   null,               null, null
insert into @ttLF select 'ExchangeStatus',              null,      1,   null,               null, null
insert into @ttLF select 'InsertedTime',                null,      1,   null,               null, null
insert into @ttLF select 'ProcessedTime',               null,      1,   null,               null, null
insert into @ttLF select 'Reference',                   null,   null,   null,               null, null
insert into @ttLF select 'Result',                      null,   null,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'RecordId;';

/******************************************************************************/
/* Summary Layouts Details */
/******************************************************************************/

/******************************************************************************/
/* Summary Fields Setup */
/******************************************************************************/

Go
