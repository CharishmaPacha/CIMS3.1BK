/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/06/08  SJ      Added Result field for Standard layout (HA-768)
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

select @ContextName = 'List.CIMSDE_ImportOrderDetails',
       @DataSetName = 'vwCIMSDE_ImportOrderDetails';

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

insert into @ttLF select 'OrderDetailId',               null,   null,   null,               null, null

insert into @ttLF select 'OrderId',                     null,   null,   null,               null, null
insert into @ttLF select 'PickTicket',                  null,   null,   null,               null, null

insert into @ttLF select 'HostOrderLine',               null,   null,   null,               null, null
insert into @ttLF select 'ParentHostLineNo',            null,   null,   null,               null, null
insert into @ttLF select 'ParentLineId',                null,   null,   null,               null, null

insert into @ttLF select 'LineType',                    null,   null,   null,               null, null
insert into @ttLF select 'SKU',                         null,   null,   null,               null, null
insert into @ttLF select 'SKUId',                       null,   null,   null,               null, null

insert into @ttLF select 'UnitsOrdered',                null,   null,   null,               null, null
insert into @ttLF select 'UnitsAuthorizedToShip',       null,   null,   null,               null, null

insert into @ttLF select 'OrigUnitsAuthorizedToShip',   null,   null,   null,               null, null

insert into @ttLF select 'UnitsAssigned',               null,   null,   null,               null, null
insert into @ttLF select 'UnitsShipped',                null,   null,   null,               null, null

insert into @ttLF select 'UnitsPerCarton',              null,   null,   null,               null, null
insert into @ttLF select 'UnitsPerInnerPack',           null,   null,   null,               null, null
insert into @ttLF select 'RetailUnitPrice',             null,   null,   null,               null, null
insert into @ttLF select 'UnitSalePrice',               null,   null,   null,               null, null
insert into @ttLF select 'UnitTaxAmount',               null,   null,   null,               null, null

insert into @ttLF select 'Lot',                         null,   null,   null,               null, null
insert into @ttLF select 'CustSKU',                     null,   null,   null,               null, null

insert into @ttLF select 'LocationId',                  null,   null,   null,               null, null
insert into @ttLF select 'Location',                    null,   null,   null,               null, null
insert into @ttLF select 'PickZone',                    null,   null,   null,               null, null

insert into @ttLF select 'DestZone',                    null,   null,   null,               null, null
insert into @ttLF select 'DestLocation',                null,   null,   null,               null, null

insert into @ttLF select 'PickBatchGroup',              null,   null,   null,               null, null
insert into @ttLF select 'PickBatchCategory',           null,   null,   null,               null, null

insert into @ttLF select 'PackingGroup',                null,   null,   null,               null, null

insert into @ttLF select 'OD_UDF1',                     null,   null,   null,               null, null
insert into @ttLF select 'OD_UDF2',                     null,   null,   null,               null, null
insert into @ttLF select 'OD_UDF3',                     null,   null,   null,               null, null
insert into @ttLF select 'OD_UDF4',                     null,   null,   null,               null, null
insert into @ttLF select 'OD_UDF5',                     null,   null,   null,               null, null
insert into @ttLF select 'OD_UDF6',                     null,   null,   null,               null, null
insert into @ttLF select 'OD_UDF7',                     null,   null,   null,               null, null
insert into @ttLF select 'OD_UDF8',                     null,   null,   null,               null, null
insert into @ttLF select 'OD_UDF9',                     null,   null,   null,               null, null
insert into @ttLF select 'OD_UDF10',                    null,   null,   null,               null, null
insert into @ttLF select 'OD_UDF11',                    null,   null,   null,               null, null
insert into @ttLF select 'OD_UDF12',                    null,   null,   null,               null, null
insert into @ttLF select 'OD_UDF13',                    null,   null,   null,               null, null
insert into @ttLF select 'OD_UDF14',                    null,   null,   null,               null, null
insert into @ttLF select 'OD_UDF15',                    null,   null,   null,               null, null
insert into @ttLF select 'OD_UDF16',                    null,   null,   null,               null, null
insert into @ttLF select 'OD_UDF17',                    null,   null,   null,               null, null
insert into @ttLF select 'OD_UDF18',                    null,   null,   null,               null, null
insert into @ttLF select 'OD_UDF19',                    null,   null,   null,               null, null
insert into @ttLF select 'OD_UDF20',                    null,   null,   null,               null, null
insert into @ttLF select 'OD_UDF21',                    null,   null,   null,               null, null
insert into @ttLF select 'OD_UDF22',                    null,   null,   null,               null, null
insert into @ttLF select 'OD_UDF23',                    null,   null,   null,               null, null
insert into @ttLF select 'OD_UDF24',                    null,   null,   null,               null, null
insert into @ttLF select 'OD_UDF25',                    null,   null,   null,               null, null
insert into @ttLF select 'OD_UDF26',                    null,   null,   null,               null, null
insert into @ttLF select 'OD_UDF27',                    null,   null,   null,               null, null
insert into @ttLF select 'OD_UDF28',                    null,   null,   null,               null, null
insert into @ttLF select 'OD_UDF29',                    null,   null,   null,               null, null
insert into @ttLF select 'OD_UDF30',                    null,   null,   null,               null, null

insert into @ttLF select 'OHStatus',                    null,   null,   null,               null, null
insert into @ttLF select 'Ownership',                   null,   null,   null,               null, null

insert into @ttLF select 'InventoryClass1',             null,   null,   null,               null, null
insert into @ttLF select 'InventoryClass2',             null,   null,   null,               null, null
insert into @ttLF select 'InventoryClass3',             null,   null,   null,               null, null

insert into @ttLF select 'BusinessUnit',                null,   null ,  null,               null, null
insert into @ttLF select 'CreatedDate',                 null,   null,   null,               null, null
insert into @ttLF select 'ModifiedDate',                null,   null,   null,               null, null
insert into @ttLF select 'CreatedBy',                   null,   null,   null,               null, null
insert into @ttLF select 'ModifiedBy',                  null,   null,   null,               null, null

insert into @ttLF select 'InputXML',                    null,   null,   null,               null, null
insert into @ttLF select 'ResultXML',                   null,   null,   null,               null, null
insert into @ttLF select 'Result',                      null,      1,   null,               null, null

insert into @ttLF select 'HostRecId',                   null,      1,   null,               null, null
insert into @ttLF select 'RecordId',                    null,      1,   null,               null, null
insert into @ttLF select 'ExchangeStatus',              null,      1,   null,               null, null
insert into @ttLF select 'InsertedTime',                null,      1,   null,               null, null
insert into @ttLF select 'ProcessedTime',               null,      1,   null,               null, null
insert into @ttLF select 'Reference',                   null,   null,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'RecordId;';

/******************************************************************************/
/* Summary Layouts Details */
/******************************************************************************/

/******************************************************************************/
/* Summary Fields Setup */
/******************************************************************************/

Go
