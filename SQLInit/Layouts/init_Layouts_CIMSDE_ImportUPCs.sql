/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/05/23  RKC     Initial revision (CIMSV3-550).
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

select @ContextName = 'List.CIMSDE_ImportUPCs',
       @DataSetName = 'vwCIMSDE_ImportUPCs';

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
insert into @ttLF select 'SKUId',                       null,   null,   null,               null, null

insert into @ttLF select 'Description',                 null,   null,   null,               null, null
insert into @ttLF select 'SKU1Description',             null,   null,   null,               null, null
insert into @ttLF select 'SKU2Description',             null,   null,   null,               null, null
insert into @ttLF select 'SKU3Description',             null,   null,   null,               null, null
insert into @ttLF select 'SKU4Description',             null,   null,   null,               null, null
insert into @ttLF select 'SKU5Description',             null,   null,   null,               null, null
insert into @ttLF select 'UPC',                         null,   null,   null,               null, null

insert into @ttLF select 'Status',                      null,   null,   null,               null, null
insert into @ttLF select 'AlternateSKU',                null,   null,   null,               null, null
insert into @ttLF select 'UoM',                         null,   null,   null,               null, null

insert into @ttLF select 'InnerPacksPerLPN',            null,   null,   null,               null, null
insert into @ttLF select 'UnitsPerInnerPack',           null,   null,   null,               null, null
insert into @ttLF select 'UnitsPerLPN',                 null,   null,   null,               null, null

insert into @ttLF select 'InnerPackWeight',             null,   null,   null,               null, null
insert into @ttLF select 'InnerPackLength',             null,   null,   null,               null, null
insert into @ttLF select 'InnerPackWidth',              null,   null,   null,               null, null
insert into @ttLF select 'InnerPackHeight',             null,   null,   null,               null, null
insert into @ttLF select 'InnerPackVolume',             null,   null,   null,               null, null

insert into @ttLF select 'UnitWeight',                  null,   null,   null,               null, null
insert into @ttLF select 'UnitLength',                  null,   null,   null,               null, null
insert into @ttLF select 'UnitWidth',                   null,   null,   null,               null, null
insert into @ttLF select 'UnitHeight',                  null,   null,   null,               null, null
insert into @ttLF select 'UnitVolume',                  null,   null,   null,               null, null
insert into @ttLF select 'UnitPrice',                   null,   null,   null,               null, null

insert into @ttLF select 'Barcode',                     null,   null,   null,               null, null
insert into @ttLF select 'SourceSystem',                null,   null,   null,               null, null

insert into @ttLF select 'Brand',                       null,   null,   null,               null, null
insert into @ttLF select 'ProdCategory',                null,   null,   null,               null, null
insert into @ttLF select 'ProdSubCategory',             null,   null,   null,               null, null
insert into @ttLF select 'ABCClass',                    null,   null,   null,               null, null

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
insert into @ttLF select 'UDF11',                       null,   null,   null,               null, null
insert into @ttLF select 'UDF12',                       null,   null,   null,               null, null
insert into @ttLF select 'UDF13',                       null,   null,   null,               null, null
insert into @ttLF select 'UDF14',                       null,   null,   null,               null, null
insert into @ttLF select 'UDF15',                       null,   null,   null,               null, null
insert into @ttLF select 'UDF16',                       null,   null,   null,               null, null
insert into @ttLF select 'UDF17',                       null,   null,   null,               null, null
insert into @ttLF select 'UDF18',                       null,   null,   null,               null, null
insert into @ttLF select 'UDF19',                       null,   null,   null,               null, null
insert into @ttLF select 'UDF20',                       null,   null,   null,               null, null
insert into @ttLF select 'UDF21',                       null,   null,   null,               null, null
insert into @ttLF select 'UDF22',                       null,   null,   null,               null, null
insert into @ttLF select 'UDF23',                       null,   null,   null,               null, null
insert into @ttLF select 'UDF24',                       null,   null,   null,               null, null
insert into @ttLF select 'UDF25',                       null,   null,   null,               null, null
insert into @ttLF select 'UDF26',                       null,   null,   null,               null, null
insert into @ttLF select 'UDF27',                       null,   null,   null,               null, null
insert into @ttLF select 'UDF28',                       null,   null,   null,               null, null
insert into @ttLF select 'UDF29',                       null,   null,   null,               null, null
insert into @ttLF select 'UDF30',                       null,   null,   null,               null, null

insert into @ttLF select 'BusinessUnit',                null,   null,   null,               null, null
insert into @ttLF select 'CreatedDate',                 null,   null,   null,               null, null
insert into @ttLF select 'ModifiedDate',                null,   null,   null,               null, null
insert into @ttLF select 'CreatedBy',                   null,   null,   null,               null, null
insert into @ttLF select 'ModifiedBy',                  null,   null,   null,               null, null

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
