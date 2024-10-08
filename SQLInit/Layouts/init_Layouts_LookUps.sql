/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/12/29  PKK     Corrected the file as per template (CIMSV3-1282)
  2020/06/16  AJ      Changes to don't show duplicates (HA-489)
  2020/04/28  MS      Changes to select Statuses (HA-293)
  2019/05/14  RBV     File organized to be in compliance with latest template init_Layouts_Template.sql (CIMSV3-537)
  2018/02/01  KSK     Initial revision.
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

select @ContextName = 'List.LookUps',
       @DataSetName = 'vwLookUps';

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
insert into @ttLF select 'RecordId',                    null,   null,   null,               null, null

insert into @ttLF select 'LookUpCategory',              null,   null,   null,               null, null
insert into @ttLF select 'CategoryDesc',                null,   null,   null,               null, null
insert into @ttLF select 'CategoryStatus',              null,     -2,   null,               null, null

insert into @ttLF select 'LookUpCode',                  null,   null,   null,               null, null
insert into @ttLF select 'LookUpDescription',           null,   null,   null,               null, null
insert into @ttLF select 'LookUpDisplayDescription',    null,    -20,   null,               null, null

insert into @ttLF select 'SortSeq',                     null,   null,   null,               null, null
insert into @ttLF select 'Status',                      null,    -21,   null,               null, null
insert into @ttLF select 'StatusDescription',           null,      1,   null,               null, null

insert into @ttLF select 'CategoryActions',             null,   null,   null,               null, null
insert into @ttLF select 'CategorySortSeq',             null,   null,   null,               null, null
insert into @ttLF select 'Visible',                     null,   null,   null,               null, null

insert into @ttLF select 'BusinessUnit',                null,   null,   null,               null, null
insert into @ttLF select 'ModifiedDate',                null,   null,   null,               null, null
insert into @ttLF select 'ModifiedBy',                  null,   null,   null,               null, null
insert into @ttLF select 'CreatedDate',                 null,   null,   null,               null, null
insert into @ttLF select 'CreatedBy',                   null,   null,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF,@DataSetName, 'RecordId;' /* Key fields */;

/******************************************************************************/
/* Summary Layouts Details */
/******************************************************************************/

/*----------------------------------------------------------------------------*/

/******************************************************************************/
/* Summary Fields Setup */
/******************************************************************************/

/*----------------------------------------------------------------------------*/

Go