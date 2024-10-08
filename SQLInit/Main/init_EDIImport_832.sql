/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2016/06/10  NB      Introduced mapping for CoO(NBD-601)
  2016/03/30  NB      Mapping changes to Ownerhip(NBD-317)
  2015/12/22  NB      BusinessUnit - defaulted to NBD
                      UDF1 - Passing in SenderId, to be used for Ownership
  2015/11/02  AY      Initial Revision
------------------------------------------------------------------------------*/

Go

  declare @vEDIDirection        TName,
          @vEDITransaction      TName,
          @vEDISenderId         TName,
          @vProfileName         TName,
          @vBusinessUnit        TBusinessUnit;

  declare @ttEDIPM              TEDIProcessMap;

select @vEDISenderId    = 'Chrome',
       @vEDITransaction = '832',
       @vEDIDirection   = 'Import',
       @vBusinessUnit   = 'NBD',
       @vProfileName    = 'Chrome832';

/*------------------------------------------------------------------------------*/
/* Add criteria */
/*------------------------------------------------------------------------------*/
exec pr_EDI_ManageProfileRule @vEDISenderId, @vEDITransaction, @vEDIDirection, @vProfileName, 'U' /* Action - add/udpate */, @vBusinessUnit;

/*------------------------------------------------------------------------------*/
/* 832 Mapping for Chrome */
/*------------------------------------------------------------------------------*/

select @vProfileName    = 'Chrome832';

/*                            ProcessAction,  SegmentId,  ProcessConditions,            ElementId, CIMSXMLField,       CIMSFieldName,      DefaultValue,      CIMSXMLPath, EDIElementDesc */
/*
insert into @ttEDIPM select  'TEMPLATE',      'ISA',      null,                         null,      null,               null,               null,               null,        null
insert into @ttEDIPM select  'TEMPLATE',      'GS',       null,                         null,      null,               null,               null,               null,        null
*/
insert into @ttEDIPM select  'TEMPLATE',      'ST',       'ST01=832',                   null,      null,               null,               'ImportSKUs',       null,        null
insert into @ttEDIPM select  'TEMPLATE',      'BCT',      null,                         null,      null,               null,               null,               null,        null

insert into @ttEDIPM select  'NEWREC',        'LIN',      null,                         null,      null,               null,               null,               null,        null
insert into @ttEDIPM select  'CLEARDATA',     'LIN',      null,                         null,      null,               'SKU1+SKU2+SKU3',   null,               null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'LIN',      null,                         null,      'Action',           null,               '[ImportAction]',   null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'LIN',      null,                         null,      'BusinessUnit',     null,               @vBusinessUnit,     null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'LIN',      null,                         null,      'RecordType',       null,               'SKU',              null,        null

insert into @ttEDIPM select  'ADDXMLFIELD',   'LIN',      'LIN02=VN',                   'LIN03',   'SKU1',             null,               null,               null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'LIN',      'LIN04=UP',                   'LIN05',   'UPC',              null,               null,               null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'LIN',      'LIN06=UP',                   'LIN07',   'UPC',              null,               null,               null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'LIN',      'LIN06=CM',                   'LIN07',   'SKU2',             null,               null,               null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'LIN',      'LIN08=UP',                   'LIN09',   'UPC',              null,               null,               null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'LIN',      'LIN08=SM',                   'LIN09',   'SKU3',             null,               null,               null,        null
insert into @ttEDIPM select  'SAVEDATA',      'LIN',      'LIN02=VN',                   'LIN03',   null,               'SKU1',             null,               null,        null
insert into @ttEDIPM select  'SAVEDATA',      'LIN',      'LIN06=CM',                   'LIN07',   null,               'SKU2',             null,               null,        null
insert into @ttEDIPM select  'SAVEDATA',      'LIN',      'LIN08=SM',                   'LIN09',   null,               'SKU3',             null,               null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'LIN',       null,                         null,     'SKU',              null,               '[SKU1]+[SKU2]+[SKU3]',null,     null
/* This will have to be transformed into DefaultOwner using the Mapping mechanism */
insert into @ttEDIPM select  'ADDXMLFIELD',   'LIN',       null,                         null,     'Ownership',        null,               '[SenderId]',               null,        null

insert into @ttEDIPM select  'ADDXMLFIELD',   'PID',      'PID01=S|X;PID02=08',       'PID04',   'SKU1',             null,               null,               null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'PID',      'PID01=S|X;PID02=73',       'PID04',   'SKU2',             null,               null,               null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'PID',      'PID01=S|X;PID02=74',       'PID04',   'SKU3',             null,               null,               null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'PID',      'PID01=F|X;PID02=08',         'PID05',   'SKU1Description',  null,               null,               null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'PID',      'PID01=F|X;PID02=73',         'PID05',   'SKU2Description',  null,               null,               null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'PID',      'PID01=F|X;PID02=74',         'PID05',   'SKU3Description',  null,               null,               null,        null

insert into @ttEDIPM select  'ADDXMLFIELD',   'CTP',      'CTP02=UCP',                  'CTP03',   'UnitCost',         null,               null,               null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'CTP',      'CTP02=MSR',                  'CTP03',   'UnitPrice',        null,               null,               null,        null
/* CT is code for Country of Origin
   38 is code for Country code  */
insert into @ttEDIPM select  'ADDXMLFIELD',   'N1',      'N101=CT;N103=38',             'N104',    'UDF1',             null,               null,               null,        null

exec pr_EDI_SetupProfileMap @vProfileName, @vEDITransaction, @ttEDIPM, 'R' /* Action - Add */, @vBusinessUnit;

Go
