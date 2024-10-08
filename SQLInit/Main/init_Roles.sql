/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/24  KBB     CIMSSupport: Move to bottom of list of roles(CIMSV3-1215)
  2020/03/29  MS      Added BusinessUnit (CIMSV3-467)
  2016/02/01  AY      Renamed Role 1
  2012/08/08  AY      Changed to be sorted properly.
------------------------------------------------------------------------------*/

Go

delete from Roles;

/* Have to insert the values for identity columns */
set IDENTITY_INSERT Roles ON;

/* We will not use RoleId 1 as that was reserved for CIMS Team in V2 */
insert into Roles (RoleId,  RoleName,             Description,                IsActive, BusinessUnit)

            select  2,      'Admin',              'Administrator',            1,        BusinessUnit from vwBusinessUnits
     union  select  3,      'SuperUser',          'Super User',               1,        BusinessUnit from vwBusinessUnits
     union  select  4,      'Manager',            'Manager',                  1,        BusinessUnit from vwBusinessUnits
     union  select  5,      'Supervisor',         'Supervisor',               1,        BusinessUnit from vwBusinessUnits
     union  select  6,      'InventoryMgr',       'Inventory Manager',        1,        BusinessUnit from vwBusinessUnits

     union  select 11,      'Material Handler',   'Material Handler',         1,        BusinessUnit from vwBusinessUnits
     union  select 12,      'Receiver',           'Receiver',                 1,        BusinessUnit from vwBusinessUnits
     union  select 13,      'Picker',             'Picker',                   1,        BusinessUnit from vwBusinessUnits
     union  select 14,      'Packer',             'Packer',                   1,        BusinessUnit from vwBusinessUnits
     union  select 15,      'Shipper',            'Shipper',                  1,        BusinessUnit from vwBusinessUnits

     union  select 20,      'RF User',            'RF User',                  1,        BusinessUnit from vwBusinessUnits
     union  select 21,      'Office User',        'Office User',              1,        BusinessUnit from vwBusinessUnits
     union  select 23,      'Temporary User',     'Temporary Worker',         1,        BusinessUnit from vwBusinessUnits

     union  select 98,      'Contractor',         'Contractor',               1,        BusinessUnit from vwBusinessUnits
     union  select 99,      'Consultant',         'Consultant',               1,        BusinessUnit from vwBusinessUnits

     union  select 999,     'CIMSSupport',        'CIMS Support Team',        1,        BusinessUnit from vwBusinessUnits

set IDENTITY_INSERT Roles OFF;

Go
