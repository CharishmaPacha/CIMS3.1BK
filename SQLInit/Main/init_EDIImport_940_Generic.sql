/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2016/06/29  RV      (NBD-639)
                       Added mapping Duties & Taxes to TotalTax
  2016/06/24  NB      (NBD-619)
                       Added mapping for TotalShippingCost
  2016/06/14  NB      (NBD-607)
                      Changes to handle NTE segment processing to build comments from
                      multiple NTE segments and update to Comments in XML
  2016/04/19  NB      Added mapping for REF for GIFT orders(NBD-403)
  2016/03/01  NB      set the DefaultValue for HostOrderLine to ''(NBD-102)
  2016/01/06  NB      (NBD-59)
                      Default OrderType to C, Priority to 99
                      Changed to read RoutingCode, ShipVia and FreightCharge from W66, with no
                      process conditions
  2016/01/05  NB      (NBD-59)
                      Defaults for Warehouse and ShipFrom
                      Read BillTo from N1 with BY or BT
                      Order Detaile SKU and UPC Mapping corrections
  2016/01/01  NB      Initial Revision(NBD-59)
------------------------------------------------------------------------------*/

Go

  declare @vEDIDirection        TName,
          @vEDITransaction      TName,
          @vEDISenderId         TName,
          @vProfileName         TName,
          @vBusinessUnit        TBusinessUnit;

  declare @ttEDIPM              TEDIProcessMap;

select @vEDISenderId    = 'NBD',
       @vEDITransaction = '940',
       @vEDIDirection   = 'Import',
       @vBusinessUnit   = 'NBD',
       @vProfileName    = 'Generic940';

/*------------------------------------------------------------------------------*/
/* Add criteria */
/*------------------------------------------------------------------------------*/
exec pr_EDI_ManageProfileRule @vEDISenderId, @vEDITransaction, @vEDIDirection, @vProfileName, 'U' /* Action - add/udpate */, @vBusinessUnit;
exec pr_EDI_ManageProfileRule 'KUIU', @vEDITransaction, @vEDIDirection, @vProfileName, 'U' /* Action - add/udpate */, @vBusinessUnit;
/*------------------------------------------------------------------------------*/
/* 940 Mapping for Generic */
/*------------------------------------------------------------------------------*/

--select @vProfileName    = 'Chrome940';

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
insert into @ttEDIPM select  'ADDXMLFIELD',   'W05',      null,                         'W0503',   'SalesOrder',        null,              null,              null,        null
/* Ownership  - This must be transformed to CIMS Owner code */
insert into @ttEDIPM select  'ADDXMLFIELD',   'W05',      null,                         null,      'Ownership',         null,              '[SenderId]',      null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'W05',      null,                         null,      'BusinessUnit',      null,              'NBD',             null,        null
/* Warehouse cannot be null
   Default Warehouse - set this to SenderId
   This will be transformed to Warehouse using Owner-Warehouse mapping in Lookups */
insert into @ttEDIPM select  'ADDXMLFIELD',   'W05',      null,                         null,      'Warehouse',         null,              '[SenderId]',      null,        null
/* Default ShipFrom - SenderId will be transformed to Owner using Mapping
   Owner code will be reference for ShipFrom Information  */
insert into @ttEDIPM select  'ADDXMLFIELD',   'W05',      null,                          null,     'ShipFrom',          null,               '[SenderId]',       null,        null
/* Order Type default to C for Customer Order - Will get overwritten by actual values if EDI file has the relevant segments and data */
insert into @ttEDIPM select  'ADDXMLFIELD',   'W05',      null,                          null,     'OrderType',        null,              'C',              null,        null
/* Priority default to 99 - Will get overwritten by actual values if EDI file has the relevant segments and data */
insert into @ttEDIPM select  'ADDXMLFIELD',   'W05',      null,                          null,     'Priority',          null,              '99',              null,        null
/* Sold To address */
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
/* ShipFrom  - This will be transformed to CIMS Shipfrom code  */
insert into @ttEDIPM select  'ADDXMLFIELD',   'N1',       'N101=SH',                    'N102',    'ShipFrom',          null,              null,              null,        null
/* Ship To */
insert into @ttEDIPM select  'ADDXMLFIELD',   'N1',       'N101=ST',                    'N102',    'ShipToName',        null,              null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'N1',       'N101=ST;N103=92',            'N104',    'ShipToId',          null,              null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'N2',       'N101=ST',                    'N201',    'ShipToReference1',  null,              null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'N3',       'N101=ST',                    'N301',    'ShipToAddressLine1',null,              null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'N3',       'N101=ST',                    'N302',    'ShipToAddressLine2',null,              null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'N4',       'N101=ST',                    'N401',    'ShipToCity',        null,              null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'N4',       'N101=ST',                    'N402',    'ShipToState',       null,              null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'N4',       'N101=ST',                    'N403',    'ShipToZip',         null,              null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'N4',       'N101=ST',                    'N404',    'ShipToCountry',     null,              null,              null,        null
/* Bill To */
insert into @ttEDIPM select  'ADDXMLFIELD',   'N1',       'N101=BY|BT',                 'N102',    'BillToAddressName', null,              null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'N3',       'N101=BY|BT',                 'N301',    'BillToAddressLine1',null,              null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'N3',       'N101=BY|BT',                 'N302',    'BillToAddressLine2',null,              null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'N4',       'N101=BY|BT',                 'N401',    'BillToAddressCity', null,              null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'N4',       'N101=BY|BT',                 'N402',    'BillToAddressState',null,              null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'N4',       'N101=BY|BT',                 'N403',    'BillToAddressZip',  null,              null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'N4',       'N101=BY|BT',                 'N404',    'BillToAddressCountry',null,            null,              null,        null

insert into @ttEDIPM select  'CLEARDATA',     'N9',       'N901=8X',                    null,       null,                'OrderType',       null,              null,        null
insert into @ttEDIPM select  'SAVEDATA',      'N9',       'N901=8X',                    'N902',     null,                'OrderType',       null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'N9',       'N901=8X',                    null,      'OrderType',          null,              '[SenderId]+[OrderType]',null,  null
insert into @ttEDIPM select  'ADDXMLFIELD',   'N9',       'N901=8X',                    'N903',    'OrderCategory1',    null,              null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'N9',       'N901=CO',                    'N902',    'CustPO',            null,              null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'N9',       'N901=PC',                    'N902',    'Priority',          null,              null,              null,        null
/* Department */
insert into @ttEDIPM select  'ADDXMLFIELD',   'N9',       'N901=DP',                    'N902',    'UDF1',              null,              null,              null,        null
/* Duties & Taxes */
insert into @ttEDIPM select  'ADDXMLFIELD',   'N9',       'N901=AC',                    'N902',    'TotalTax',          null,              null,              null,        null
/* GIFT */
insert into @ttEDIPM select  'ADDXMLFIELD',   'REF',      'REF01=PC',                   'REF02',   'UDF3',              null,              null,              null,        null
/* Total Shipping Cost */
insert into @ttEDIPM select  'ADDXMLFIELD',   'REF',      'REF01=IV2',                  'REF02',   'TotalShippingCost', null,              null,              null,        null

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
insert into @ttEDIPM select  'ADDXMLFIELD',   'W01',      'W0104=VC',                   'W0104',   'SKU1',              null,              null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'W01',      'W0104=UP',                   'W0105',   'SKU',               null,              null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'W01',      'W0104=UP',                   'W0105',   'UPC',               null,              null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'W01',      'W0106=UP',                   'W0107',   'SKU',               null,              null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'W01',      'W0106=UP',                   'W0107',   'UPC',               null,              null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'W01',      null,                         'W0111',   'UnitsPerCarton',    null,              null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'W01',      null,                         'W0112',   'HostOrderLine',     null,              '',                null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'W01',      null,                         null,      'LineType',          null,              'M',               null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'W01',      null,                         null,      'BusinessUnit',      null,              'NBD',             null,        null

insert into @ttEDIPM select  'ADDXMLFIELD',   'G69',      null,                         'G6901',   'UDF1',              null,              null,              null,        null

insert into @ttEDIPM select  'ADDXMLFIELD',   'AMT',      'AMT01=LI',                   'AMT02',   'UnitSalePrice',     null,              null,              null,        null

exec pr_EDI_SetupProfileMap @vProfileName, @vEDITransaction, @ttEDIPM, 'R' /* Action - Add */, @vBusinessUnit;

Go
