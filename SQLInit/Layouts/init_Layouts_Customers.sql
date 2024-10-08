/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/12/23  PKK     Corrected the file as per template (CIMSV3-1282)
  2019/12/18  MS      Layout Corrections (CIMSV3-490)
  2014/07/01  AK      Added fields by comparing with the respective view binded(vwCustomers).
                      Hidden Status (Code) field.
  2013/03/06  VN      Initial revision.
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

select @ContextName = 'List.Customers',
       @DataSetName = 'vwCustomers';

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

insert into @ttLF select 'CustomerId',                  null,      1,   null,               null, null
insert into @ttLF select 'CustomerName',                null,   null,   null,               null, null
insert into @ttLF select 'Status',                      null,     -2,   null,               null, null
insert into @ttLF select 'StatusDescription',           null,   null,   null,               null, null
insert into @ttLF select 'CustAddressLine1',            null,   null,   null,               null, null
insert into @ttLF select 'CustAddressLine2',            null,   null,   null,               null, null
insert into @ttLF select 'CustCity',                    null,   null,   null,               null, null
insert into @ttLF select 'CustState',                   null,   null,   null,               null, null
insert into @ttLF select 'CustZip',                     null,   null,   null,               null, null
insert into @ttLF select 'CustCountry',                 null,   null,   null,               null, null
insert into @ttLF select 'CustPhoneNo',                 null,   null,   null,               null, null
insert into @ttLF select 'CustEmail',                   null,   null,   null,               null, null

insert into @ttLF select 'CustContactPerson',           null,   null,   null,               null, null
insert into @ttLF select 'CustContactAddrId',           null,   null,   null,               null, null
insert into @ttLF select 'CustOrgAddrId',               null,   null,   null,               null, null
insert into @ttLF select 'CustomerContactId',           null,   null,   null,               null, null
insert into @ttLF select 'CustContactRefId',            null,   null,   null,               null, null

insert into @ttLF select 'BillToContactId',             null,   null,   null,               null, null
insert into @ttLF select 'BillToContactRefId',          null,   null,   null,               null, null
insert into @ttLF select 'BillToAddressLine1',          null,   null,   null,               null, null
insert into @ttLF select 'BillToAddressLine2',          null,   null,   null,               null, null
insert into @ttLF select 'BillToCity',                  null,   null,   null,               null, null
insert into @ttLF select 'BillToState',                 null,   null,   null,               null, null
insert into @ttLF select 'BillToZip',                   null,   null,   null,               null, null
insert into @ttLF select 'BillToCountry',               null,   null,   null,               null, null
insert into @ttLF select 'BillToPhoneNo',               null,   null,   null,               null, null
insert into @ttLF select 'BillToEmail',                 null,   null,   null,               null, null

insert into @ttLF select 'BillToContactPerson',         null,   null,   null,               null, null
insert into @ttLF select 'BillToContactAddrId',         null,   null,   null,               null, null
insert into @ttLF select 'BillToOrgAddrId',             null,   null,   null,               null, null

insert into @ttLF select 'UDF1',                        null,   null,   null,               null, null
insert into @ttLF select 'UDF2',                        null,   null,   null,               null, null
insert into @ttLF select 'UDF3',                        null,   null,   null,               null, null
insert into @ttLF select 'UDF4',                        null,   null,   null,               null, null
insert into @ttLF select 'UDF5',                        null,   null,   null,               null, null

insert into @ttLF select 'BusinessUnit',                null,   null,   null,               null, null
insert into @ttLF select 'ModifiedDate',                null,     -2,   null,               null, null
insert into @ttLF select 'ModifiedBy',                  null,     -2,   null,               null, null
insert into @ttLF select 'CreatedDate',                 null,     -2,   null,               null, null
insert into @ttLF select 'CreatedBy',                   null,     -2,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'CustomerId' /* Key Fields */;

Go