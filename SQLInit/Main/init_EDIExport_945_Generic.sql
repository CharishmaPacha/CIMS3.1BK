/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2016/04/21  NB      Changed W1208 mapping to SKU from SKU1(NBD-423)
  2016/04/11  AY      Mapping W2702 to UDF2 for SCAC Code(NBD-266)
  2016/03/01  NB      Introduced (SEGMENTCOUNT) as value for LX01(NBD-102)
  2016/02/29  NB      Formatting changes (NBD-102)
  2016/02/26  NB      (NBD-102)
                      Mapping changes for creation of LX, N9, MAN segments conditionally, return UPC
                      or SKU in W12, Write HostOrderLine only if exists
  2016/02/11  NB      G7203 mapping modified to read FreightCharges from ShipOH record(NBD-102)
  2016/02/10  NB      (NBD-102)
                      Corrected FreightCharges cims field
                      Changed W0301 mapping to TransQty
  2016/02/02  NB      Create MAN segment for only ShipLPND(NBD-102)
  2016/01/27  NB      Initial Revision(NBD-102)
------------------------------------------------------------------------------*/

Go

  declare @vEDIDirection        TName,
          @vEDITransaction      TName,
          @vEDISenderId         TName,
          @vProfileName         TName,
          @vBusinessUnit        TBusinessUnit;

  declare @ttEDIPM              TEDIProcessMap;

select @vEDISenderId    = 'NBD',
       @vEDITransaction = '945',
       @vEDIDirection   = 'Export',
       @vBusinessUnit   = 'NBD',
       @vProfileName    = 'Generic945';

/*------------------------------------------------------------------------------*/
/* Add criteria */
/*------------------------------------------------------------------------------*/
exec pr_EDI_ManageProfileRule @vEDISenderId, @vEDITransaction, @vEDIDirection, @vProfileName, 'U' /* Action - add/udpate */, @vBusinessUnit;
exec pr_EDI_ManageProfileRule 'Chrome',      @vEDITransaction, @vEDIDirection, @vProfileName, 'U' /* Action - add/udpate */, @vBusinessUnit;
exec pr_EDI_ManageProfileRule 'KUIU',        @vEDITransaction, @vEDIDirection, @vProfileName, 'U' /* Action - add/udpate */, @vBusinessUnit;
exec pr_EDI_ManageProfileRule 'Vasyli',      @vEDITransaction, @vEDIDirection, @vProfileName, 'U' /* Action - add/udpate */, @vBusinessUnit;

/*------------------------------------------------------------------------------*/
/* 945 Mapping for Generic */
/*------------------------------------------------------------------------------*/

/*                            ProcessAction,  SegmentId,  ProcessConditions,  ElementId, CIMSXMLField,       CIMSFieldName,      DefaultValue,      CIMSXMLPath, EDIElementDesc */

/*
insert into @ttEDIPM select 'CLEARDATA',     'ST',         null,              null,      null,               'CreateNew',        null,              null,        null
*/
/* Below statement will be evaluated as below by EDI Exchange
   The condition PickTicket=[CurrentPT] is evaluated considering the value of PickTicket in the Record values and saved value with the name 'CurrentPT'
   The result of this statement processing is a new value saved in memory, called 'CreateNew', and updated for each record in the XML
   The DefaultValue column has two values seperated by comma Y,N.
   If the condition result is true, then the first value Y is stored in the new flag 'CreateNew'
   If the condition result is false, then the first value N is stored in the new flag 'CreateNew'
*/
insert into @ttEDIPM select 'SAVEDATA',      'ST',        'PickTicket![CurrentPT]',null, null,               'CreateNew',        'Y,N',             null,        null
insert into @ttEDIPM select 'NEWEDISEGMENT', 'ST',        '[CreateNew]=Y',    null,      null,               null,                null,             null,        null
insert into @ttEDIPM select 'ADDEDIFIELD',   'ST',        '[CreateNew]=Y',    'ST01',    null,               null,               '945',             null,        null
insert into @ttEDIPM select 'ADDEDIFIELD',   'ST',        '[CreateNew]=Y',    'ST02',    null,               null,               '[STControlNumber945]',null,    null

insert into @ttEDIPM select 'NEWEDISEGMENT', 'W06',       '[CreateNew]=Y',    null,      null,               null,               null,              null,        null
/* F code for Full Detail */
insert into @ttEDIPM select 'ADDEDIFIELD',   'W06',       '[CreateNew]=Y',    'W0601',   null,               null,               'F',               null,        null
insert into @ttEDIPM select 'ADDEDIFIELD',   'W06',       '[CreateNew]=Y',    'W0602',   'SalesOrder',       null,               null,              null,        null
insert into @ttEDIPM select 'ADDEDIFIELD',   'W06',       '[CreateNew]=Y',    'W0603',   'TransDateTime',    null,               null,              null,        null
insert into @ttEDIPM select 'ADDEDIFIELD',   'W06',       '[CreateNew]=Y',    'W0604',   'LPN',              null,               null,              null,        null
/*
insert into @ttEDIPM select 'ADDEDIFIELD',   'W06',       null,               'W0605',   null,               null,               null,              null,        null
*/
insert into @ttEDIPM select 'ADDEDIFIELD',   'W06',       '[CreateNew]=Y',    'W0606',   'CustPO',           null,               null,              null,        null
/*
insert into @ttEDIPM select 'ADDEDIFIELD',   'W06',       null,               'W0607',   null,               null,               null,              null,        null
insert into @ttEDIPM select 'ADDEDIFIELD',   'W06',       null,               'W0608',   null,               null,               null,              null,        null
insert into @ttEDIPM select 'ADDEDIFIELD',   'W06',       null,               'W0609',   null,               null,               null,              null,        null
insert into @ttEDIPM select 'ADDEDIFIELD',   'W06',       null,               'W0610',   null,               null,               null,              null,        null
insert into @ttEDIPM select 'ADDEDIFIELD',   'W06',       null,               'W0611',   null,               null,               null,              null,        null
insert into @ttEDIPM select 'ADDEDIFIELD',   'W06',       null,               'W0612',   null,               null,               null,              null,        null
*/

insert into @ttEDIPM select 'NEWEDISEGMENT', 'N1',        '[CreateNew]=Y',    null,      null,               null,               null,              null,        null
/* BT is the code for Bill To */
insert into @ttEDIPM select 'ADDEDIFIELD',   'N1',        '[CreateNew]=Y',    'N101',    null,               null,               'BT',              null,        null
insert into @ttEDIPM select 'ADDEDIFIELD',   'N1',        '[CreateNew]=Y',    'N102',    'BillToName',       null,               null,              null,        null
/*
insert into @ttEDIPM select 'ADDEDIFIELD',   'N1',        null,               'N103',    null,               null,               '92',              null,        null
insert into @ttEDIPM select 'ADDEDIFIELD',   'N1',        null,               'N102',    null,               null,               null,              null,        null
*/

insert into @ttEDIPM select 'NEWEDISEGMENT', 'G62',       '[CreateNew]=Y',    null,      null,               null,               null,              null,        null
/* '11'  Shipped On */
insert into @ttEDIPM select 'ADDEDIFIELD',   'G62',       '[CreateNew]=Y',    'G6201',   null,               null,               '07',              null,        null
insert into @ttEDIPM select 'ADDEDIFIELD',   'G62',       '[CreateNew]=Y',    'G6202',   'ShippedDate',      null,               null,              null,        null

insert into @ttEDIPM select 'NEWEDISEGMENT', 'W27',       '[CreateNew]=Y',    null,      null,               null,               null,              null,        null
/* 'M'  for Motor Carrier */
insert into @ttEDIPM select 'ADDEDIFIELD',   'W27',       '[CreateNew]=Y',    'W2701',   null,               null,               'M',               null,        null
insert into @ttEDIPM select 'ADDEDIFIELD',   'W27',       '[CreateNew]=Y',    'W2702',   'UDF2',             null,               null,              null,        null
/* Routing document says Freeform Description
TODO Need to add ShipViaDescription to the Export record */
insert into @ttEDIPM select 'ADDEDIFIELD',   'W27',       '[CreateNew]=Y',    'W2703',   'ShipViaDescription',null,              null,              null,        null
/* Freight Terms
TODO Need to add FreightTerms to the export record and transform them into Host Mapping  */
insert into @ttEDIPM select 'ADDEDIFIELD',   'W27',       '[CreateNew]=Y',    'W2704',   'FreightTerms',     null,               null,              null,        null
/*
insert into @ttEDIPM select 'ADDEDIFIELD',   'W27',       null,               'W2705',   null,               null,               null,              null,        null
insert into @ttEDIPM select 'ADDEDIFIELD',   'W27',       null,               'W2706',   null,               null,               null,              null,        null
*/
/* Routing Code ..This is stored in OH_UDF2 */
insert into @ttEDIPM select 'ADDEDIFIELD',   'W27',       '[CreateNew]=Y',    'W2707',   'OH_UDF2',          null,               null,              null,        null
/*
insert into @ttEDIPM select 'ADDEDIFIELD',   'W27',       null,               'W2707',   null,               null,               null,              null,        null
insert into @ttEDIPM select 'ADDEDIFIELD',   'W27',       null,               'W2708',   null,               null,               null,              null,        null
insert into @ttEDIPM select 'ADDEDIFIELD',   'W27',       null,               'W2709',   null,               null,               null,              null,        null
insert into @ttEDIPM select 'ADDEDIFIELD',   'W27',       null,               'W2710',   null,               null,               null,              null,        null
*/

insert into @ttEDIPM select 'NEWEDISEGMENT', 'G72',       '[CreateNew]=Y',    null,      null,               null,               null,              null,        null
/* 504 is for Freight */
insert into @ttEDIPM select 'ADDEDIFIELD',   'G72',       '[CreateNew]=Y',    'G7201',   null,               null,               '504',             null,        null
/* Freight Terms
TODO Need to add Freight Terms to Export Record and Transform it to the Host Mapping */
insert into @ttEDIPM select 'ADDEDIFIELD',   'G72',       '[CreateNew]=Y',    'G7202',   'FreightTerms',     null,               null,              null,        null
/* Allowance or Charge Number
TODO Need to Add Freight Charge to Export record */
insert into @ttEDIPM select 'ADDEDIFIELD',   'G72',       'RecordType=ShipOH','G7203',   'FreightCharges',   null,               null,              null,        null
/*
insert into @ttEDIPM select 'ADDEDIFIELD',   'G72',       null,               'W7204',   null,               null,               null,              null,        null
insert into @ttEDIPM select 'ADDEDIFIELD',   'G72',       null,               'W7205',   null,               null,               null,              null,        null
insert into @ttEDIPM select 'ADDEDIFIELD',   'G72',       null,               'W7206',   null,               null,               null,              null,        null
insert into @ttEDIPM select 'ADDEDIFIELD',   'G72',       null,               'W7207',   null,               null,               null,              null,        null
insert into @ttEDIPM select 'ADDEDIFIELD',   'G72',       null,               'W7208',   null,               null,               null,              null,        null
insert into @ttEDIPM select 'ADDEDIFIELD',   'G72',       null,               'W7209',   null,               null,               null,              null,        null
insert into @ttEDIPM select 'ADDEDIFIELD',   'G72',       null,               'W7210',   null,               null,               null,              null,        null
insert into @ttEDIPM select 'ADDEDIFIELD',   'G72',       null,               'W7211',   null,               null,               null,              null,        null
*/
/* LOOP START */
/* LOOP START */
/* LOOP START */

/* All the below instructions are executed only when the RecordType is either ShipLPND or ShipOD */
insert into @ttEDIPM select 'SAVEDATA',      'LX',        'RecordType=ShipLPND;LPN![CurrentLPN]',null, null, 'NewLPNLX',         'Y,N',             null,        null
insert into @ttEDIPM select 'SAVEDATA',      'LX',        'RecordType=ShipOD',null,      null,               'NewODLX',          'Y,N',             null,        null

insert into @ttEDIPM select 'NEWEDISEGMENT', 'LX',        '[NewLPNLX]=Y',     null,      null,               null,               null,              null,        null
insert into @ttEDIPM select 'NEWEDISEGMENT', 'LX',        '[NewODLX]=Y',      null,      null,               null,               null,              null,        null
/* Sequence Number..Assigned by counting the current number of LX instances */
insert into @ttEDIPM select 'ADDEDIFIELD',   'LX',        '[NewLPNLX]=Y',     'LX01',    null,               null,               '(SEGMENTCOUNT)',  null,        null
insert into @ttEDIPM select 'ADDEDIFIELD',   'LX',        '[NewODLX]=Y',      'LX01',    null,               null,               '(SEGMENTCOUNT)',  null,        null

insert into @ttEDIPM select 'NEWEDISEGMENT', 'MAN',       '[NewLPNLX]=Y',     null,      null,               null,               null,              null,        null
/* GM is for UCC128 */
insert into @ttEDIPM select 'ADDEDIFIELD',   'MAN',       '[NewLPNLX]=Y',     'MAN01',   null,               null,               'GM',              null,        null
insert into @ttEDIPM select 'ADDEDIFIELD',   'MAN',       '[NewLPNLX]=Y',     'MAN02',   'UCCBarcode',       null,               null,              null,        null
insert into @ttEDIPM select 'ADDEDIFIELD',   'MAN',       '[NewLPNLX]=Y',     'MAN03',   'CartonDimensions', null,               null,              null,        null
/* CP is for Carrier Asisgned Number */
insert into @ttEDIPM select 'ADDEDIFIELD',   'MAN',       '[NewLPNLX]=Y',     'MAN04',   null,               null,               'CP',              null,        null
insert into @ttEDIPM select 'ADDEDIFIELD',   'MAN',       '[NewLPNLX]=Y',     'MAN05',   'TrackingNo',       null,               null,              null,        null
/*
insert into @ttEDIPM select 'ADDEDIFIELD',   'MAN',       null,               'MAN06',   null,               null,               null,              null,        null
*/

insert into @ttEDIPM select 'NEWEDISEGMENT', 'N9',        '[NewLPNLX]=Y',     null,      null,               null,               null,              null,        null
/* BM is for 'Bill Of Lading */
insert into @ttEDIPM select 'ADDEDIFIELD',   'N9',        '[NewLPNLX]=Y',     'N901',    null,               null,               'BM',              null,        null
insert into @ttEDIPM select 'ADDEDIFIELD',   'N9',        '[NewLPNLX]=Y',     'N902',    'BoL',              null,               null,              null,        null

insert into @ttEDIPM select 'NEWEDISEGMENT', 'N9',        '[NewLPNLX]=Y',     null,      null,               null,               null,              null,        null
/* WT is for 'Shipment Weight */
insert into @ttEDIPM select 'ADDEDIFIELD',   'N9',        '[NewLPNLX]=Y',     'N901',    null,               null,               'WT',              null,        null
insert into @ttEDIPM select 'ADDEDIFIELD',   'N9',        '[NewLPNLX]=Y',     'N902',    'Weight',           null,               null,              null,        null

insert into @ttEDIPM select 'NEWEDISEGMENT', 'W12',       'RecordType=ShipLPND|ShipOD',null,null,            null,               null,              null,        null
/* Shipment Order Status Code Complete or Short Shipped
   When the Record is of type ShipLPNDetail, the code is sent as Completely Shipped
   When the Record is of type ShipOD, the code is sent as Short Shipped */
insert into @ttEDIPM select 'ADDEDIFIELD',   'W12',       'RecordType=ShipLPND','W1201', null,               null,               'CC',              null,        null
insert into @ttEDIPM select 'ADDEDIFIELD',   'W12',       'RecordType=ShipOD','W1201',   null,               null,               'SC',              null,        null
/* Quantity Ordered */
insert into @ttEDIPM select 'ADDEDIFIELD',   'W12',       'RecordType=ShipLPND','W1202', 'TransQty',         null,               null,              null,        null
insert into @ttEDIPM select 'ADDEDIFIELD',   'W12',       'RecordType=ShipOD','W1202',   'UnitsToAllocate',  null,               null,              null,        null
/* Quantity Shipped */
insert into @ttEDIPM select 'ADDEDIFIELD',   'W12',       'RecordType=ShipLPND','W1203', 'TransQty',         null,               null,              null,        null
insert into @ttEDIPM select 'ADDEDIFIELD',   'W12',       'RecordType=ShipOD','W1203',   null,               null,               '0',               null,        null
/* Quantity Difference */
insert into @ttEDIPM select 'ADDEDIFIELD',   'W12',       'RecordType=ShipLPND','W1204', null,               null,               '0',               null,        null
insert into @ttEDIPM select 'ADDEDIFIELD',   'W12',       'RecordType=ShipOD','W1204',   'UnitsToAllocate',  null,               null,              null,        null
/* Units or Basis for Measurement EA is for Each */
insert into @ttEDIPM select 'ADDEDIFIELD',   'W12',       'RecordType=ShipLPND|ShipOD','W1205',null,         null,               'EA',              null,        null
/* UPC # */
insert into @ttEDIPM select 'ADDEDIFIELD',   'W12',       'RecordType=ShipLPND|ShipOD;UPC!','W1206','UPC',   null,               null,              null,        null
insert into @ttEDIPM select 'ADDEDIFIELD',   'W12',       'RecordType=ShipLPND|ShipOD;UPC=','W1206','SKU',   null,               null,              null,        null
/* TODO MG for Man Part# or VA for Style#  */
insert into @ttEDIPM select 'ADDEDIFIELD',   'W12',       'RecordType=ShipLPND|ShipOD','W1207',null,         null,               'VA',              null,        null
insert into @ttEDIPM select 'ADDEDIFIELD',   'W12',       'RecordType=ShipLPND|ShipOD','W1208','SKU',        null,               null,              null,        null
/* Original Order Line Number from 940 */
insert into @ttEDIPM select 'ADDEDIFIELD',   'W12',       'RecordType=ShipLPND|ShipOD;HostOrderLine!','W1209','HostOrderLine',null,null,            null,        null
/*
insert into @ttEDIPM select 'ADDEDIFIELD',   'W12',       null,               'W1210',   null,               null,               null,              null,        null
insert into @ttEDIPM select 'ADDEDIFIELD',   'W12',       null,               'W1211',   null,               null,               null,              null,        null
insert into @ttEDIPM select 'ADDEDIFIELD',   'W12',       null,               'W1212',   null,               null,               null,              null,        null
insert into @ttEDIPM select 'ADDEDIFIELD',   'W12',       null,               'W1213',   null,               null,               null,              null,        null
insert into @ttEDIPM select 'ADDEDIFIELD',   'W12',       null,               'W1214',   null,               null,               null,              null,        null
insert into @ttEDIPM select 'ADDEDIFIELD',   'W12',       null,               'W1215',   null,               null,               null,              null,        null
insert into @ttEDIPM select 'ADDEDIFIELD',   'W12',       null,               'W1216',   null,               null,               null,              null,        null
insert into @ttEDIPM select 'ADDEDIFIELD',   'W12',       null,               'W1217',   null,               null,               null,              null,        null
insert into @ttEDIPM select 'ADDEDIFIELD',   'W12',       null,               'W1218',   null,               null,               null,              null,        null
insert into @ttEDIPM select 'ADDEDIFIELD',   'W12',       null,               'W1219',   null,               null,               null,              null,        null
insert into @ttEDIPM select 'ADDEDIFIELD',   'W12',       null,               'W1220',   null,               null,               null,              null,        null
insert into @ttEDIPM select 'ADDEDIFIELD',   'W12',       null,               'W1221',   null,               null,               null,              null,        null
insert into @ttEDIPM select 'ADDEDIFIELD',   'W12',       null,               'W1222',   null,               null,               null,              null,        null
*/
/* Save the current Pick Ticket value.
This will be used to determine whether there is a need for a new ST segment when the next record is encountered */
insert into @ttEDIPM select 'SAVEDATA',      'W12',       'RecordType=ShipLPND',null,    'LPN',              'CurrentLPN',       null,              null,        null
insert into @ttEDIPM select 'SAVEDATA',      'W12',       null,               null,      'PickTicket',       'CurrentPT',        null,              null,        null

/* LOOP end */
/* LOOP end */
/* LOOP end */

insert into @ttEDIPM select 'NEWEDISEGMENT', 'W03',       'RecordType=ShipOH',null,      null,               null,               null,              null,        null
/* Total Number of Units Shipped
TODO Need to enhance ShipOH export to sent totals in UnistAssigned export column */
insert into @ttEDIPM select 'ADDEDIFIELD',   'W03',       'RecordType=ShipOH','W0301',   'TransQty',         null,               null,              null,        null
/* Total Weight
TODO Need to enhance the Export record to send Total Order Weight in Weight Column */
insert into @ttEDIPM select 'ADDEDIFIELD',   'W03',       'RecordType=ShipOH','W0302',   'Weight',           null,               null,              null,        null
/* UoM KG or Pounds
  Defaulted to Pounds */
insert into @ttEDIPM select 'ADDEDIFIELD',   'W03',       'RecordType=ShipOH','W0303',   null,               null,               'LB',              null,        null
/*
insert into @ttEDIPM select 'ADDEDIFIELD',   'W03',       null,               'W0304',   null,               null,               null,              null,        null
insert into @ttEDIPM select 'ADDEDIFIELD',   'W03',       null,               'W0305',   null,               null,               null,              null,        null
insert into @ttEDIPM select 'ADDEDIFIELD',   'W03',       null,               'W0306',   null,               null,               null,              null,        null
insert into @ttEDIPM select 'ADDEDIFIELD',   'W03',       null,               'W0307',   null,               null,               null,              null,        null
*/

insert into @ttEDIPM select 'NEWEDISEGMENT', 'SE',        'RecordType=ShipOH',null,      null,               null,               null,              null,        null
insert into @ttEDIPM select 'ADDEDIFIELD',   'SE',        'RecordType=ShipOH','SE01',    null,               null,               '[SegmentCount945]',null,       null
insert into @ttEDIPM select 'ADDEDIFIELD',   'SE',        'RecordType=ShipOH','SE02',    null,               null,               '[STControlNumber945]',null,    null

exec pr_EDI_SetupProfileMap @vProfileName, @vEDITransaction, @ttEDIPM, 'R' /* Action - Add */, @vBusinessUnit;

Go
