/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/13  OK      Changed to pass LocationId as EntityKey (HA-2274)
  2021/03/13  SK      Minor changes required for results page (HA-2270)
  2021/03/10  KBB     Added missing Fields from view (HA-2198)
  2021/03/06  KBB     Initial revision(HA-2003)
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

select @ContextName = 'List.CycleCountResults',
       @DataSetName = 'vwCycleCountResults';

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
insert into @ttLF select 'TaskId',                      null,     -1,   null,               null, null
insert into @ttLF select 'TaskDetailId',                null,     -1,   null,               null, null
insert into @ttLF select 'TransactionDate',             null,     -1,   null,               null, null

insert into @ttLF select 'BatchNo',                     null,   null,   'Batch No',         null, null
insert into @ttLF select 'Warehouse',                   null,   null,   null,               null, null
insert into @ttLF select 'Location',                    null,      1,   null,               null, null
insert into @ttLF select 'LocationRow',                 null,   null,   null,               null, null
insert into @ttLF select 'LocationLevel',               null,   null,   null,               null, null
insert into @ttLF select 'LPN',                         null,   null,   null,               null, null
insert into @ttLF select 'SKU',                         null,   null,   null,               null, null
insert into @ttLF select 'SKU1',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU2',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU3',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU4',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU5',                        null,   null,   null,               null, null
insert into @ttLF select 'SKUDesc',                     null,   null,   null,               null, null

insert into @ttLF select 'PrevQuantity',                null,      1,   null,               null, null
insert into @ttLF select 'Quantity1',                   null,   null,   null,               null, null
insert into @ttLF select 'FinalQuantity',               null,      1,   null,               null, null

insert into @ttLF select 'QuantityChange1',             null,   null,   null,               null, null
insert into @ttLF select 'QuantityChange2',             null,   null,   null,               null, null
insert into @ttLF select 'QuantityChange',              null,      1,   null,               null, null
insert into @ttLF select 'AbsQuantityChange',           null,      1,   null,               null, null

insert into @ttLF select 'PercentQtyChange1',           null,   null,   null,               null, null
insert into @ttLF select 'PercentQtyChange2',           null,   null,   null,               null, null
insert into @ttLF select 'PercentQtyChange',            null,   null,   null,               null, null
insert into @ttLF select 'AbsPercentQtyChange',         null,      1,   null,               null, null

insert into @ttLF select 'QtyAccuracy1',                null,   null,   null,               null, null
insert into @ttLF select 'QtyAccuracy2',                null,   null,   null,               null, null
insert into @ttLF select 'QtyAccuracy',                 null,   null,   null,               null, null

insert into @ttLF select 'PrevInnerPacks',              null,   null,   null,               null, null
insert into @ttLF select 'InnerPacks1',                 null,   null,   null,               null, null
insert into @ttLF select 'FinalInnerPacks',             null,   null,   null,               null, null

insert into @ttLF select 'InnerPacksChange1',           null,   null,   null,               null, null
insert into @ttLF select 'InnerPacksChange2',           null,   null,   null,               null, null
insert into @ttLF select 'InnerPacksChange',            null,   null,   null,               null, null

insert into @ttLF select 'PercentIPChange1',            null,   null,   null,               null, null
insert into @ttLF select 'PercentIPChange2',            null,   null,   null,               null, null
insert into @ttLF select 'PercentIPChange',             null,   null,   null,               null, null

insert into @ttLF select 'IPAccuracy1',                 null,   null,   null,               null, null
insert into @ttLF select 'IPAccuracy2',                 null,   null,   null,               null, null
insert into @ttLF select 'IPAccuracy',                  null,   null,   null,               null, null

insert into @ttLF select 'PrevLPNs',                    null,   null,   null,               null, null
insert into @ttLF select 'NumLPNs',                     null,   null,   null,               null, null
insert into @ttLF select 'LPNChange',                   null,     -1,   null,               null, null

insert into @ttLF select 'Pallet',                      null,      1,   null,               null, null
insert into @ttLF select 'PrevPallet',                  null,      1,   null,               null, null
insert into @ttLF select 'PrevLocation',                null,      1,   null,               null, null
insert into @ttLF select 'LocationType',                null,     -1,   null,               null, null
insert into @ttLF select 'LocationTypeDesc',            null,     -1,   null,               null, null
insert into @ttLF select 'StorageType',                 null,     -1,   null,               null, null
insert into @ttLF select 'StorageTypeDesc',             null,     -1,   null,               null, null
insert into @ttLF select 'PickZone',                    null,     -1,   null,               null, null

insert into @ttLF select 'CurrentSKUCount',             null,     -1,   null,               null, null
insert into @ttLF select 'OldSKUCount',                 null,     -1,   null,               null, null

insert into @ttLF select 'SKUVariance',                 null,   null,   null,               null, null
insert into @ttLF select 'SKUVarianceDesc',             null,   null,   null,               null, null
insert into @ttLF select 'UnitCost',                    null,   null,   null,               null, null
insert into @ttLF select 'Variance',                    null,   null,   null,               null, null

/* Internal fields */
insert into @ttLF select 'LPNId',                       null,   null,   null,               null, null
insert into @ttLF select 'LocationId',                  null,   null,   null,               null, null
insert into @ttLF select 'SKUId',                       null,   null,   null,               null, null
insert into @ttLF select 'PrevLocationId',              null,   null,   null,               null, null
insert into @ttLF select 'PalletId',                    null,   null,   null,               null, null
insert into @ttLF select 'PrevPalletId',                null,   null,   null,               null, null
insert into @ttLF select 'UPC',                         null,   null,   null,               null, null

insert into @ttLF select 'vwCCR_UDF1',                  null,   null,   null,               null, null
insert into @ttLF select 'vwCCR_UDF2',                  null,   null,   null,               null, null
insert into @ttLF select 'vwCCR_UDF3',                  null,   null,   null,               null, null
insert into @ttLF select 'vwCCR_UDF4',                  null,   null,   null,               null, null
insert into @ttLF select 'vwCCR_UDF5',                  null,   null,   null,               null, null
insert into @ttLF select 'vwCCR_UDF6',                  null,   null,   null,               null, null
insert into @ttLF select 'vwCCR_UDF7',                  null,   null,   null,               null, null
insert into @ttLF select 'vwCCR_UDF8',                  null,   null,   null,               null, null
insert into @ttLF select 'vwCCR_UDF9',                  null,   null,   null,               null, null
insert into @ttLF select 'vwCCR_UDF10',                 null,   null,   null,               null, null

insert into @ttLF select 'BusinessUnit',                null,   null,   null,               null, null
insert into @ttLF select 'CreatedDate',                 null,   null,   null,               null, null
insert into @ttLF select 'ModifiedDate',                null,   null,   null,               null, null
insert into @ttLF select 'CreatedBy',                   null,   null,   null,               null, null
insert into @ttLF select 'ModifiedBy',                  null,   null,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, ';LocationId' /* Key fields */;

/******************************************************************************/
/* Summary Layouts Details */
/******************************************************************************/

/******************************************************************************/
/* Summary Fields Setup */
/******************************************************************************/

/*----------------------------------------------------------------------------*/

Go
