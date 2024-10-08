/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2016/03/22  NB      Introduced EDIFileName to ST Template(NBD-264)
  2016/02/18  NB      Introduced SourceSystem and TargetSystem defaults to ST Template(NBD-31)
  2015/12/22  NB      Changed ST msgFrom to 'SenderId'
                      Added new instructions for save ST Control Number(NBD-59)
  2015/11/02  AY      Initial Revision
------------------------------------------------------------------------------*/

Go

  declare @vEDIDirection        TName,
          @vEDITransaction      TName,
          @vEDISenderId         TName,
          @vProfileName         TName,
          @vBusinessUnit        TBusinessUnit;

  declare @ttEDIPM              TEDIProcessMap;

select @vEDISenderId    = 'All', -- null not allowed
       @vEDITransaction = 'All', -- null not allowed
       @vEDIDirection   = 'Import',
       @vBusinessUnit   = 'NBD',
       @vProfileName    = 'StandardSegments';

/*------------------------------------------------------------------------------*/
/* Add criteria */
/*------------------------------------------------------------------------------*/
exec pr_EDI_ManageProfileRule @vEDISenderId, @vEDITransaction, @vEDIDirection, @vProfileName, 'U' /* Action - add/udpate */, @vBusinessUnit;

/*------------------------------------------------------------------------------*/
/* 832 Mapping for Chrome */
/*------------------------------------------------------------------------------*/

/*                          ProcessAction,    SegmentId,  ProcessConditions,            ElementId, CIMSXMLField,       CIMSFieldName,      DefaultValue,       CIMSXMLPath, EDIElementDesc */
insert into @ttEDIPM select 'SAVEDATA',       'ISA',      null,                         'ISA06',   null,               'MsgFrom',          null,               null,        null
insert into @ttEDIPM select 'SAVEDATA',       'ISA',      null,                         'ISA08',   null,               'BusinessUnit',     null,               null,        null

/*------------------------------------------------------------------------------*/

/*                          ProcessAction,    SegmentId,  ProcessConditions,            ElementId, CIMSXMLField,       CIMSFieldName,      DefaultValue,       CIMSXMLPath, EDIElementDesc */
insert into @ttEDIPM select 'SAVEDATA',       'GS',       null,                         'GS02',    null,               'TargetSystem',     null,               null,        null
insert into @ttEDIPM select 'SAVEDATA',       'GS',       null,                         'GS03',    null,               'SourceSystem',     null,               null,        null

/*------------------------------------------------------------------------------*/

/*                          ProcessAction,    SegmentId,  ProcessConditions,            ElementId, CIMSXMLField,       CIMSFieldName,      DefaultValue,       CIMSXMLPath, EDIElementDesc */
insert into @ttEDIPM select 'CHECK',          'ST',       null,                         null,      null,               null,               null,               null,        null
insert into @ttEDIPM select 'NEWDOC',         'ST',       null,                         null,      null,               null,               null,               null,        null
insert into @ttEDIPM select 'ADDXMLFIELD',    'ST',       null,                         null,      'schemaName',       null,               'RFCL_<Import>',    null,        null
insert into @ttEDIPM select 'ADDXMLFIELD',    'ST',       null,                         null,      'schemaVersion',    null,               '1.0',              null,        null
insert into @ttEDIPM select 'ADDXMLFIELD',    'ST',       null,                         null,      'msgSubject',       null,               '<Import>',         null,        null
insert into @ttEDIPM select 'ADDXMLFIELD',    'ST',       null,                         null,      'SourceReference',  null,               '[EDIFileName]',    null,        null
insert into @ttEDIPM select 'ADDXMLFIELD',    'ST',       null,                         null,      'msgFrom',          null,               '[SenderId]',       null,        null
insert into @ttEDIPM select 'SAVEDATA',       'ST',       null,                         'ST02',    null,               'STControlNumber',  null,               null,        null
insert into @ttEDIPM select 'ADDXMLFIELD',    'ST',       null,                         null,      'EDISTControlNumber',null,              '[STControlNumber]',null,        null
insert into @ttEDIPM select 'ADDXMLFIELD',    'ST',       null,                         null,      'EDIFileName',       null,              '[EDIFileName]',    null,        null
/* The Source System and Target System are required by the Interface Log. Therefore these must be added by default
   Overriding the default can be done in the respective mapping */
insert into @ttEDIPM select 'ADDXMLFIELD',    'ST',       null,                         null,      'SourceSystem',      null,               'EDI',             null,        null
insert into @ttEDIPM select 'ADDXMLFIELD',    'ST',       null,                         null,      'TargetSystem',      null,               'CIMS',            null,        null

/*------------------------------------------------------------------------------*/

/*                          ProcessAction,    SegmentId,  ProcessConditions,            ElementId, CIMSXMLField,       CIMSFieldName,      DefaultValue,       CIMSXMLPath, EDIElementDesc */
insert into @ttEDIPM select 'SAVEDATA',       'BCT',      'BCT10=00|04|05',             null,      null,               'ImportAction',     'U',                null,        null
insert into @ttEDIPM select 'SAVEDATA',       'BCT',      'BCT10=02',                   null,      null,               'ImportAction',     'I',                null,        null

exec pr_EDI_SetupProfileMap @vProfileName, @vEDITransaction, @ttEDIPM, 'R' /* Action - Add */, @vBusinessUnit;

Go
