/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2016/05/19  NB      Mapping changes from Diane's feedback(NBD-89)
  2016/05/09  NB      Mapping changes from Diane's feedback (NBD-89)
  2016/04/14  NB      (NBD-89)
                      Mapping changes to read summary record type for receiving
                      Changes to send PO at the for each Detail
  2016/03/15  NB      Initial Revision(NBD-89)

  861 Implementation

  The assumption is the CIMS XML will contain 'RecvRV' transactions. All records
  for a ReceiptId are in sequence.
------------------------------------------------------------------------------*/

Go

  declare @vEDIDirection        TName,
          @vEDITransaction      TName,
          @vEDISenderId         TName,
          @vProfileName         TName,
          @vBusinessUnit        TBusinessUnit;

  declare @ttEDIPM              TEDIProcessMap;

select @vEDISenderId    = 'NBD',
       @vEDITransaction = '861',
       @vEDIDirection   = 'Export',
       @vBusinessUnit   = 'NBD',
       @vProfileName    = 'Generic861';

/*------------------------------------------------------------------------------*/
/* Add criteria */
/*------------------------------------------------------------------------------*/
exec pr_EDI_ManageProfileRule @vEDISenderId, @vEDITransaction, @vEDIDirection, @vProfileName, 'U' /* Action - add/udpate */, @vBusinessUnit;
exec pr_EDI_ManageProfileRule 'Vasyli',      @vEDITransaction, @vEDIDirection, @vProfileName, 'U' /* Action - add/udpate */, @vBusinessUnit;

/*------------------------------------------------------------------------------*/
/* 861 Mapping for Generic */
/*------------------------------------------------------------------------------*/

/*                          ProcessAction,   SegmentId,  ProcessConditions,  ElementId, CIMSXMLField,       CIMSFieldName,      DefaultValue,      CIMSXMLPath, EDIElementDesc */

/*
*/
/* Below statement will be evaluated as below by EDI Exchange
   The condition 'ReceiptNumber![CurrentReceiptNum]' is evaluated considering the value of ReceiptNumber in the Record values and saved value with the name 'CurrentReceiptNum'
   The result of this statement processing is a new value saved in memory, called 'CreateNew', and updated for each record in the XML
   The DefaultValue column has two values seperated by comma Y,N.
   If the condition result is true, then the first value Y is stored in the new flag 'CreateNew'
   If the condition result is false, then the first value N is stored in the new flag 'CreateNew'
*/
insert into @ttEDIPM select 'SAVEDATA',      'ST',       'RecordType=RecvRV;ReceiptNumber![CurrentReceiptNum]',null,null,     'CreateNew',        'Y,N',             null,        null

/* '[CreateNew]=Y;[CurrentReceiptNum]!' */
insert into @ttEDIPM select 'NEWEDISEGMENT', 'SE',       '[CreateNew]=Y;[CurrentReceiptNum]!',null,null,    null,               null,              null,        null
insert into @ttEDIPM select 'ADDEDIFIELD',   'SE',       '[CreateNew]=Y;[CurrentReceiptNum]!','SE01',null,  null,               '[SegmentCount861]',null,       null
insert into @ttEDIPM select 'ADDEDIFIELD',   'SE',       '[CreateNew]=Y;[CurrentReceiptNum]!','SE02',null,  null,               '[STControlNumber861]',null,    null

insert into @ttEDIPM select 'NEWEDISEGMENT', 'ST',       '[CreateNew]=Y',    null,      null,               null,                null,             null,        null
insert into @ttEDIPM select 'ADDEDIFIELD',   'ST',       '[CreateNew]=Y',    'ST01',    null,               null,               '861',             null,        null
insert into @ttEDIPM select 'ADDEDIFIELD',   'ST',       '[CreateNew]=Y',    'ST02',    null,               null,               '[STControlNumber861]',null,    null

insert into @ttEDIPM select 'NEWEDISEGMENT', 'BRA',      '[CreateNew]=Y',    null,      null,               null,               null,              null,        null
insert into @ttEDIPM select 'ADDEDIFIELD',   'BRA',      '[CreateNew]=Y',    'BRA01',   'ExportBatch',      null,               null,              null,        null
insert into @ttEDIPM select 'ADDEDIFIELD',   'BRA',      '[CreateNew]=Y',    'BRA02',   'TransDateTime',    null,               null,              null,        null
/* If the owner is Vasyli, then code is MR else it is ZZ */
insert into @ttEDIPM select 'ADDEDIFIELD',   'BRA',      '[CreateNew]=Y;Ownership=VSL','BRA03',null,        null,               'MR',              null,        null
insert into @ttEDIPM select 'ADDEDIFIELD',   'BRA',      '[CreateNew]=Y;Ownership!VSL','BRA03',null,        null,               'ZZ',              null,        null
/* 1 is the code Receiving Dock Advice */
insert into @ttEDIPM select 'ADDEDIFIELD',   'BRA',      '[CreateNew]=Y',    'BRA04',   null,               null,               '1',               null,        null
insert into @ttEDIPM select 'UNMAPPED',      'BRA',      '[CreateNew]=Y',    'BRA05',   'TransDateTime',    null,               null,              null,        null

insert into @ttEDIPM select 'NEWEDISEGMENT', 'DTM',      '[CreateNew]=Y',    null,      null,               null,               null,              null,        null
/* 371 is code for Received */
insert into @ttEDIPM select 'ADDEDIFIELD',   'DTM',      '[CreateNew]=Y',    'DTM01',   null,               null,               '371',             null,        null
/* Date */
insert into @ttEDIPM select 'ADDEDIFIELD',   'DTM',      '[CreateNew]=Y',    'DTM02',   'TransDateTime',    null,               null,              null,        null
/* Time */
insert into @ttEDIPM select 'UNMAPPED',      'DTM',      '[CreateNew]=Y',    'DTM03',   'TransDateTime',    null,               null,              null,        null

insert into @ttEDIPM select 'NEWEDISEGMENT', 'TD1',      '[CreateNew]=Y',    null,      null,               null,               null,              null,        null
insert into @ttEDIPM select 'ADDEDIFIELD',   'TD1',      '[CreateNew]=Y',    'TD101',   'RH_UDF3',          null,               null,              null,        null
insert into @ttEDIPM select 'ADDEDIFIELD',   'TD1',      '[CreateNew]=Y',    'TD102',   'RH_UDF4',          null,               null,              null,        null

insert into @ttEDIPM select 'UNMAPPED',      'TD5',      '[CreateNew]=Y',    'TD501',   null,               null,               null,              null,        null
insert into @ttEDIPM select 'UNMAPPED',      'TD5',      '[CreateNew]=Y',    'TD502',   null,               null,               null,              null,        null
insert into @ttEDIPM select 'UNMAPPED',      'TD5',      '[CreateNew]=Y',    'TD503',   null,               null,               null,              null,        null
insert into @ttEDIPM select 'UNMAPPED',      'TD5',      '[CreateNew]=Y',    'TD504',   null,               null,               null,              null,        null
insert into @ttEDIPM select 'UNMAPPED',      'TD5',      '[CreateNew]=Y',    'TD505',   null,               null,               null,              null,        null


insert into @ttEDIPM select 'NEWEDISEGMENT', 'RCD',      'RecordType=RecvRV', null,      null,               null,               null,              null,        null
/* Spec says Not used */
insert into @ttEDIPM select 'UNMAPPED',      'RCD',      'RecordType=RecvRV', 'RCD01',   null,               null,               null,              null,        null
/* Received Qty */
insert into @ttEDIPM select 'ADDEDIFIELD',   'RCD',      'RecordType=RecvRV', 'RCD02',   'TransQty',         null,               null,              null,        null
/* EA is the code for Each */
insert into @ttEDIPM select 'ADDEDIFIELD',   'RCD',      'RecordType=RecvRV', 'RCD03',   null,               null,               'EA',              null,        null
insert into @ttEDIPM select 'UNMAPPED',      'RCD',      'RecordType=RecvRV', 'RCD04',   null,               null,               null,              null,        null
insert into @ttEDIPM select 'UNMAPPED',      'RCD',      'RecordType=RecvRV', 'RCD05',   null,               null,               null,              null,        null
insert into @ttEDIPM select 'UNMAPPED',      'RCD',      'RecordType=RecvRV', 'RCD06',   null,               null,               null,              null,        null
insert into @ttEDIPM select 'UNMAPPED',      'RCD',      'RecordType=RecvRV', 'RCD07',   null,               null,               null,              null,        null
/* 07 is the code for Good Condition. This is assumed if there is no reason code in the transaction
   The reasoncode, if any, must be transformed into proper values
   07 - Good Condition
   08 - Rejected
   09 - On hold
*/
insert into @ttEDIPM select 'ADDEDIFIELD',   'RCD',      'RecordType=RecvRV', 'RCD08',   'ReasonCode',       null,               '07',              null,        null

/* Spec says Not used */
insert into @ttEDIPM select 'UNMAPPED',      'SN1',      'RecordType=RecvRV', null,      null,               null,               null,              null,        null
insert into @ttEDIPM select 'UNMAPPED',      'SN1',      'RecordType=RecvRV', 'SN101',   null,               null,               null,              null,        null
insert into @ttEDIPM select 'UNMAPPED',      'SN1',      'RecordType=RecvRV', 'SN102',   null,               null,               null,              null,        null
insert into @ttEDIPM select 'UNMAPPED',      'SN1',      'RecordType=RecvRV', 'SN103',   null,               null,               null,              null,        null

insert into @ttEDIPM select 'NEWEDISEGMENT', 'LIN',      'RecordType=RecvRV', null,      null,               null,               null,              null,        null
/* Spec says Not used */
insert into @ttEDIPM select 'UNMAPPED',      'LIN',      'RecordType=RecvRV', 'LIN01',   null,               null,               null,              null,        null
/* UP is the code for UPC code */
insert into @ttEDIPM select 'ADDEDIFIELD',   'LIN',      'RecordType=RecvRV', 'LIN02',   null,               null,               'UP',              null,        null
insert into @ttEDIPM select 'ADDEDIFIELD',   'LIN',      'RecordType=RecvRV', 'LIN03',   'UPC',              null,               null,              null,        null
/* Spec says Not used */
insert into @ttEDIPM select 'UNMAPPED',      'LIN',      'RecordType=RecvRV', 'LIN04',   null,               null,               null,              null,        null
insert into @ttEDIPM select 'UNMAPPED',      'LIN',      'RecordType=RecvRV', 'LIN05',   null,               null,               null,              null,        null

/*
Spec says Not used at NBD
insert into @ttEDIPM select 'NEWEDISEGMENT', 'PID',      'RecordType=RecvRV', null,      null,               null,               null,              null,        null
*/

/*
Spec mentions that this is to be used at the header level
whereas all the samples show this to be used at the line level

Going by the spec for now
*/
insert into @ttEDIPM select 'NEWEDISEGMENT', 'REF',      'RecordType=RecvRV;CustPO!',null,null,              null,               null,              null,        null
insert into @ttEDIPM select 'ADDEDIFIELD',   'REF',      'RecordType=RecvRV;CustPO!','REF01',null,           null,               'PO',              null,        null
/* If Cust PO is present, then read it into REF02
   If Cust PO is NOT present, then read it ReceiptNumber, which is the PO Number for 850 */
insert into @ttEDIPM select 'ADDEDIFIELD',   'REF',      'RecordType=RecvRV;CustPO!','REF02','CustPO',       null,               null,              null,        null
insert into @ttEDIPM select 'UNMAPPED',      'REF',      'RecordType=RecvRV',    'REF03',   'Description',   null,               null,              null,        null

insert into @ttEDIPM select 'NEWEDISEGMENT', 'REF',      'RecordType=RecvRV;RD_UDF5!',    null,      null,      null,               null,              null,        null
insert into @ttEDIPM select 'ADDEDIFIELD',   'REF',      'RecordType=RecvRV;RD_UDF5!',    'REF01',   null,      null,               'CO',              null,        null
/* In the case of ASN ROs, the ShipmentId is sent back in 861 as CO */
insert into @ttEDIPM select 'ADDEDIFIELD',   'REF',      'RecordType=RecvRV;RD_UDF5!','REF02', 'RD_UDF5',      null,                null,              null,        null
insert into @ttEDIPM select 'UNMAPPED',      'REF',      'RecordType=RecvRV',    'REF03',   'Description',  null,                null,              null,        null

/*
Spec says Not used
insert into @ttEDIPM select 'NEWEDISEGMENT', 'CTT',      '[CreateNew]=Y',    null,      null,               null,               null,              null,        null
*/

insert into @ttEDIPM select 'SAVEDATA',      null,       'RecordType=RecvRV', null,      'ReceiptNumber',    'CurrentReceiptNum',null,              null,        null

exec pr_EDI_SetupProfileMap @vProfileName, @vEDITransaction, @ttEDIPM, 'R' /* Action - Add */, @vBusinessUnit;

Go
