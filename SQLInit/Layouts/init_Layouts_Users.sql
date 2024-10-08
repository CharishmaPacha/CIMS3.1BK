/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/04/03  MS      Corrections to Layout
  2020/04/01  MS      Added summary fields
  2020/03/29  MS      Added UserStatus, Warehouse (CIMSV3-467)
  2019/05/14  RKC     File organized to be in compliance with latest template init_Layouts_Template.sql (CIMSV3-537)
  2018/02/02  KSK     Initial revision.
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

select @ContextName = 'List.Users',
       @DataSetName = 'vwUsers';

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
insert into @ttLF select 'UserId',                      null,   -2,     null,               null, null
insert into @ttLF select 'UserName',                    null,   null,   null,               null, null
insert into @ttLF select 'Password',                    null,   -2,     null,               null, null

insert into @ttLF select 'Name',                        null,    1,     null,               null, null
insert into @ttLF select 'FirstName',                   null,   -1,     null,               null, null
insert into @ttLF select 'LastName',                    null,   -1,     null,               null, null

insert into @ttLF select 'RoleName',                    null,   -2,     null,               null, null
insert into @ttLF select 'RoleDescription',             null,   null,   null,               null, null

insert into @ttLF select 'DefaultWarehouse',            null,   null,   null,               null, null
insert into @ttLF select 'DefaultWarehouseDesc',        null,   null,   null,               null, null
insert into @ttLF select 'UIDefaultPage',               null,   null,   null,               null, null
insert into @ttLF select 'Email',                       null,   -1,     null,               null, null
insert into @ttLF select 'LastLoggedIn',                null,   null,   null,               null, null

insert into @ttLF select 'IsActive',                    null,   -1,     null,               null, null
insert into @ttLF select 'UserStatus',                  null,   null,   null,               null, null
insert into @ttLF select 'StatusDescription',           null,   1,      null,               null, null

insert into @ttLF select 'RoleId',                      null,   -2,     null,               null, null
insert into @ttLF select 'UserRoleId',                  null,   -2,     null,               null, null

insert into @ttLF select 'BusinessUnit',                null,   null,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'UserId;UserName' /* Key fields */;

/******************************************************************************/
/* Summary Layouts Details */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
/******************************************************************************/
/* Summary Fields Setup */
/******************************************************************************/
/*----------------------------------------------------------------------------*/
/*                        FieldName,           SummaryType, DisplayFormat,         AggregateMethod */
insert into @ttLSF select 'UserName',          'Count',     '# Users: {0:n0}',     null

exec pr_Setup_LayoutSummaryFields @ContextName, null /* LayoutDescription */, @ttLSF;

Go
