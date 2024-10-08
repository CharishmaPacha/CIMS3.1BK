/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2016/06/17  NB      (NBD-610)
                      Added mapping for CustSKU
                      Switched mapping for SalesOrder and CustPO
  2016/06/14  NB      (NBD-607)
                      Changes to handle NTE segment processing to build comments from
                      multiple NTE segments and update to Comments in XML
  2016/01/06  NB      (NBD-59)
                      Changed to read RoutingCode, ShipVia and FreightCharge from W66, with no
                      process conditions
  2016/01/01  NB      Replaced UDF3 with UnitsPerCarton
  2015/12/22  NB      BusinessUnit - defaulted to NBD
                      UDF1 - Passing in SenderId, to be used for Ownership
                      Initial Revision(NBD-59)
------------------------------------------------------------------------------*/

Go

  declare @vEDIDirection        TName,
          @vEDITransaction      TName,
          @vEDISenderId         TName,
          @vProfileName         TName,
          @vBusinessUnit        TBusinessUnit;

  declare @ttEDIPM              TEDIProcessMap;

select @vEDISenderId    = 'Chrome',
       @vEDITransaction = '940',
       @vEDIDirection   = 'Import',
       @vBusinessUnit   = 'NBD',
       @vProfileName    = 'Chrome940';

/*------------------------------------------------------------------------------*/
/* Add criteria */
/*------------------------------------------------------------------------------*/
exec pr_EDI_ManageProfileRule @vEDISenderId, @vEDITransaction, @vEDIDirection, @vProfileName, 'U' /* Action - add/udpate */, @vBusinessUnit;

/*------------------------------------------------------------------------------*/
/* 940 Mapping for Chrome */
/*------------------------------------------------------------------------------*/

select @vProfileName    = 'Chrome940';

/*                            ProcessAction,  SegmentId,  ProcessConditions,            ElementId, CIMSXMLField,       CIMSFieldName,      DefaultValue,      CIMSXMLPath, EDIElementDesc */

insert into @ttEDIPM select  'TEMPLATE',      'ST',       'ST01=940',                   null,      null,               null,               'ImportOrders',    null,        null

insert into @ttEDIPM select  'CLEARDATA',     'W05',      null,                         null,      null,               'PKGComments+TRAComments',null,        null,        null
insert into @ttEDIPM select  'NEWREC',        'W05',      null,                         null,      null,                null,              'OH',              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'W05',      null,                         null,      'RecordType',        null,              'OH',              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'W05',      'W0501=N',                    null,      'Action',            null,              'I',               null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'W05',      'W0501=R',                    null,      'Action',            null,              'U',               null,        null
insert into @ttEDIPM select  'SAVEDATA',      'W05',      null,                         'W0502',   null,                'PickTicket',      null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'W05',      null,                         'W0502',   'PickTicket',        null,              null,              null,        null
insert into @ttEDIPM select  'SAVEDATA',      'W05',      null,                         'W0503',   null,                'SalesOrder',      null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'W05',      null,                         'W0503',   'CustPO',            null,              null,              null,        null
/* Ownership  - This must be transformed to CIMS Owner code */
insert into @ttEDIPM select  'ADDXMLFIELD',   'W05',      null,                         null,      'Ownership',         null,              '[SenderId]',      null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'W05',      null,                         null,      'BusinessUnit',      null,              'NBD',             null,        null

insert into @ttEDIPM select  'ADDXMLFIELD',   'N1',       'N101=OB',                    'N102',    'SoldToName',        null,              null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'N1',       'N101=OB;N103=92',            'N104',    'SoldToId',          null,              null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'N3',       'N101=OB',                    'N301',    'SoldToAddressLine1',null,              null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'N3',       'N101=OB',                    'N302',    'SoldToAddressLine2',null,              null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'N4',       'N101=OB',                    'N401',    'SoldToCity',        null,              null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'N4',       'N101=OB',                    'N402',    'SoldToState',       null,              null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'N4',       'N101=OB',                    'N403',    'SoldToZip',         null,              null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'N4',       'N101=OB',                    'N404',    'SoldToCountry',     null,              null,              null,        null
/* Warehouse  - This must be transformed to CIMS Warehouse code  */
insert into @ttEDIPM select  'CLEARDATA',     'N1',       'N101=WH;N103=92',            null,      null,                'Warehouse',       null,              null,        null
insert into @ttEDIPM select  'SAVEDATA',      'N1',       'N101=WH;N103=92',            'N104',    null,                'Warehouse',       null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'N1',       'N101=WH;N103=92',            null,      'Warehouse',         null,              '[SenderId]+[Warehouse]',null,  null
/* ShipFrom  - This must be transformed to CIMS Shipfrom code  */
insert into @ttEDIPM select  'ADDXMLFIELD',   'N1',       'N101=SH',                    'N102',    'ShipFrom',          null,              null,              null,        null

insert into @ttEDIPM select  'ADDXMLFIELD',   'N1',       'N101=ST',                    'N102',    'ShipToName',        null,              null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'N1',       'N101=ST;N103=92',            'N104',    'ShipToId',          null,              null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'N2',       'N101=ST',                    'N201',    'ShipToReference1',  null,              null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'N3',       'N101=ST',                    'N301',    'ShipToAddressLine1',null,              null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'N3',       'N101=ST',                    'N302',    'ShipToAddressLine2',null,              null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'N4',       'N101=ST',                    'N401',    'ShipToCity',        null,              null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'N4',       'N101=ST',                    'N402',    'ShipToState',       null,              null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'N4',       'N101=ST',                    'N403',    'ShipToZip',         null,              null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'N4',       'N101=ST',                    'N404',    'ShipToCountry',     null,              null,              null,        null

insert into @ttEDIPM select  'ADDXMLFIELD',   'N1',       'N101=BY',                    'N102',    'BillToAddressName', null,              null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'N3',       'N101=BY',                    'N301',    'BillToAddressLine1',null,              null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'N3',       'N101=BY',                    'N302',    'BillToAddressLine2',null,              null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'N4',       'N101=BY',                    'N401',    'BillToAddressCity', null,              null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'N4',       'N101=BY',                    'N402',    'BillToAddressState',null,              null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'N4',       'N101=BY',                    'N403',    'BillToAddressZip',  null,              null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'N4',       'N101=BY',                    'N404',    'BillToAddressCountry',null,            null,              null,        null

insert into @ttEDIPM select  'CLEARDATA',     'N9',       'N901=8X',                    null,       null,                'OrderType',       null,              null,        null
insert into @ttEDIPM select  'SAVEDATA',      'N9',       'N901=8X',                    'N902',     null,                'OrderType',       null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'N9',       'N901=8X',                    null,      'OrderType',          null,              '[SenderId]+[OrderType]',null,  null
insert into @ttEDIPM select  'ADDXMLFIELD',   'N9',       'N901=8X',                    'N903',    'OrderCategory1',    null,              null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'N9',       'N901=CO',                    'N902',    'SalesOrder',        null,              null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'N9',       'N901=PC',                    'N902',    'Priority',          null,              null,              null,        null
/* Department */
insert into @ttEDIPM select  'ADDXMLFIELD',   'N9',       'N901=DP',                    'N902',    'UDF1',              null,              null,              null,        null

insert into @ttEDIPM select  'ADDXMLFIELD',   'G62',      'G6201=4',                    'G6202',   'OrderedDate',       null,              null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'G62',      'G6201=53',                   'G6202',   'DesiredShipDate',   null,              null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'G62',      'G6201=54',                   'G6202',   'CancelDate',        null,              null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'G62',      'G6201=47',                   'G6202',   'CreatedDate',       null,              null,              null,        null
/* Save NTE PKG Comments */
insert into @ttEDIPM select  'SAVEDATA',      'NTE',      'NTE01=PKG',                  'NTE02',   null,               'NTE02PKG',        null,               null,        null
/* Concatenated previously saved comments with the current NTE PKG Comments */
insert into @ttEDIPM select  'SAVEDATA',      'NTE',      'NTE01=PKG',                  null,      null,               'PKGComments',     '[PKGComments]+[NTE02PKG]',null, null
insert into @ttEDIPM select  'SAVEDATA',      'NTE',      'NTE01=TRA',                  'NTE02',   null,               'NTE02TRA',        null,               null,        null
insert into @ttEDIPM select  'SAVEDATA',      'NTE',      'NTE01=TRA',                  'NTE02',   null,               'TRAComments',     '[TRAComments]+[NTE02TRA]',null, null
insert into @ttEDIPM select  'ADDXMLFIELD',   'NTE',      null,                         null,      'Comments',         null,              '[PKGComments]+[TRAComments]',null,null

insert into @ttEDIPM select  'ADDXMLFIELD',   'W66',      'W6601=NC',                   null,      'FreightTerms',      null,              'NOCHARGE',        null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'W66',      'W6601=CC',                   null,      'FreightTerms',      null,              'COLLECT',         null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'W66',      'W6601=PP',                   null,      'FreightTerms',      null,              'PREPAID',         null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'W66',      'W6601=TB',                   null,      'FreightTerms',      null,              '3RDPARTY',        null,        null
/* Routing Code */
insert into @ttEDIPM select  'ADDXMLFIELD',   'W66',      null,                         'W6605',   'UDF2',              null,              null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'W66',      null,                         'W6609',   'FreightCharges',    null,              null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'W66',      null,                         'W6610',   'ShipVia',           null,              null,              null,        null

insert into @ttEDIPM select  'NEWREC',        'W01',      null,                         null,      null,                null,              'OD',              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'W01',      null,                         null,      'RecordType',        null,              'OD',              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'W01',      null,                         null,      'Action',            null,              'I',               null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'W01',      null,                         null,      'PickTicket',        null,              '[PickTicket]',    null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'W01',      null,                         null,      'SalesOrder',        null,              '[SalesOrder]',    null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'W01',      null,                         'W0101',   'UnitsOrdered',      null,              null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'W01',      null,                         'W0101',   'UnitsAuthorizedToShip',null,           null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'W01',      null,                         'W0102',   'UoM',               null,              null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'W01',      'W0103=VC',                   'W0104',   'SKU1',              null,              null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'W01',      'W0105=UP',                   'W0106',   'SKU',               null,              null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'W01',      'W0105=UP',                   'W0106',   'UPC',               null,              null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'W01',      'W0107=CB',                   'W0108',   'CustSKU',           null,              null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'W01',      null,                         'W0111',   'UnitsPerCarton',    null,              null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'W01',      null,                         'W0112',   'HostOrderLine',     null,              '100',             null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'W01',      null,                         null,      'LineType',          null,              'M',               null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'W01',      null,                         null,      'BusinessUnit',      null,              'NBD',             null,        null

insert into @ttEDIPM select  'ADDXMLFIELD',   'G69',      null,                         'G6901',   'UDF1',              null,              null,              null,        null

insert into @ttEDIPM select  'ADDXMLFIELD',   'AMT',      'AMT01=LI',                   'AMT02',   'UnitSalePrice',     null,              null,              null,        null

exec pr_EDI_SetupProfileMap @vProfileName, @vEDITransaction, @ttEDIPM, 'R' /* Action - Add */, @vBusinessUnit;

Go
