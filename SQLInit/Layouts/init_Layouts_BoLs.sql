/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/12/29  PKK     Corrected the file as per template (CIMSV3-1282)
  2020/06/09  RT      Intial Revision
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

select @ContextName = 'List.BoLs',
       @DataSetName = 'vwBoLs';

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
insert into @ttLF select 'BoLId',                       null,     -3,   null,               null, null
insert into @ttLF select 'BoLNumber',                   null,   null,   null,               null, null
insert into @ttLF select 'VICSBoLNumber',               null,   null,   null,               null, null
insert into @ttLF select 'BoLType',                     null,   null,   null,               null, null
insert into @ttLF select 'BoLTypeDesc',                 null,   null,   null,               null, null
insert into @ttLF select 'MasterBoL',                   null,     -1,   null,               null, null

insert into @ttLF select 'ShipToName',                  null,   null,   null,               null, null
insert into @ttLF select 'ShipToLocation',              null,   null,   null,               null, null
insert into @ttLF select 'FoB',                         null,   null,   null,               null, null
insert into @ttLF select 'BoLCID',                      null,   null,   null,               null, null
insert into @ttLF select 'TrailerNumber',               null,   null,   null,               null, null
insert into @ttLF select 'SealNumber',                  null,   null,   null,               null, null
insert into @ttLF select 'ProNumber',                   null,   null,   null,               null, null
insert into @ttLF select 'FreightTerms',                null,      1,   null,               null, null

insert into @ttLF select 'ShipVia',                     null,     -2,   null,               null, null
insert into @ttLF select 'ShipViaDescription',          null,     -1,   null,               null, null
insert into @ttLF select 'BoLInstructions',             null,   null,   null,               null, null

insert into @ttLF select 'ShipFromAddressId',           null,   null,   null,               null, null
insert into @ttLF select 'ShipToAddressId',             null,      1,   null,               null, null
insert into @ttLF select 'BillToAddressId',             null,      1,   null,               null, null

insert into @ttLF select 'LoadId',                      null,     -1,   null,               null, null
insert into @ttLF select 'LoadNumber',                  null,     -1,   null,               null, null

insert into @ttLF select 'BoL_UDF1',                    null,   null,   null,               null, null
insert into @ttLF select 'BoL_UDF2',                    null,   null,   null,               null, null
insert into @ttLF select 'BoL_UDF3',                    null,   null,   null,               null, null
insert into @ttLF select 'BoL_UDF4',                    null,   null,   null,               null, null
insert into @ttLF select 'BoL_UDF5',                    null,   null,   null,               null, null
insert into @ttLF select 'BoL_UDF6',                    null,   null,   null,               null, null
insert into @ttLF select 'BoL_UDF7',                    null,   null,   null,               null, null
insert into @ttLF select 'BoL_UDF8',                    null,   null,   null,               null, null
insert into @ttLF select 'BoL_UDF9',                    null,   null,   null,               null, null
insert into @ttLF select 'BoL_UDF10',                   null,   null,   null,               null, null

insert into @ttLF select 'BusinessUnit',                null,   null,   null,               null, null
insert into @ttLF select 'ModifiedDate',                null,   null,   null,               null, null
insert into @ttLF select 'ModifiedBy',                  null,   null,   null,               null, null
insert into @ttLF select 'CreatedDate',                 null,   null,   null,               null, null
insert into @ttLF select 'CreatedBy',                   null,   null,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'BoLId;BoLNumber' /* Key fields */;

Go