/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/18  KBB     Added RecordId and missing layoutfields (HA-1670)
  2019/05/14  RKC     File organized to be in compliance with latest template init_Layouts_Template.sql (CIMSV3-537)
  2019/04/08  PHK     Made some changes in the layout(CIMSV3-230)
  2018/02/01  AJ      Initial revision.
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

select @ContextName = 'List.ShipVias',
       @DataSetName = 'vwShipVias';

/******************************************************************************/
/* Layouts */
/******************************************************************************/
delete from @Layouts;

/*                          Layout  Default  Layout                        Default        Status Visible SortSeq ShowExpanded
                            Type    Layout   Description                   SelectionName                                   */
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
insert into @ttLF select 'RecordId',                    null,     -3,   null,               null, null
insert into @ttLF select 'ShipVia',                     null,      1,   null,               null, null
insert into @ttLF select 'ShipViaDescription',          null,      1,   null,               null, null
insert into @ttLF select 'Carrier',                     null,      1,   null,               null, null
insert into @ttLF select 'CarrierServiceCode',          null,      1,   null,               null, null
insert into @ttLF select 'SCAC',                        null,      1,   null,               null, null

insert into @ttLF select 'StandardAttributes',          null,     -1,   null,               null, null
insert into @ttLF select 'IsSmallPackageCarrier',       null,      1,   null,               null, null
insert into @ttLF select 'SpecialServices',             null,     -1,   null,               null, null
insert into @ttLF select 'ServiceLevel',                null,      1,   null,               null, null

insert into @ttLF select 'ServiceClassDesc',            null,      1,   null,               null, null
insert into @ttLF select 'ServiceClass',                null,     -1,   null,               null, null
insert into @ttLF select 'CarrierType',                 null,     -1,   null,               null, null
insert into @ttLF select 'PackagingType',               null,     -1,   null,               null, null

insert into @ttLF select 'Status',                      null,     -3,   null,               null, null
insert into @ttLF select 'SortSeq',                     null,     -1,   null,               null, null

insert into @ttLF select 'BusinessUnit',                null,     -2,   null,               null, null
insert into @ttLF select 'CreatedDate',                 null,     -1,   null,               null, null
insert into @ttLF select 'ModifiedDate',                null,     -1,   null,               null, null
insert into @ttLF select 'CreatedBy',                   null,     -1,   null,               null, null
insert into @ttLF select 'ModifiedBy',                  null,     -1,   null,               null, null

/* Deprecated */
insert into @ttLF select 'Description',                 null,     -2,   null,               null, null
insert into @ttLF select 'DisplayDescription',          null,     -2,   null,               null, null

/* Add Fields to Standard Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName,'RecordId;ShipVia'/* Key fields */;

/******************************************************************************/
/* Summary Layouts Details */
/******************************************************************************/

/*----------------------------------------------------------------------------*/

/******************************************************************************/
/* Summary Fields Setup */
/******************************************************************************/

Go
