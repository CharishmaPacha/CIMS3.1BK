/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2016/03/30  NB      Removed CIMS XML field to N104 to send default value 'NB3PL'(NBD-43)
  2016/03/29  NB      (NBD-43)
                      Mapping changes to create single ST/SE, and other segments
                      Minor changes changes (W1502, W1503 -> ExportBatch)
  2016/02/15  NB      Added process map rule for W1503(NBD-43)
  2016/02/05  NB      (NBD-43)
                      Removed SINGLEST declaration for creation of proper EDI output
                      Revised mapping considering the updated specs from NBD
  2016/01/07  NB      Added SINGLEST declaration to club all records under one Transaction set(NBD-43)
  2016/01/07  NB      Initial Revision(NBD-43)
------------------------------------------------------------------------------*/

Go

  declare @vEDIDirection        TName,
          @vEDITransaction      TName,
          @vEDISenderId         TName,
          @vProfileName         TName,
          @vBusinessUnit        TBusinessUnit;

  declare @ttEDIPM              TEDIProcessMap;

select @vEDISenderId    = 'NBD',
       @vEDITransaction = '947',
       @vEDIDirection   = 'Export',
       @vBusinessUnit   = 'NBD',
       @vProfileName    = 'Generic947';

/*------------------------------------------------------------------------------*/
/* Add criteria */
/*------------------------------------------------------------------------------*/
exec pr_EDI_ManageProfileRule @vEDISenderId, @vEDITransaction, @vEDIDirection, @vProfileName, 'U' /* Action - add/udpate */, @vBusinessUnit;
exec pr_EDI_ManageProfileRule 'Chrome',      @vEDITransaction, @vEDIDirection, @vProfileName, 'U' /* Action - add/udpate */, @vBusinessUnit;
exec pr_EDI_ManageProfileRule 'KUIU',        @vEDITransaction, @vEDIDirection, @vProfileName, 'U' /* Action - add/udpate */, @vBusinessUnit;

/*------------------------------------------------------------------------------*/
/* 947 Mapping for Generic */
/*------------------------------------------------------------------------------*/

/*                            ProcessAction,  SegmentId,  ProcessConditions,  ElementId, CIMSXMLField,       CIMSFieldName,      DefaultValue,      CIMSXMLPath, EDIElementDesc */

insert into @ttEDIPM select 'SAVEDATA',       'ST',      'ExportBatch![CurrentBatch]',null, null,               'CreateNew',        'Y,N',             null,        null
/* 'SINGLEST' in the default value column indicates that all the InvCh records are clubbed together into one ST
   If default value is empty, then each record is treated as individual and one ST is created */
insert into @ttEDIPM select 'NEWEDISEGMENT', 'ST',        '[CreateNew]=Y',               null,      null,               null,               'SINGLEST',            null,        null
insert into @ttEDIPM select 'ADDEDIFIELD',   'ST',        '[CreateNew]=Y',               'ST01',    null,               null,               '947',                 null,        null
insert into @ttEDIPM select 'ADDEDIFIELD',   'ST',        '[CreateNew]=Y',               'ST02',    null,               null,               '[STControlNumber947]',null,        null

insert into @ttEDIPM select  'NEWEDISEGMENT', 'W15',      '[CreateNew]=Y',               null,      null,               null,               null,                  null,        null
insert into @ttEDIPM select  'ADDEDIFIELD',   'W15',      '[CreateNew]=Y',               'W1501',   'TransDateTime',    null,               null,                  null,        null
/* Adjustment Number assigned by Warehouse
   Both 02 and 03 are required, therefore we are assigned the same value to these 2 elements
 */
insert into @ttEDIPM select  'ADDEDIFIELD',   'W15',      '[CreateNew]=Y',               'W1502',   'ExportBatch',         null,               null,                  null,        null
insert into @ttEDIPM select  'ADDEDIFIELD',   'W15',      '[CreateNew]=Y',               'W1503',   'ExportBatch',         null,               null,                  null,        null
/* Adjustment Number assigned by Depositor
This has to be enabled and setup, if need be.
insert into @ttEDIPM select  'ADDEDIFIELD',   'W15',      null,               'W1503',   'AdjustmentNumber', null,               null,              null,        null
*/
/*
insert into @ttEDIPM select  'ADDEDIFIELD',   'W15',      null,               'W1504',   null,               null,               '04',              null,        null
*/
/* ZZ is the code for Mutually defined */
insert into @ttEDIPM select  'ADDEDIFIELD',   'W15',      '[CreateNew]=Y',               'W1505',   null,               null,               'ZZ',              null,        null
/* CO is the code for 'Correct' */
insert into @ttEDIPM select  'ADDEDIFIELD',   'W15',      '[CreateNew]=Y',               'W1506',   null,               null,               'CO',               null,        null

insert into @ttEDIPM select  'NEWEDISEGMENT', 'N1',       '[CreateNew]=Y',               null,      null,               null,               null,              null,        null
/* WH is the code for Warehouse */
insert into @ttEDIPM select  'ADDEDIFIELD',   'N1',       '[CreateNew]=Y',               'N101',    null,               null,               'WH',              null,        null
insert into @ttEDIPM select  'ADDEDIFIELD',   'N1',       '[CreateNew]=Y',               'N102',    null,               null,               'NB3PL',           null,        null
insert into @ttEDIPM select  'ADDEDIFIELD',   'N1',       '[CreateNew]=Y',               'N103',    null,               null,               '92',              null,        null
insert into @ttEDIPM select  'ADDEDIFIELD',   'N1',       '[CreateNew]=Y',               'N104',    null,               null,               'NB3PL',           null,        null
/*
insert into @ttEDIPM select  'NEWEDISEGMENT', 'N1',       null,               null,      null,               null,               null,              null,        null
* ZZ is the code for 'Mutually Defined *
insert into @ttEDIPM select  'ADDEDIFIELD',   'N1',       null,               'N103',    null,               null,               'ZZ',              null,        null
insert into @ttEDIPM select  'ADDEDIFIELD',   'N1',       null,               'N104',    'UPC',              null,               null,              null,        null
*/

/* SKU	SKU # */
insert into @ttEDIPM select  'NEWEDISEGMENT', 'N9',       null,               null,      null,               null,               null,              null,        null
/* ZZ is the code for 'Mutually Defined */
insert into @ttEDIPM select  'ADDEDIFIELD',   'N9',       null,               'N901',    null,               null,               'ZZ',              null,        null
insert into @ttEDIPM select  'ADDEDIFIELD',   'N9',       null,               'N902',    null,               null,               'SKU',              null,        null
insert into @ttEDIPM select  'ADDEDIFIELD',   'N9',       null,               'N903',    'SKU',              null,               null,              null,        null

/* BIN	Location in WH */
insert into @ttEDIPM select  'NEWEDISEGMENT', 'N9',       null,               null,      null,               null,               null,              null,        null
/* ZZ is the code for 'Mutually Defined */
insert into @ttEDIPM select  'ADDEDIFIELD',   'N9',       null,               'N901',    null,               null,               'ZZ',              null,        null
insert into @ttEDIPM select  'ADDEDIFIELD',   'N9',       null,               'N902',    null,               null,               'BIN',              null,        null
insert into @ttEDIPM select  'ADDEDIFIELD',   'N9',       null,               'N903',    'Location',         null,               null,              null,        null

/* ITX	Internal  Inventory Transaction ID

insert into @ttEDIPM select  'NEWEDISEGMENT', 'N9',       null,               null,      null,               null,               null,              null,        null
* ZZ is the code for 'Mutually Defined *
insert into @ttEDIPM select  'ADDEDIFIELD',   'N9',       null,               'N901',    null,               null,               'ZZ',              null,        null
insert into @ttEDIPM select  'ADDEDIFIELD',   'N9',       null,               'N902',    null,               null,               'ITX',              null,        null
insert into @ttEDIPM select  'ADDEDIFIELD',   'N9',       null,               'N903',    'RecordId',         null,               null,              null,        null
*/
/* UPT	Internal  Item Code *
TODO TODO TODO
insert into @ttEDIPM select  'NEWEDISEGMENT', 'N9',       null,               null,      null,               null,               null,              null,        null
* ZZ is the code for 'Mutually Defined *
insert into @ttEDIPM select  'ADDEDIFIELD',   'N9',       null,               'N901',    null,               null,               'ZZ',              null,        null
insert into @ttEDIPM select  'ADDEDIFIELD',   'N9',       null,               'N902',    null,               null,               'UPT',              null,        null
insert into @ttEDIPM select  'ADDEDIFIELD',   'N9',       null,               'N903',    '',                 null,               null,              null,        null
*/
/* REC	Perform By *
TODO TODO TODO
insert into @ttEDIPM select  'NEWEDISEGMENT', 'N9',       null,               null,      null,               null,               null,              null,        null
* ZZ is the code for 'Mutually Defined *
insert into @ttEDIPM select  'ADDEDIFIELD',   'N9',       null,               'N901',    null,               null,               'ZZ',              null,        null
insert into @ttEDIPM select  'ADDEDIFIELD',   'N9',       null,               'N902',    null,               null,               'REC',              null,        null
insert into @ttEDIPM select  'ADDEDIFIELD',   'N9',       null,               'N903',    '',                 null,               null,              null,        null
*/
/* BTY	Bin Type *
TODO TODO TODO
insert into @ttEDIPM select  'NEWEDISEGMENT', 'N9',       null,               null,      null,               null,               null,              null,        null
* ZZ is the code for 'Mutually Defined *
insert into @ttEDIPM select  'ADDEDIFIELD',   'N9',       null,               'N901',    null,               null,               'ZZ',              null,        null
insert into @ttEDIPM select  'ADDEDIFIELD',   'N9',       null,               'N902',    null,               null,               'BTY',              null,        null
insert into @ttEDIPM select  'ADDEDIFIELD',   'N9',       null,               'N903',    '',                 null,               null,              null,        null
*/
/* TTM	Date & Time Stamp */
insert into @ttEDIPM select  'NEWEDISEGMENT', 'N9',       null,               null,      null,               null,               null,              null,        null
/* ZZ is the code for 'Mutually Defined */
insert into @ttEDIPM select  'ADDEDIFIELD',   'N9',       null,               'N901',    null,               null,               'ZZ',              null,        null
insert into @ttEDIPM select  'ADDEDIFIELD',   'N9',       null,               'N902',    null,               null,               'TTM',              null,        null
insert into @ttEDIPM select  'ADDEDIFIELD',   'N9',       null,               'N903',    'TransDateTime',    null,               null,              null,        null

/* CMP	Computer *
TODO TODO TODO
insert into @ttEDIPM select  'NEWEDISEGMENT', 'N9',       null,               null,      null,               null,               null,              null,        null
* ZZ is the code for 'Mutually Defined *
insert into @ttEDIPM select  'ADDEDIFIELD',   'N9',       null,               'N901',    null,               null,               'ZZ',              null,        null
insert into @ttEDIPM select  'ADDEDIFIELD',   'N9',       null,               'N902',    null,               null,               'CMP',              null,        null
insert into @ttEDIPM select  'ADDEDIFIELD',   'N9',       null,               'N903',    '',                 null,               null,              null,        null
*/
/* USE	User */
insert into @ttEDIPM select  'NEWEDISEGMENT', 'N9',       null,               null,      null,               null,               null,              null,        null
/* ZZ is the code for 'Mutually Defined */
insert into @ttEDIPM select  'ADDEDIFIELD',   'N9',       null,               'N901',    null,               null,               'ZZ',              null,        null
insert into @ttEDIPM select  'ADDEDIFIELD',   'N9',       null,               'N902',    null,               null,               'USE',              null,        null
insert into @ttEDIPM select  'ADDEDIFIELD',   'N9',       null,               'N903',    'CreatedBy',        null,               null,              null,        null

insert into @ttEDIPM select  'NEWEDISEGMENT', 'G62',      null,               null,      null,               null,               null,              null,        null
/* '07'  Effective Date */
insert into @ttEDIPM select  'ADDEDIFIELD',   'G62',      null,               'G6201',   null,               null,               '07',              null,        null
insert into @ttEDIPM select  'ADDEDIFIELD',   'G62',      null,               'G6202',   'TransDateTime',    null,               null,              null,        null

/*
Spec document says Not Presently Used
insert into @ttEDIPM select  'NEWEDISEGMENT', 'NTE',      null,                null,      null,              null,               null,              null,        null
* 'ALL'  All Documents *
insert into @ttEDIPM select  'ADDEDIFIELD',   'NTE',      null,               'NTE01',   null,               null,               'ALL',              null,        null
insert into @ttEDIPM select  'ADDEDIFIELD',   'NTE',      null,               'NTE02',   'Comments',         null,               null,              null,        null
*/

insert into @ttEDIPM select  'NEWEDISEGMENT', 'W19',      null,               null,      null,               null,               null,              null,        null
/* TODO TODO TODO
  EDI file expects different reason code values
  There must be a tranformation of the CIMS Reason code to Host Reason code in the output
*/
insert into @ttEDIPM select  'ADDEDIFIELD',   'W19',      null,               'W1901',   'ReasonCode',       null,               null,              null,        null
insert into @ttEDIPM select  'ADDEDIFIELD',   'W19',      null,               'W1902',   'TransQty',         null,               null,              null,        null
/* TODO TODO TODO
The host expects the following
Code  	Name
AS 	Assortment
CA 	Case
EA 	Each
KT	KIt
YD	Yard

These must be returned in the UoM record field, after transforming from cims to host value
*/
insert into @ttEDIPM select  'ADDEDIFIELD',   'W19',      null,               'W1903',   'UoM',              null,               null,              null,        null
/* UPC Case Code *
TODO TODO TODO
Not mapped currently.
insert into @ttEDIPM select  'ADDEDIFIELD',   'W19',      null,               'W1904',   null,               null,               null,              null,        null
*/
/* UP - is for UPC Code */
insert into @ttEDIPM select  'ADDEDIFIELD',   'W19',      null,               'W1905',   null,               null,               'UP',              null,        null
insert into @ttEDIPM select  'ADDEDIFIELD',   'W19',      null,               'W1906',   'UPC',              null,               null,              null,        null
/* LT - Lot Number
   Add LotNumber information, only when LotNumber value is present  */
insert into @ttEDIPM select  'ADDEDIFIELD',   'W19',      'LotNumber!',       'W1907',   null,               null,               'LT',              null,        null
insert into @ttEDIPM select  'ADDEDIFIELD',   'W19',      'LotNumber!',       'W1908',   'LotNumber',        null,               null,              null,        null
/* SA Saleable Inventory */
insert into @ttEDIPM select  'ADDEDIFIELD',   'W19',      null,               'W1916',   null,               null,               'SA',              null,        null

insert into @ttEDIPM select 'SAVEDATA',       'W19',      null,               null,      'ExportBatch',     'CurrentBatch',      null,              null,        null

insert into @ttEDIPM select  'NEWEDISEGMENT', 'SE',       null,               null,      null,               null,               null,              null,        null
insert into @ttEDIPM select  'ADDEDIFIELD',   'SE',       null,               'SE01',    null,               null,               '[SegmentCount947]',null,       null
insert into @ttEDIPM select  'ADDEDIFIELD',   'SE',       null,               'SE02',    null,               null,               '[STControlNumber947]',null,    null

exec pr_EDI_SetupProfileMap @vProfileName, @vEDITransaction, @ttEDIPM, 'R' /* Action - Add */, @vBusinessUnit;

Go
