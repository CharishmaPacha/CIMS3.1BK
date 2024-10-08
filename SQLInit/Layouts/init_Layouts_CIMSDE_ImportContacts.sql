/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/09/30  SAK     Changed visibility as 11 for RecordId field (JL-147)
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

select @ContextName = 'List.CIMSDE_ImportContacts',
       @DataSetName = 'vwCIMSDE_ImportContacts';

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

insert into @ttLF select 'ContactId',                   null,   null,   null,               null, null

insert into @ttLF select 'ContactRefId',                null,   null,   null,               null, null
insert into @ttLF select 'ContactType',                 null,   null,   null,               null, null
insert into @ttLF select 'Name',                        null,   null,   null,               null, null
insert into @ttLF select 'AddressLine1',                null,   null,   null,               null, null
insert into @ttLF select 'AddressLine2',                null,   null,   null,               null, null
insert into @ttLF select 'AddressLine3',                null,      1,   null,               null, null
insert into @ttLF select 'City',                        null,   null,   null,               null, null
insert into @ttLF select 'State',                       null,   null,   null,               null, null
insert into @ttLF select 'PhoneNo',                     null,   null,   null,               null, null
insert into @ttLF select 'Email',                       null,   null,   null,               null, null
insert into @ttLF select 'AddressReference1',           null,   null,   null,               null, null
insert into @ttLF select 'AddressReference2',           null,   null,   null,               null, null

insert into @ttLF select 'Residential',                 null,   null,   null,               null, null

insert into @ttLF select 'ContactPerson',               null,   null,   null,               null, null
insert into @ttLF select 'PrimaryContactRefId',         null,   null,   null,               null, null

insert into @ttLF select 'OrganizationContactRefId',    null,   null,   null,               null, null

insert into @ttLF select 'ContactAddrId',               null,   null,   null,               null, null
insert into @ttLF select 'OrgAddrId',                   null,   null,   null,               null, null

insert into @ttLF select 'Country',                     null,   null,   null,               null, null
insert into @ttLF select 'Zip',                         null,   null,   null,               null, null

insert into @ttLF select 'CT_UDF1',                     null,   null,   null,               null, null
insert into @ttLF select 'CT_UDF2',                     null,   null,   null,               null, null
insert into @ttLF select 'CT_UDF3',                     null,   null,   null,               null, null
insert into @ttLF select 'CT_UDF4',                     null,   null,   null,               null, null
insert into @ttLF select 'CT_UDF5',                     null,   null,   null,               null, null

insert into @ttLF select 'SourceSystem',                null,   null,   null,               null, null
insert into @ttLF select 'BusinessUnit',                null,   null,   null,               null, null
insert into @ttLF select 'CreatedDate',                 null,   null,   null,               null, null
insert into @ttLF select 'ModifiedDate',                null,   null,   null,               null, null
insert into @ttLF select 'CreatedBy',                   null,   null,   null,               null, null
insert into @ttLF select 'ModifiedBy',                  null,   null,   null,               null, null

insert into @ttLF select 'InputXML',                    null,   null,   null,               null, null
insert into @ttLF select 'ResultXML',                   null,   null,   null,               null, null

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
