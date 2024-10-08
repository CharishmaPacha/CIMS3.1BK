/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/10/12  YJ      Added new fields related to ShipTo (HA-1559)
  2020/06/08  RT      Intial Revision
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

select @ContextName = 'List.BoLCarrierDetails',
       @DataSetName = 'vwBoLCarrierDetails';

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
insert into @ttLF select 'BoLCarrierDetailId',          null,     -3,   null,               null, null
insert into @ttLF select 'BoLNumber',                   null,   null,   null,               null, null
insert into @ttLF select 'LoadNumber',                  null,     -1,   null,               null, null

insert into @ttLF select 'ShipTo',                      null,     -1,   null,               null, null
insert into @ttLF select 'ShipToName',                  null,      1,   null,               null, null
insert into @ttLF select 'ShipToCity',                  null,     -1,   null,               null, null
insert into @ttLF select 'ShipToState',                 null,     -1,   null,               null, null
insert into @ttLF select 'ShipToZip',                   null,     -1,   null,               null, null
insert into @ttLF select 'ShipToCityStateZip',          null,     -1,   null,               null, null
insert into @ttLF select 'ShipToCityState',             null,      1,   null,               null, null

insert into @ttLF select 'HandlingUnitQty',             null,   null,   null,               null, null
insert into @ttLF select 'HandlingUnitType',            null,   null,   null,               null, null
insert into @ttLF select 'PackageQty',                  null,   null,   null,               null, null
insert into @ttLF select 'PackageType',                 null,   null,   null,               null, null

insert into @ttLF select 'Volume',                      null,     -1,   null,               null, '{0:n2}'
insert into @ttLF select 'Weight',                      null,      1,   null,               null, '{0:n2}'

insert into @ttLF select 'Hazardous',                   null,   null,   null,               null, null
insert into @ttLF select 'CommDescription',             null,   null,   null,               null, null
insert into @ttLF select 'NMFCCode',                    null,   null,   null,               null, null
insert into @ttLF select 'CommClass',                   null,   null,   null,               null, null

insert into @ttLF select 'BoLId',                       null,     -2,   null,               null, null
insert into @ttLF select 'LoadId',                      null,     -2,   null,               null, null
insert into @ttLF select 'ShipmentId',                  null,     -2,   null,               null, null

insert into @ttLF select 'BCD_UDF1',                    null,   null,   null,               null, null
insert into @ttLF select 'BCD_UDF2',                    null,   null,   null,               null, null
insert into @ttLF select 'BCD_UDF3',                    null,   null,   null,               null, null
insert into @ttLF select 'BCD_UDF4',                    null,   null,   null,               null, null
insert into @ttLF select 'BCD_UDF5',                    null,   null,   null,               null, null

insert into @ttLF select 'vwBCD_UDF1',                  null,   null,   null,               null, null
insert into @ttLF select 'vwBCD_UDF2',                  null,   null,   null,               null, null
insert into @ttLF select 'vwBCD_UDF3',                  null,   null,   null,               null, null
insert into @ttLF select 'vwBCD_UDF4',                  null,   null,   null,               null, null
insert into @ttLF select 'vwBCD_UDF5',                  null,   null,   null,               null, null

insert into @ttLF select 'SortSeq',                     null,   null,   null,               null, null
insert into @ttLF select 'BusinessUnit',                null,   null,   null,               null, null
insert into @ttLF select 'ModifiedDate',                null,   null,   null,               null, null
insert into @ttLF select 'ModifiedBy',                  null,   null,   null,               null, null
insert into @ttLF select 'CreatedDate',                 null,   null,   null,               null, null
insert into @ttLF select 'CreatedBy',                   null,   null,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'BoLCarrierDetailId;BoLCarrierDetailId' /* Key fields */;

Go
