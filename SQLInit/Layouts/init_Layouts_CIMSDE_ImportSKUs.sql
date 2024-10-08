/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/09/30  SAK     Changed visibility as 11 for RecordId field (JL-147)
  2020/03/06  SJ      Changed Visible for ExchangeStatus (JL-48)
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

select @ContextName = 'List.CIMSDE_ImportSKUs',
       @DataSetName = 'vwCIMSDE_ImportSKUs';

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

insert into @ttLF select 'SKU',                         null,   null,   null,               null, null
insert into @ttLF select 'SKU1',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU2',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU3',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU4',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU5',                        null,   null,   null,               null, null
insert into @ttLF select 'Description',                 null,   null,   null,               null, null
insert into @ttLF select 'SKU1Description',             null,   null,   null,               null, null
insert into @ttLF select 'SKU2Description',             null,   null,   null,               null, null
insert into @ttLF select 'SKU3Description',             null,   null,   null,               null, null
insert into @ttLF select 'SKU4Description',             null,   null,   null,               null, null
insert into @ttLF select 'SKU5Description',             null,   null,   null,               null, null
insert into @ttLF select 'UPC',                         null,   null,   null,               null, null
insert into @ttLF select 'CaseUPC',                     null,   null,   null,               null, null

insert into @ttLF select 'Status',                      null,      1,   null,               null, null
insert into @ttLF select 'UoM',                         null,   null,   null,               null, null

insert into @ttLF select 'InnerPacksPerLPN',            null,   null,   null,               null, null
insert into @ttLF select 'UnitsPerInnerPack',           null,   null,   null,               null, null
insert into @ttLF select 'UnitsPerLPN',                 null,   null,   null,               null, null

insert into @ttLF select 'InnerPackWeight',             null,   null,   null,               null, null
insert into @ttLF select 'InnerPackVolume',             null,   null,   null,               null, null
insert into @ttLF select 'InnerPackLength',             null,   null,   null,               null, null
insert into @ttLF select 'InnerPackWidth',              null,   null,   null,               null, null
insert into @ttLF select 'InnerPackHeight',             null,   null,   null,               null, null
insert into @ttLF select 'UnitWeight',                  null,      1,   null,               null, null
insert into @ttLF select 'UnitVolume',                  null,      1,   null,               null, null
insert into @ttLF select 'UnitLength',                  null,   null,   null,               null, null
insert into @ttLF select 'UnitWidth',                   null,   null,   null,               null, null
insert into @ttLF select 'UnitHeight',                  null,   null,   null,               null, null

insert into @ttLF select 'ProdCategory',                null,   null,   null,               null, null
insert into @ttLF select 'ProdSubCategory',             null,   null,   null,               null, null
insert into @ttLF select 'PutawayClass',                null,   null,   null,               null, null
insert into @ttLF select 'ABCClass',                    null,   null,   null,               null, null

insert into @ttLF select 'NestingFactor',               null,   null,   null,               null, null
insert into @ttLF select 'UnitPrice',                   null,   null,   null,               null, null
insert into @ttLF select 'UnitCost',                    null,   null,   null,               null, null
insert into @ttLF select 'PalletTie',                   null,   null,   null,               null, null
insert into @ttLF select 'PalletHigh',                  null,   null,   null,               null, null
insert into @ttLF select 'PickUoM',                     null,   null,   null,               null, null
insert into @ttLF select 'ShipUoM',                     null,   null,   null,               null, null
insert into @ttLF select 'ShipPack',                    null,   null,   null,               null, null

insert into @ttLF select 'SKUSortOrder',                null,   null,   null,               null, null
insert into @ttLF select 'AlternateSKU',                null,   null,   null,               null, null
insert into @ttLF select 'Barcode',                     null,   null,   null,               null, null
insert into @ttLF select 'Brand',                       null,   null,   null,               null, null

insert into @ttLF select 'NMFC',                        null,   null,   null,               null, null
insert into @ttLF select 'HarmonizedCode',              null,   null,   null,               null, null
insert into @ttLF select 'Serialized',                  null,   null,   null,               null, null

insert into @ttLF select 'Ownership',                   null,   null,   null,               null, null
insert into @ttLF select 'DefaultCoO',                  null,   null,   null,               null, null
insert into @ttLF select 'CartonGroup',                 null,   null,   null,               null, null

insert into @ttLF select 'IsSortable',                  null,   null,   null,               null, null
insert into @ttLF select 'IsConveyable',                null,   null,   null,               null, null
insert into @ttLF select 'IsScannable',                 null,   null,   null,               null, null

insert into @ttLF select 'SKUId',                       null,   null,   null,               null, null

insert into @ttLF select 'SKU_UDF1',                    null,   null,   null,               null, null
insert into @ttLF select 'SKU_UDF2',                    null,   null,   null,               null, null
insert into @ttLF select 'SKU_UDF3',                    null,   null,   null,               null, null
insert into @ttLF select 'SKU_UDF4',                    null,   null,   null,               null, null
insert into @ttLF select 'SKU_UDF5',                    null,   null,   null,               null, null
insert into @ttLF select 'SKU_UDF6',                    null,   null,   null,               null, null
insert into @ttLF select 'SKU_UDF7',                    null,   null,   null,               null, null
insert into @ttLF select 'SKU_UDF8',                    null,   null,   null,               null, null
insert into @ttLF select 'SKU_UDF9',                    null,   null,   null,               null, null
insert into @ttLF select 'SKU_UDF10',                   null,   null,   null,               null, null
insert into @ttLF select 'SKU_UDF11',                   null,   null,   null,               null, null
insert into @ttLF select 'SKU_UDF12',                   null,   null,   null,               null, null
insert into @ttLF select 'SKU_UDF13',                   null,   null,   null,               null, null
insert into @ttLF select 'SKU_UDF14',                   null,   null,   null,               null, null
insert into @ttLF select 'SKU_UDF15',                   null,   null,   null,               null, null
insert into @ttLF select 'SKU_UDF16',                   null,   null,   null,               null, null
insert into @ttLF select 'SKU_UDF17',                   null,   null,   null,               null, null
insert into @ttLF select 'SKU_UDF18',                   null,   null,   null,               null, null
insert into @ttLF select 'SKU_UDF19',                   null,   null,   null,               null, null
insert into @ttLF select 'SKU_UDF20',                   null,   null,   null,               null, null
insert into @ttLF select 'SKU_UDF21',                   null,   null,   null,               null, null
insert into @ttLF select 'SKU_UDF22',                   null,   null,   null,               null, null
insert into @ttLF select 'SKU_UDF23',                   null,   null,   null,               null, null
insert into @ttLF select 'SKU_UDF24',                   null,   null,   null,               null, null
insert into @ttLF select 'SKU_UDF25',                   null,   null,   null,               null, null
insert into @ttLF select 'SKU_UDF26',                   null,   null,   null,               null, null
insert into @ttLF select 'SKU_UDF27',                   null,   null,   null,               null, null
insert into @ttLF select 'SKU_UDF28',                   null,   null,   null,               null, null
insert into @ttLF select 'SKU_UDF29',                   null,   null,   null,               null, null
insert into @ttLF select 'SKU_UDF30',                   null,   null,   null,               null, null

insert into @ttLF select 'SourceSystem',                null,   null,   null,               null, null
insert into @ttLF select 'BusinessUnit',                null,   null,   null,               null, null
insert into @ttLF select 'CreatedDate',                 null,   null,   null,               null, null
insert into @ttLF select 'ModifiedDate',                null,   null,   null,               null, null
insert into @ttLF select 'CreatedBy',                   null,   null,   null,               null, null
insert into @ttLF select 'ModifiedBy',                  null,   null,   null,               null, null

insert into @ttLF select 'InputXML',                    null,   null,   null,               null, null
insert into @ttLF select 'ResultXML',                   null,   null,   null,               null, null

insert into @ttLF select 'HostRecId',                   null,      1,   null,               null, null
insert into @ttLF select 'RecordId',                    null,     11,   null,               null, null
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
