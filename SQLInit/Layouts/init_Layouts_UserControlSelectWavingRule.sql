/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/05/20  SV      Initial revision (HA-510)
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

/********************************************************************************/
/* Layout for Create Inventory Form */
select @ContextName = 'UserControl.SelectWavingRule';
delete from @Layouts;

/*------------------------------------------------------------------------------*/
/* UserControl.SelectShipVia */
/*------------------------------------------------------------------------------*/
/*                          Layout  Default  Layout                           Default               Status Visible SortSeq ShowExpanded
                            Type    Layout   Description                      SelectionName                                   */
insert into @Layouts select 'L',    'N',     'Standard',                      null,                 'A',   null,   0,      'Y'

exec pr_Setup_Layout @ContextName, null, @Layouts, 'DI' /* Delete & Insert */, 'cimsdba', @BusinessUnit;

/*----------------------------------------------------------------------------*/
/* Layout Fields for Standard Layout */
/*----------------------------------------------------------------------------*/
delete from @ttLF;
/*                        Field               Visible Visible Field          Width Display
                          Name                Index           Caption              Format */
insert into @ttLF select 'SortSeq',           null,      1,    'Seq No',      50,   null
insert into @ttLF select 'RuleId',            null,   null,    null,          null, null
insert into @ttLF select 'BatchingLevel',     null,      1,    null,          70,   null
insert into @ttLF select 'OrderType',         null,   null,    null,          null, null
insert into @ttLF select 'Status',            null,   null,    null,          null, null
insert into @ttLF select 'OrderTypeDescription',
                                              null,   null,    null,          null, null
insert into @ttLF select 'OrderPriority',     null,   null,    null,          80,   null
insert into @ttLF select 'ShipVia',           null,   null,    null,          null, null
insert into @ttLF select 'ShipViaDescription',null,   null,    null,          null, null
insert into @ttLF select 'Carrier',           null,   null,    null,          null, null
insert into @ttLF select 'SoldToId',          null,      1,    null,          null, null
insert into @ttLF select 'SoldToDescription', null,   null,    null,          null, null
insert into @ttLF select 'ShipToId',          null,   null,    null,          null, null
insert into @ttLF select 'ShipToDescription', null,   null,    null,          null, null
insert into @ttLF select 'PickZone'  ,        null,   null,    null,          null, null
insert into @ttLF select 'OrderWeightMin',    null,   null,    'Min Weight',  null, null
insert into @ttLF select 'OrderWeightMax',    null,   null,    'Max Weight',  65,   null
insert into @ttLF select 'OrderVolumeMin',    null,   null,    null,          null, null
insert into @ttLF select 'OrderVolumeMax',    null,   null,    null,          null, null
insert into @ttLF select 'OrderInnerPacks',   null,   null,    null,          null, null
insert into @ttLF select 'OrderUnits',        null,      1,    null,          null, null

insert into @ttLF select 'OH_Category1',      null,      1,    null,          null, null
insert into @ttLF select 'OH_Category2',      null,      1,    null,          null, null
insert into @ttLF select 'OH_Category3',      null,      1,    null,          null, null
insert into @ttLF select 'OH_Category4',      null,   null,    null,          null, null
insert into @ttLF select 'OH_Category5',      null,   null,    null,          null, null

insert into @ttLF select 'OH_UDF1',           null,   null,    null,          null, null
insert into @ttLF select 'OH_UDF2',           null,   null,    null,          null, null
insert into @ttLF select 'OH_UDF3',           null,   null,    null,          null, null
insert into @ttLF select 'OH_UDF4',           null,      1,    null,          null, null
insert into @ttLF select 'OH_UDF5',           null,   null,    null,          null, null

insert into @ttLF select 'BatchType',         null,      1,    'Wave Type',   null, null
insert into @ttLF select 'BatchPriority',     null,   null,    null,          50,   null
insert into @ttLF select 'BatchStatus',       null,   null,    null,          null, null
insert into @ttLF select 'BatchStatusDescription',
                                              null,   null,    null,          null, null
insert into @ttLF select 'BatchTypeDescription',
                                              null,   null,    null,          null, null
insert into @ttLF select 'PickBatchGroup',    null,   null,    null,          null, null
insert into @ttLF select 'OrderDetailWeight', null,   null,   'OD Wgt',       55,   null
insert into @ttLF select 'OrderDetailVolume', null,   null,   'OD Vol',       55,   null
insert into @ttLF select 'PutawayClass',      null,   null,    null,          null, null
insert into @ttLF select 'ProdCategory',      null,   null,    null,          null, null
insert into @ttLF select 'ProdSubCategory',   null,   null,    null,          null, null
insert into @ttLF select 'PutawayZone',       null,   null,    null,          null, null

insert into @ttLF select 'MaxOrders',         null,   null,    null,          null, null
insert into @ttLF select 'MaxLines',          null,   null,    null,          null, null
insert into @ttLF select 'MaxSKUs',           null,   null,    null,          null, null
insert into @ttLF select 'MaxUnits',          null,   null,    null,          null, null
insert into @ttLF select 'MaxWeight',         null,   null,    null,          null, null
insert into @ttLF select 'MaxVolume',         null,   null,    null,          null, null
insert into @ttLF select 'MaxLPNs',           null,   null,    null,          null, null
insert into @ttLF select 'MaxInnerPacks',     null,     -2,    null,          null, null
insert into @ttLF select 'DestZoneDescription',
                                              null,     -2,    null,          null, null
insert into @ttLF select 'DestZoneDisplayDescription',
                                              null,     -2,    null,          null, null
insert into @ttLF select 'DestZone',          null,      1,    null,          null, null
insert into @ttLF select 'DestLocation',      null,   null,    null,          null, null

insert into @ttLF select 'UDF1',              null,   null,    null,          null, null
insert into @ttLF select 'UDF2',              null,   null,    null,          null, null
insert into @ttLF select 'UDF3',              null,   null,    null,          null, null
insert into @ttLF select 'UDF4',              null,   null,    null,          null, null
insert into @ttLF select 'UDF5',              null,   null,    null,          null, null

insert into @ttLF select 'VersionId',         null,   null,    null,          null, null
insert into @ttLF select 'BusinessUnit',      null,   null,    null,          null, null
insert into @ttLF select 'Ownership',         null,   null,    null,          null, null
insert into @ttLF select 'Warehouse',         null,      1,    null,          null, null

insert into @ttLF select 'ModifiedDate',      null,   null,    null,          null, null
insert into @ttLF select 'ModifiedBy',        null,   null,    null,          null, null
insert into @ttLF select 'CreatedDate',       null,   null,    null,          null, null
insert into @ttLF select 'CreatedBy',         null,   null,    null,          null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF;

Go
