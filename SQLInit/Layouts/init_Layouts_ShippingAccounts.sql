/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/12/23  PKK     Corrected the file as per template (CIMSV3-1282)
  2019/05/14  RKC     File organized to be in compliance with latest template init_Layouts_Template.sql (CIMSV3-537)
  2019/04/12  PHK     Initial revision (CIMSV3-229)
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

select @ContextName = 'List.ShippingAccounts',
       @DataSetName = 'vwShippingAccounts';

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
insert into @ttLF select 'RecordId',                    null,     -2,   null,               null, null

insert into @ttLF select 'ShippingAcctName',            null,   null,   null,               null, null

insert into @ttLF select 'Carrier',                     null,   null,   null,               null, null
insert into @ttLF select 'ShipVia',                     null,   null,   null,               null, null

insert into @ttLF select 'ShipperAccountNumber',        null,   null,   null,               null, null
insert into @ttLF select 'ShipperMeterNumber',          null,   null,   null,               null, null
insert into @ttLF select 'ShipperAccessKey',            null,   null,   null,               null, null

insert into @ttLF select 'UserId',                      null,     -1,   null,               null, null
insert into @ttLF select 'Password',                    null,     -1,   null,               null, null

insert into @ttLF select 'MasterAccount',               null,   null,   null,               null, null
insert into @ttLF select 'AccountDetails',              null,   null,   null,               null, null

insert into @ttLF select 'Status',                      null,   null,   null,               null, null
insert into @ttLF select 'SortSeq',                     null,   null,   null,               null, null
insert into @ttLF select 'BusinessUnit',                null,     -1,   null,               null, null

insert into @ttLF select 'SA_UDF1',                     null,   null,   null,               null, null
insert into @ttLF select 'SA_UDF2',                     null,   null,   null,               null, null
insert into @ttLF select 'SA_UDF3',                     null,   null,   null,               null, null
insert into @ttLF select 'SA_UDF4',                     null,   null,   null,               null, null
insert into @ttLF select 'SA_UDF5',                     null,   null,   null,               null, null

insert into @ttLF select 'CreatedDate',                 null,   null,   null,               null, null
insert into @ttLF select 'ModifiedDate',                null,   null,   null,               null, null
insert into @ttLF select 'CreatedBy',                   null,   null,   null,               null, null
insert into @ttLF select 'ModifiedBy',                  null,   null,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'RecordId;' /* Key fields */;

/******************************************************************************/
/* Summary Layouts Details */
/******************************************************************************/

/*----------------------------------------------------------------------------*/

/******************************************************************************/
/* Summary Fields Setup */
/******************************************************************************/

Go