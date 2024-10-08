/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/03/30  TK      Added RolePermissionKey as EntityKey field (HA-69)
  2019/04/26  PHK     Initial revision.
------------------------------------------------------------------------------*/

Go

declare @ContextName  TName,
        @DataSetName  TName,
        @BusinessUnit TBusinessUnit;

declare @ttLayouts    TLayoutTable,
        @ttLF         TLayoutFieldsTable;

select @ContextName = 'List.RolePermissions',
       @DataSetName = 'vwActiveUIRolePermissions';

/*------------------------------------------------------------------------------*/
/* Lists.Roles */
/*------------------------------------------------------------------------------*/
/*                            Layout  Default  Layout                        Default        Status Visible SortSeq ShowExpanded
                              Type    Layout   Description                   SelectionName                                      */
insert into @ttLayouts select 'L',    'N',     'Standard',                   null,          null,  null,   0,      null

exec pr_Setup_Layout @ContextName, @DataSetName, @ttLayouts, 'DI' /* Delete & Insert */, 'cimsdba', @BusinessUnit;

/*----------------------------------------------------------------------------*/
/* Layout Fields for Standard Layout */
/*----------------------------------------------------------------------------*/
/*                        Field                         Visible Visible Field               Width Display
                          Name                          Index           Caption                   Format */
insert into @ttLF select 'RolePermissionKey',           null,   null,   null,               null, null
insert into @ttLF select 'RolePermissionId',            null,   null,   null,               null, null
insert into @ttLF select 'RoleName',                    null,   -2,     null,               null, null
insert into @ttLF select 'RoleDescription',             null,   null,   null,               null, null

insert into @ttLF select 'Application',                 null,   null,   null,               null, null
insert into @ttLF select 'Operation',                   null,   -2,     null,               null, null
insert into @ttLF select 'OperationDescription',        null,   1,      null,               null, null

insert into @ttLF select 'PermissionName',              null,   -1,     null,               null, null
insert into @ttLF select 'Description',                 null,   1,      'Permission',       null, null

insert into @ttLF select 'IsActive',                    null,   -2,     null,               null, null
insert into @ttLF select 'IsVisible',                   null,   null,   null,               null, null
insert into @ttLF select 'NodeLevel',                   null,   null,   null,               null, null
insert into @ttLF select 'SortSeq',                     null,   -2,     null,               null, null
insert into @ttLF select 'IsAllowed',                   null,   null,   null,               null, null
insert into @ttLF select 'IsAllowedBitValue',           null,   null,   null,               null, null

insert into @ttLF select 'RoleId',                      null,   null,   null,               null, null
insert into @ttLF select 'PermissionId',                null,   null,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, ';RolePermissionKey' /* KeyFields */;

Go
