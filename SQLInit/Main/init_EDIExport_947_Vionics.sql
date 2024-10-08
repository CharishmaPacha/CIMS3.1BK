/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2016/01/07  NB      Initial Revision(NBD-43)
------------------------------------------------------------------------------*/

Go

  declare @vEDIDirection        TName,
          @vEDITransaction      TName,
          @vEDISenderId         TName,
          @vProfileName         TName,
          @vBusinessUnit        TBusinessUnit;

  declare @ttEDIPM              TEDIProcessMap;

select @vEDISenderId    = 'Vasyli',
       @vEDITransaction = '947',
       @vEDIDirection   = 'Export',
       @vBusinessUnit   = 'NBD',
       @vProfileName    = 'Vasyli947';

/*------------------------------------------------------------------------------*/
/* Add criteria */
/*------------------------------------------------------------------------------*/
exec pr_EDI_ManageProfileRule @vEDISenderId, @vEDITransaction, @vEDIDirection, @vProfileName, 'U' /* Action - add/udpate */, @vBusinessUnit;

/*------------------------------------------------------------------------------*/
/* 947 Mapping for Generic */
/*------------------------------------------------------------------------------*/

/*                            ProcessAction,  SegmentId,  ProcessConditions,  ElementId, CIMSXMLField,       CIMSFieldName,      DefaultValue,      CIMSXMLPath, EDIElementDesc */

insert into @ttEDIPM select  'NEWEDISEGMENT', 'ST',       null,               null,      null,               null,               null,              null,        null
insert into @ttEDIPM select  'ADDEDIFIELD',   'ST',       null,               'ST01',    null,               null,               '947',             null,        null
insert into @ttEDIPM select  'ADDEDIFIELD',   'ST',       null,               'ST02',    null,               null,               '[STControlNumber947]',null,    null

insert into @ttEDIPM select  'NEWEDISEGMENT', 'W15',      null,               null,      null,               null,               null,              null,        null
insert into @ttEDIPM select  'ADDEDIFIELD',   'W15',      null,               'W1501',   'TransDateTime',    null,               null,              null,        null
/* 'ZZ' is the code for 'Mutually Defined' */
insert into @ttEDIPM select  'ADDEDIFIELD',   'W15',      null,               'W1504',   null,               null,               'ZZ',              null,        null
/* CO is the code for Correction */
insert into @ttEDIPM select  'ADDEDIFIELD',   'W15',      null,               'W1505',   null,               null,               'CO',              null,        null
/* 2 is the code for Change (update)
insert into @ttEDIPM select  'ADDEDIFIELD',   'W15',      null,               'W1506',   null,               null,               '2',               null,        null
*/

insert into @ttEDIPM select  'NEWEDISEGMENT', 'N1',       null,               null,      null,               null,               null,              null,        null
/* WH is the code for Warehouse */
insert into @ttEDIPM select  'ADDEDIFIELD',   'N1',       null,               'N101',    null,               null,               'WH',              null,        null
insert into @ttEDIPM select  'ADDEDIFIELD',   'N1',       null,               'N102',    null,               null,               'NB3PL',           null,        null
insert into @ttEDIPM select  'ADDEDIFIELD',   'N1',       null,               'N103',    null,               null,               '92',              null,        null
insert into @ttEDIPM select  'ADDEDIFIELD',   'N1',       null,               'N102',    'Warehouse',        null,               null,              null,        null

insert into @ttEDIPM select  'NEWEDISEGMENT', 'G62',      null,               null,      null,               null,               null,              null,        null
/* '07' - Transaction Control Date */
insert into @ttEDIPM select  'ADDEDIFIELD',   'G62',      null,               'G6201',   null,               null,               '07',              null,        null
insert into @ttEDIPM select  'ADDEDIFIELD',   'G62',      null,               'G6202',   'TransDateTime',    null,               null,              null,        null


insert into @ttEDIPM select  'NEWEDISEGMENT', 'W19',      null,               null,      null,               null,               null,              null,        null
/* '06' Debit Code */
insert into @ttEDIPM select  'ADDEDIFIELD',   'W19',      null,               'W1901',   null,               null,               '06',              null,        null
insert into @ttEDIPM select  'ADDEDIFIELD',   'W19',      null,               'W1902',   'TransQty',         null,               null,              null,        null
/* 'EA'- Each */
insert into @ttEDIPM select  'ADDEDIFIELD',   'W19',      null,               'W1903',   null,               null,               'EA',              null,        null
/* UP - GTIN-12 */
insert into @ttEDIPM select  'ADDEDIFIELD',   'W19',      null,               'W1905',   null,               null,               'UP',              null,        null
insert into @ttEDIPM select  'ADDEDIFIELD',   'W19',      null,               'W1906',   'UPC',              null,               null,              null,        null
/* SA Saleable Inventory code */
insert into @ttEDIPM select  'ADDEDIFIELD',   'W19',      null,               'W1916',   null,               null,               'SA',              null,        null

insert into @ttEDIPM select  'NEWEDISEGMENT', 'N9',       null,               null,      null,               null,               null,              null,        null
/* ZZ is the code for 'Mutually Defined */
insert into @ttEDIPM select  'ADDEDIFIELD',   'N9',       null,               'N901',    null,               null,               'ZZ',              null,        null
insert into @ttEDIPM select  'ADDEDIFIELD',   'N9',       null,               'N902',    null,               null,               'SKU',             null,        null
insert into @ttEDIPM select  'ADDEDIFIELD',   'N9',       null,               'N903',    'SKU',              null,               null,              null,        null

insert into @ttEDIPM select  'NEWEDISEGMENT', 'N9',       null,               null,      null,               null,               null,              null,        null
/* ZZ is the code for 'Mutually Defined */
insert into @ttEDIPM select  'ADDEDIFIELD',   'N9',       null,               'N901',    null,               null,               'ZZ',              null,        null
insert into @ttEDIPM select  'ADDEDIFIELD',   'N9',       null,               'N902',    null,               null,               'BIN',             null,        null
insert into @ttEDIPM select  'ADDEDIFIELD',   'N9',       null,               'N903',    'Location',         null,               null,              null,        null
/*
TODO TODO

N9*ZZ*ITX*2880775
N9*ZZ*UPT*3809946  (record #)
N9*ZZ*REC*SYSTEM  (Type of transaction)
N9*ZZ*BTY*PICKING (Bin type)
*/

/* Time of Transaction */
insert into @ttEDIPM select  'NEWEDISEGMENT', 'N9',       null,               null,      null,               null,               null,              null,        null
/* ZZ is the code for 'Mutually Defined */
insert into @ttEDIPM select  'ADDEDIFIELD',   'N9',       null,               'N901',    null,               null,               'ZZ',              null,        null
insert into @ttEDIPM select  'ADDEDIFIELD',   'N9',       null,               'N902',    null,               null,               'TTM',             null,        null
insert into @ttEDIPM select  'ADDEDIFIELD',   'N9',       null,               'N903',    'TransDateTime',    null,               null,              null,        null
/*
TODO TODO TODO
N9*ZZ*CMP*NBD-VSL-MGR04 (computer)
N9*ZZ*USR*IDOMINGUEZ  (User name)
*/

insert into @ttEDIPM select  'NEWEDISEGMENT', 'SE',       null,               null,      null,               null,               null,              null,        null
insert into @ttEDIPM select  'ADDEDIFIELD',   'SE',       null,               'SE01',    null,               null,               '[SegmentCount947]',null,       null
insert into @ttEDIPM select  'ADDEDIFIELD',   'SE',       null,               'SE02',    null,               null,               '[STControlNumber947]',null,    null

exec pr_EDI_SetupProfileMap @vProfileName, @vEDITransaction, @ttEDIPM, 'R' /* Action - Add */, @vBusinessUnit;

Go