/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/01/20  PKK     Corrected the file as per the template(CIMSV3-1282)
  2020/06/10  MS      Removed caption for ContactTypeDesc (HA-861)
  2020/05/20  RKC     Added Summary Layout
                      Added ContactTypeDesc field (CIMSV3-195)
  2019/05/14  RKC     File organized to be in compliance with latest template init_Layouts_Template.sql (CIMSV3-537)
  2019/04/26  SPP     Initial revision.
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

select @ContextName = 'List.Contacts',
       @DataSetName = 'vwContacts';

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
insert into @ttLF select 'ContactId',                   null,     -3,   null,               null, null
insert into @ttLF select 'ContactRefId',                null,   null,   null,               null, null
insert into @ttLF select 'ContactType',                 null,   null,   null,               null, null
insert into @ttLF select 'ContactTypeDesc',             null,   null,   null,               null, null
insert into @ttLF select 'Name',                        null,   null,   null,               null, null
insert into @ttLF select 'AddressLine1',                null,   null,   null,               null, null
insert into @ttLF select 'AddressLine2',                null,     -1,   null,               null, null
insert into @ttLF select 'AddressLine3',                null,   null,   null,               null, null
insert into @ttLF select 'City',                        null,     -1,   null,               null, null
insert into @ttLF select 'State',                       null,     -1,   null,               null, null
insert into @ttLF select 'Zip',                         null,     -1,   null,               null, null
insert into @ttLF select 'CityStateZip',                null,      1,   null,               null, null
insert into @ttLF select 'Country',                     null,   null,   null,               null, null

insert into @ttLF select 'PhoneNo',                     null,   null,   null,               null, null
insert into @ttLF select 'Email',                       null,   null,   null,               null, null
insert into @ttLF select 'Reference1',                  null,   null,   null,               null, null
insert into @ttLF select 'Reference2',                  null,   null,   null,               null, null
insert into @ttLF select 'Residential',                 null,   null,   null,               null, null

insert into @ttLF select 'Status',                      null,   null,   null,               null, null

insert into @ttLF select 'ContactPerson',               null,   null,   null,               null, null
insert into @ttLF select 'ContactAddrId',               null,   null,   null,               null, null
insert into @ttLF select 'OrgAddrId',                   null,   null,   null,               null, null
insert into @ttLF select 'AddressRegion',               null,   null,   null,               null, null

insert into @ttLF select 'UDF1',                        null,   null,   null,               null, null
insert into @ttLF select 'UDF2',                        null,   null,   null,               null, null
insert into @ttLF select 'UDF3',                        null,   null,   null,               null, null
insert into @ttLF select 'UDF4',                        null,   null,   null,               null, null
insert into @ttLF select 'UDF5',                        null,   null,   null,               null, null

insert into @ttLF select 'SourceSystem',                null,   null,   null,               null, null
insert into @ttLF select 'BusinessUnit',                null,   null,   null,               null, null
insert into @ttLF select 'ModifiedDate',                null,   null,   null,               null, null
insert into @ttLF select 'ModifiedBy',                  null,   null,   null,               null, null
insert into @ttLF select 'CreatedDate',                 null,   null,   null,               null, null
insert into @ttLF select 'CreatedBy',                   null,   null,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF,@DataSetName, 'ContactId;ContactRefId' /* Key fields */;

/******************************************************************************/
/* Summary Layouts Details */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'Summary by Contact Type & Country';
delete from @ttLFE;

/*                        Field                         Visible Visible Field               Width Display  Aggregate
                          Name                          Index           Caption                   Format   Method */
insert into @ttLFE select 'ContactTypeDesc',            null,      1,   null,               null, null,    null
insert into @ttLFE select 'Country',                    null,      1,   null,               null, null,    null
insert into @ttLFE select 'ContactId',                  null,      1,   'Contacts',         null, null,    'DCount'

exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE;

/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'Summary by Contact Type & State';
delete from @ttLFE;

/*                        Field                         Visible Visible Field               Width Display  Aggregate
                          Name                          Index           Caption                   Format   Method */
insert into @ttLFE select 'ContactTypeDesc',            null,      1,   null,               null, null,    null
insert into @ttLFE select 'State',                      null,      1,   null,               null, null,    null
insert into @ttLFE select 'ContactId',                  null,      1,   'Contacts',         null, null,    'DCount'

exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE;

/******************************************************************************/
/* Summary Fields Setup */
/******************************************************************************/

Go
