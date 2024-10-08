/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/06  OK      Added summary fields (HA-2544)
  2021/03/13  OK      Added LoadType. LoadStatus, ShipToId and changed visibility for UDFDesc1, UDFDesc2 and Count1 to 11 make filters availabl for these (HA-2264)
  2021/03/11  KBB     Corrected the fields Order as per the Table  and Added few new fields (HA-1093)
  2021/01/19  PKK     Corrected the file as per the template(CIMSV3-1282)
  2020/09/25  KBB     Initial revision (HA-1093)
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

select @ContextName = 'List.ShippingLog',
       @DataSetName = 'pr_UI_DS_ShippingLog';

/******************************************************************************/
/* Layouts */
/******************************************************************************/
delete from @Layouts;

/*                          Layout  Default  Layout                        Default        Status Visible SortSeq ShowExpanded
                            Type    Layout   Description                   SelectionName                                   */
insert into @Layouts select 'L',    'N',     'Standard',                   null,          null,  null,   0,      null

exec pr_Setup_Layout @ContextName, @DataSetName, @Layouts, 'DI' /* Delete & Insert */, 'cimsdba', @BusinessUnit;

/******************************************************************************/
/* Listing Layouts Details */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
/* Layout Fields for Standard Layout */
/*----------------------------------------------------------------------------*/
delete from @ttLF;

/*                        Field                         Visible Visible Field                  Width Display
                          Name                          Index           Caption                   Format */
insert into @ttLF select 'RecordId',                    null,   null,   null,                  null, null
insert into @ttLF select 'ShipFrom',                    null,   null,   null,                  null, null
insert into @ttLF select 'ShipFromName',                null,      1,   'Ship From',           null, null
insert into @ttLF select 'Warehouse',                   null,     -1,   null,                  null, null
insert into @ttLF select 'WarehouseDesc',               null,     -1,   null,                  null, null

insert into @ttLF select 'LoadId',                      null,   null,   null,                  null, null
insert into @ttLF select 'LoadNumber',                  null,      1,   null,                  null, null

insert into @ttLF select 'Account',                     null,     -1,   null,                  null, null
insert into @ttLF select 'AccountName',                 null,      1,   null,                  null, null

insert into @ttLF select 'ClientLoad',                  null,   null,   null,                  null, null
insert into @ttLF select 'LoadType',                    null,   null,   null,                  null, null
insert into @ttLF select 'LoadTypeDesc',                null,     -1,   null,                  null, null
insert into @ttLF select 'LoadStatus',                  null,   null,   null,                  null, null
insert into @ttLF select 'LoadStatusDesc',              null,     -1,   null,                  null, null
insert into @ttLF select 'RoutingStatusDesc',           null,     -1,   null,                  null, null

insert into @ttLF select 'CancelDate',                  null,     -1,   null,                  null, null
insert into @ttLF select 'ShippedDate',                 null,   null,   null,                  null, null

insert into @ttLF select 'UDFDesc2',                    null,      11,   'Lot#',                200, null
insert into @ttLF select 'UDFDesc1',                    null,      11,   'Cust POs',            200, null
insert into @ttLF select 'Count1',                      null,      11,   '# POs',              null, null

insert into @ttLF select 'CustPO',                      null,     -2,   null,                  null, null
insert into @ttLF select 'ShipToDC',                    null,      1,   'DC #',                null, null
insert into @ttLF select 'ShipToStore',                 null,     -1,   null,                  null, null
insert into @ttLF select 'LPNsAssigned',                null,      1,   '# Ctns',              null, null

insert into @ttLF select 'ShipToId',                    null,     -1,   null,                  null, null
insert into @ttLF select 'ShipToName',                  null,     -1,   null,                  null, null
insert into @ttLF select 'ShipToCityState',             null,      1,   null,                  null, null
insert into @ttLF select 'ShipToCity',                  null,     -1,   null,                  null, null
insert into @ttLF select 'ShipToState',                 null,     -1,   null,                  null, null
insert into @ttLF select 'ShipToZip',                   null,     -1,   null,                  null, null

insert into @ttLF select 'ShipVia',                     null,     -1,   null,                  null, null
insert into @ttLF select 'ShipViaDesc',                 null,      1,   null,                  null, null

insert into @ttLF select 'EstimatedCartons',            null,   null,   null,                  null, null
insert into @ttLF select 'TotalWeight',                 null,   null,   null,                  null, null
insert into @ttLF select 'TotalVolume',                 null,   null,   null,                  null, null

insert into @ttLF select 'Count2',                      null,   null,   null,                  null, null
insert into @ttLF select 'Count3',                      null,   null,   null,                  null, null
insert into @ttLF select 'Count4',                      null,   null,   null,                  null, null
insert into @ttLF select 'Count5',                      null,   null,   null,                  null, null

insert into @ttLF select 'AppointmentConfirmation',     null,     -1,   null,                  null, null
--insert into @ttLF select 'AppointmentDateTime',         null,   null,   null,                  null, null

insert into @ttLF select 'DesiredShipDate',             null,      1,   'Pickup Date',         null, null
insert into @ttLF select 'ApptTime',                    null,      1,   'Pickup Time',         null, null
insert into @ttLF select 'GroupCriteria',               null,   null,   null,                  null, null

insert into @ttLF select 'UDFDesc3',                    null,   null,   null,                  null, null
insert into @ttLF select 'UDFDesc4',                    null,   null,   null,                  null, null
insert into @ttLF select 'UDFDesc5',                    null,   null,   null,                  null, null

insert into @ttLF select 'UDF1',                        null,   null,   null,                  null, null
insert into @ttLF select 'UDF2',                        null,   null,   null,                  null, null
insert into @ttLF select 'UDF3',                        null,   null,   null,                  null, null
insert into @ttLF select 'UDF4',                        null,   null,   null,                  null, null
insert into @ttLF select 'UDF5',                        null,   null,   null,                  null, null

insert into @ttLF select 'Archived',                    null,   null,   null,                  null, null
insert into @ttLF select 'BusinessUnit',                null,   null,   null,                  null, null
insert into @ttLF select 'ModifiedDate',                null,   null,   null,                  null, null
insert into @ttLF select 'ModifiedBy',                  null,   null,   null,                  null, null
insert into @ttLF select 'CreatedDate',                 null,   null,   null,                  null, null
insert into @ttLF select 'CreatedBy',                   null,   null,   null,                  null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'RecordId;LoadNumber' /* Key fields */;

/******************************************************************************/
/* Summary Layouts Details*/
/******************************************************************************/

/******************************************************************************/
/* Summary Fields Setup */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
select @LayoutDescription = null; -- Applicable to all layouts
delete from @ttLSF;

/*                        FieldName,                    SummaryType, DisplayFormat,                AggregateMethod */
insert into @ttLSF select 'LoadNumber',                 'DCount',    '# Loads:{0:n0}',             null
insert into @ttLSF select 'EstimatedCartons',           'Sum',       '{0:###,###,###}',            null
insert into @ttLSF select 'TotalWeight',                'Sum',       '{0:###,###,###}',            null
insert into @ttLSF select 'TotalVolume',                'Sum',       '{0:###,###,###}',            null

exec pr_Setup_LayoutSummaryFields @ContextName, null /* LayoutDescription */, @ttLSF;

Go
