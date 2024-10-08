/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/12/29  PKK     Corrected the files as per template (CIMSV3-1282)
  2020/05/15  RKC     Changed the Visible & FieldName for some of the fields (HA-451)
  2019/05/28  SPP     Corrected Layouts (CIMSV3-485)
  2019/04/24  YJ      Initial revision.
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

select @ContextName = 'List.PutawayRules',
       @DataSetName = 'vwPutawayRules';

/******************************************************************************/
/* Layouts */
/******************************************************************************/
delete from @Layouts;

/*                          Layout  Default  Layout                           Default               Status Visible SortSeq ShowExpanded
                            Type    Layout   Description                      SelectionName                                          */
insert into @Layouts select 'L',    'N',     'Standard',                      null,                 null,  null,   0,      null

exec pr_Setup_Layout @ContextName, @DataSetName, @Layouts, 'DI' /* Delete & Insert */, 'cimsdba', @BusinessUnit;

/******************************************************************************/
/* Listing Layouts Details */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
/* Layout Fields for Standard Layout */
/*----------------------------------------------------------------------------*/
delete from @ttLF;

/*                        Field                                Visible Visible Field               Width Display
                          Name                                 Index           Caption                   Format */
insert into @ttLF select 'RecordId',                           null,   null,   null,               null, null
insert into @ttLF select 'SequenceNo',                         null,   null,   null,               null, null

insert into @ttLF select 'PAType',                             null,   null,   null,               null, null
insert into @ttLF select 'PATypeDescription',                  null,   null,   null,               null, null

insert into @ttLF select 'SKUPutawayClass',                    null,     -2,   null,               null, null
insert into @ttLF select 'SKUPutawayClassDescription',         null,     -2,   null,               null, null
insert into @ttLF select 'SKUPutawayClassDisplayDescription',  null,      1,   null,               null, null

insert into @ttLF select 'LPNPutawayClass',                    null,      1,   null,               null,  null
insert into @ttLF select 'PalletPutawayClass',                 null,     -1,   null,               null,  null

insert into @ttLF select 'PutawayZone',                        null,      1,   null,               null, null
insert into @ttLF select 'PutawayZoneDesc',                    null,     -2,   null,               null, null
insert into @ttLF select 'PutawayZoneDisplayDesc',             null,     -2,   null,               null, null

insert into @ttLF select 'LPNType',                            null,     -2,   'LPN Type',         null, null
insert into @ttLF select 'LPNTypeDescription',                 null,     -1,   null,               null, null

insert into @ttLF select 'PalletType',                         null,     -2,   null,               null, null
insert into @ttLF select 'PalletTypeDescription',              null,     -1,   null,               null, null

insert into @ttLF select 'Warehouse',                          null,   null,   null,               null, null
insert into @ttLF select 'LocationClass',                      null,     -1,   null,               null, null
insert into @ttLF select 'LocationType',                       null,     -2,   null,               null, null
insert into @ttLF select 'LocationTypeDesc',                   null,      1,   null,               null, null
insert into @ttLF select 'StorageType',                        null,     -2,   null,               null, null
insert into @ttLF select 'StorageTypeDesc',                    null,      1,   null,               null, null
insert into @ttLF select 'LocationStatus',                     null,     -2,   null,               null, null
insert into @ttLF select 'LocationStatusDesc',                 null,      1,   null,               null, null
insert into @ttLF select 'Location',                           null,     -1,   null,               null, null

insert into @ttLF select 'SKUExists',                          null,   null,   null,               null, null

insert into @ttLF select 'Status',                             null,     -2,   null,               null, null
insert into @ttLF select 'StatusDescription',                  null,      1,   null,               null, null

insert into @ttLF select 'BusinessUnit',                       null,   null,   null,               null, null
insert into @ttLF select 'ModifiedDate',                       null,   null,   null,               null, null
insert into @ttLF select 'ModifiedBy',                         null,   null,   null,               null, null
insert into @ttLF select 'CreatedDate',                        null,   null,   null,               null, null
insert into @ttLF select 'CreatedBy',                          null,   null,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'RecordId;'

Go