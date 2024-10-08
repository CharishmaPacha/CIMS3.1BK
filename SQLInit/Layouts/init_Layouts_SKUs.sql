/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/02/04  AJM     Added NestingFactor, PickMultiple, PrimaryPickZone, SecondaryPickZone, NMFC, HarmonizedCode, IsBaggable, SKUSortOrder, DefaultCoO, Archived (CIMSV3-1334)
  2020/12/30  PKK     Corrected the file as per template (CIMSV-1282)
  2020/05/22  AJ      Changed the visibility for the Status fields to fix duplicate fields display in selections (HA-489)
  2020/04/15  SJ      Added case dimensions fields in SKU Dimensions layout (HA-130)
  2020/04/14  SJ      Changed visible for SKUs Case Dimensions (HA-130)
  2020/04/08  RKC     Added SKU Pack Configurations layout (HA-138)
  2020/04/06  OK      Added V3 status fields (HA-132)
  2019/05/30  VM      SKU FieldVisible set to 1 (OB2-774)
  2019/05/14  RKC     File organized to be in compliance with latest template init_Layouts_Template.sql (CIMSV3-537)
  2017/09/29  YJ      pr_Setup_Layout: Change to setup Layouts using procedure (CIMSV3-73)
  2017/09/29  YJ      Initial revision.
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

select @ContextName = 'List.SKUs',
       @DataSetName = 'vwSKUs';

/******************************************************************************/
/* Layouts */
/******************************************************************************/
delete from @Layouts;

/*                          Layout  Default  Layout                           Default               Status Visible SortSeq ShowExpanded
                            Type    Layout   Description                      SelectionName                                   */
insert into @Layouts select 'L',    'N',     'Standard',                      null,                 null,  null,   0,      null
insert into @Layouts select 'L',    'N',     'SKU Dimensions',                null,                 null,  null,   0,      null
insert into @Layouts select 'L',    'N',     'SKU Pack Configurations',       null,                 null,  null,   0,      null

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
insert into @ttLF select 'SKUId',                       null,   null,   null,               null, null
/* V3 Key fields cannot be set to invisible. Some V2 clients like OB set this to invisible in fields as they do not need to see SKU */
insert into @ttLF select 'SKU',                            1,   null,   null,               null, null
insert into @ttLF select 'SKU1',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU2',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU3',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU4',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU5',                        null,   null,   null,               null, null

insert into @ttLF select 'Description',                 null,   null,   null,                250, null
insert into @ttLF select 'SKU1Description',             null,   null,   null,               null, null
insert into @ttLF select 'SKU2Description',             null,   null,   null,               null, null
insert into @ttLF select 'SKU3Description',             null,   null,   null,               null, null
insert into @ttLF select 'SKU4Description',             null,   null,   null,               null, null
insert into @ttLF select 'SKU5Description',             null,   null,   null,               null, null

insert into @ttLF select 'SKUStatus',                   null,   null,   null,               null, null
insert into @ttLF select 'SKUStatusDesc',               null,   null,   null,               null, null

insert into @ttLF select 'UPC',                         null,      1,   null,               null, null   -- by default we disable UPC for GNC, hence enabled here
insert into @ttLF select 'UoM',                         null,   null,   null,               null, null

insert into @ttLF select 'InnerPacksPerLPN',            null,   null,   null,               null, null
insert into @ttLF select 'UnitsPerInnerPack',           null,   null,   null,               null, null
insert into @ttLF select 'UnitsPerLPN',                 null,   null,   null,               null, null

insert into @ttLF select 'ProdCategory',                null,   null,   null,               null, null
insert into @ttLF select 'ProdCategoryDesc',            null,   null,   null,               null, null
insert into @ttLF select 'ProdSubCategory',             null,   null,   null,               null, null
insert into @ttLF select 'ProdSubCategoryDesc',         null,   null,   null,               null, null

insert into @ttLF select 'InnerPackWeight',             null,   null,   null,               null, null
insert into @ttLF select 'InnerPackLength',             null,   null,   null,               null, null
insert into @ttLF select 'InnerPackWidth',              null,   null,   null,               null, null
insert into @ttLF select 'InnerPackHeight',             null,   null,   null,               null, null
insert into @ttLF select 'InnerPackVolume',             null,   null,   null,               null, null

insert into @ttLF select 'PalletTie',                   null,   null,   null,               null, null
insert into @ttLF select 'PalletHigh',                  null,   null,   null,               null, null

insert into @ttLF select 'UnitPrice',                   null,   null,   null,               null, null
insert into @ttLF select 'UnitCost',                    null,   null,   null,               null, null
insert into @ttLF select 'UnitLength',                  null,   null,   null,               null, null
insert into @ttLF select 'UnitWidth',                   null,   null,   null,               null, null
insert into @ttLF select 'UnitHeight',                  null,   null,   null,               null, null
insert into @ttLF select 'UnitWeight',                  null,   null,   null,               null, null
insert into @ttLF select 'UnitVolume',                  null,   null,   null,               null, null
insert into @ttLF select 'NestingFactor',               null,   null,   null,               null, null
insert into @ttLF select 'ABCClass',                    null,   null,   null,               null, null
insert into @ttLF select 'ReplenishClass',              null,   null,   null,               null, null
insert into @ttLF select 'ReplenishClassDesc',          null,   null,   null,               null, null
insert into @ttLF select 'ReplenishClassDisplayDesc',   null,   null,   null,               null, null

insert into @ttLF select 'PrimaryPickZone',             null,   null,   null,               null, null
insert into @ttLF select 'SecondaryPickZone',           null,   null,   null,               null, null

insert into @ttLF select 'NMFC',                        null,   null,   null,               null, null
insert into @ttLF select 'HarmonizedCode',              null,   null,   null,               null, null

insert into @ttLF select 'Barcode',                     null,     -1,   null,               null, null
insert into @ttLF select 'Brand',                       null,   null,   null,               null, null
insert into @ttLF select 'AlternateSKU',                null,   null,   null,               null, null
insert into @ttLF select 'SKUImageURL',                 null,   null,   null,               null, null

insert into @ttLF select 'PutawayClass',                null,   null,   null,               null, null
insert into @ttLF select 'PutawayClassDesc',            null,   null,   null,               null, null
insert into @ttLF select 'PutawayClassDisplayDesc',     null,   null,   null,               null, null

insert into @ttLF select 'IsSortable',                  null,   null,   null,               null, null
insert into @ttLF select 'IsConveyable',                null,   null,   null,               null, null
insert into @ttLF select 'IsScannable',                 null,   null,   null,               null, null
insert into @ttLF select 'IsBaggable',                  null,   null,   null,               null, null
insert into @ttLF select 'SKUSortOrder',                null,   null,   null,               null, null
insert into @ttLF select 'Ownership',                   null,   null,   null,               null, null
insert into @ttLF select 'DefaultCoO',                  null,   null,   null,               null, null

insert into @ttLF select 'PickUoM',                     null,   null,   null,               null, null
insert into @ttLF select 'ShipUoM',                     null,   null,   null,               null, null
insert into @ttLF select 'PickMultiple',                null,   null,   null,               null, null
insert into @ttLF select 'ShipPack',                    null,   null,   null,               null, null
insert into @ttLF select 'Serialized',                  null,   null,   null,               null, null

insert into @ttLF select 'UDF1',                        null,   null,   null,               null, null
insert into @ttLF select 'UDF2',                        null,   null,   null,               null, null
insert into @ttLF select 'UDF3',                        null,   null,   null,               null, null
insert into @ttLF select 'UDF4',                        null,   null,   null,               null, null
insert into @ttLF select 'UDF5',                        null,   null,   null,               null, null
insert into @ttLF select 'UDF6',                        null,   null,   null,               null, null
insert into @ttLF select 'UDF7',                        null,   null,   null,               null, null
insert into @ttLF select 'UDF8',                        null,   null,   null,               null, null
insert into @ttLF select 'UDF9',                        null,   null,   null,               null, null
insert into @ttLF select 'UDF10',                       null,   null,   null,               null, null

insert into @ttLF select 'Archived',                    null,   null,   null,               null, null
insert into @ttLF select 'Businessunit',                null,   null,   null,               null, null
insert into @ttLF select 'ModifiedDate',                null,   null,   null,               null, null
insert into @ttLF select 'ModifiedBy',                  null,   null,   null,               null, null
insert into @ttLF select 'CreatedDate',                 null,   null,   null,               null, null
insert into @ttLF select 'CreatedBy',                   null,   null,   null,               null, null

insert into @ttLF select 'Status',                      null,    -20,   null,               null, null -- FieldVisible = -2 and IsSelectable = Y
insert into @ttLF select 'StatusDescription',           null,    -20,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'SKUId;SKU' /* Key fields */;

/*----------------------------------------------------------------------------*/
/*                        FieldName,           SummaryType, DisplayFormat,           AggregateMethod */
--insert into @ttLSF select 'SKU',               'Count',     '# SKUs:{0:n0}',         null

/*
   By default the summary on key fields is always included, so don't need to do this. If there are other
   fields to setup summary for then do so above
*/
--exec pr_Setup_LayoutSummaryFields @ContextName, null /* LayoutDescription */, @ttLSF;

/******************************************************************************/
/* Listing Layouts Details */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
/* Layout Fields for Standard Layout */
/*----------------------------------------------------------------------------*/
delete from @ttLF;

/*                        Field                         Visible Visible Field               Width Display
                          Name                          Index           Caption                   Format */
insert into @ttLF select 'SKU',                            1,   null,   null,               null, null
insert into @ttLF select 'SKU1',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU2',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU3',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU4',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU5',                        null,   null,   null,               null, null

insert into @ttLF select 'Description',                 null,   null,   null,               null, null

insert into @ttLF select 'PutawayClass',                null,   null,   null,               null, null
insert into @ttLF select 'PutawayClassDesc',            null,   null,   null,               null, null

insert into @ttLF select 'UnitLength',                  null,      1,   null,               null, null
insert into @ttLF select 'UnitWidth',                   null,      1,   null,               null, null
insert into @ttLF select 'UnitHeight',                  null,      1,   null,               null, null
insert into @ttLF select 'UnitVolume',                  null,      1,   null,               null, null
insert into @ttLF select 'UnitWeight',                  null,      1,   null,               null, null

insert into @ttLF select 'InnerPackWeight',             null,     -1,   null,               null, null
insert into @ttLF select 'InnerPackLength',             null,     -1,   null,               null, null
insert into @ttLF select 'InnerPackWidth',              null,     -1,   null,               null, null
insert into @ttLF select 'InnerPackHeight',             null,     -1,   null,               null, null
insert into @ttLF select 'InnerPackVolume',             null,     -1,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'SKU Dimensions', @ttLF;

/******************************************************************************/
/* Listing Layouts Details */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
/* Layout Fields for SKU Pack Configurations Layout */
/*----------------------------------------------------------------------------*/
delete from @ttLF;

/*                        Field                         Visible Visible Field               Width Display
                          Name                          Index           Caption                   Format */
insert into @ttLF select 'SKU',                            1,   null,   null,               null, null
insert into @ttLF select 'SKU1',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU2',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU3',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU4',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU5',                        null,   null,   null,               null, null

insert into @ttLF select 'Description',                 null,   null,   null,               null, null

insert into @ttLF select 'InnerPacksPerLPN',            null,      1,   null,               null, null
insert into @ttLF select 'UnitsPerInnerPack',           null,      1,   null,               null, null
insert into @ttLF select 'UnitsPerLPN',                 null,      1,   null,               null, null

insert into @ttLF select 'PalletTie',                   null,      1,   null,               null, null
insert into @ttLF select 'PalletHigh',                  null,      1,   null,               null, null

insert into @ttLF select 'PickUoM',                     null,   null,   null,               null, null
insert into @ttLF select 'ShipUoM',                     null,   null,   null,               null, null
insert into @ttLF select 'ShipPack',                    null,   null,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'SKU Pack Configurations', @ttLF;

/******************************************************************************/
/* Summary Layouts Details */
/******************************************************************************/

/*----------------------------------------------------------------------------*/

/******************************************************************************/
/* Summary Fields Setup */
/******************************************************************************/

Go
