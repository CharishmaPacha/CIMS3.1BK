begin transaction

  declare @ttEDIProcess Table
          (RecordId           integer  identity (1,1),
           ProcessSeq         integer,
           ProcessAction      varchar(500),
           EDIDirection       varchar(50),
           EDITransaction     varchar(50),
           SegmentId          varchar(50),
           ElementId          varchar(50),
           ProcessConditions  varchar(500),
           CIMSXMLPath        varchar(150),
           CIMSXMLField       varchar(150),
           DefaultValue       varchar(150),
           CIMSField          varchar(100),
           EDIElementDesc     varchar(500));

declare @sEDIDirection        varchar(50),
        @sEDITransaction      varchar(50);


select @sEDIDirection = 'IMPORT',
       @sEDITransaction = '832';

insert into @ttEDIProcess
             (ProcessSeq, ProcessAction, EDIDirection,  EDITransaction,    SegmentId, ElementId, ProcessConditions, CIMSXMLPath,           CIMSXMLField,     DefaultValue,     CIMSField,      EDIElementDesc)
select        1,          'SAVEDATA',    @sEDIDirection,@sEDITransaction,  'ISA',     'ISA06',   null,              null,                  null,             null,             'MsgFrom',      null
union select  2,          'SAVEDATA',    @sEDIDirection,@sEDITransaction,  'ISA',     'ISA08',   null,              null,                  null,             null,             'BusinessUnit', null

union select  3,          'SAVEDATA',    @sEDIDirection,@sEDITransaction,  'GS',      'GS02',    null,              null,                  null,             null,             'TargetSystem', null
union select  4,          'SAVEDATA',    @sEDIDirection,@sEDITransaction,  'GS',      'GS03',    null,              null,                  null,             null,             'SourceSystem', null

union select  5,          'CHECK',       @sEDIDirection,@sEDITransaction,  'ST',       null,     'ST01=832',        null,                  null,             null,             null,          null
union select  6,          'NEWDOC',      @sEDIDirection,@sEDITransaction,  'ST',       null,     null,              null,                  null,             null,             null,          null
union select  7,          'ADDXMLFIELD', @sEDIDirection,@sEDITransaction,  'ST',       null,     null,              'msg/msgHeader',       'schemaName',     'RFCL_ImportSKUs',null,          null
union select  8,          'ADDXMLFIELD', @sEDIDirection,@sEDITransaction,  'ST',       null,     null,              'msg/msgHeader',       'schemaVersion',  '1.0',            null,          null
union select  9,          'ADDXMLFIELD', @sEDIDirection,@sEDITransaction,  'ST',       null,     null,              'msg/msgHeader',       'msgSubject',     'ImportSKUs',     null,          null
union select  10,         'ADDXMLFIELD', @sEDIDirection,@sEDITransaction,  'ST',       null,     null,              'msg/msgHeader',       'SourceReference','[EDIFileName]',  null,          null
union select  11,         'ADDXMLFIELD', @sEDIDirection,@sEDITransaction,  'ST',       null,     null,              'msg/msgHeader',       'msgFrom',        '[MsgFrom]',      null,          null

union select  12,         'SAVEDATA',    @sEDIDirection,@sEDITransaction,  'BCT',      null,     'BCT10=00|04|05',   null,                 null,             'U',              'ImportAction', null
union select  13,         'SAVEDATA',    @sEDIDirection,@sEDITransaction,  'BCT',      null,     'BCT10=02',         null,                 null,             'I',              'ImportAction', null

union select  14,         'NEWREC',      @sEDIDirection,@sEDITransaction,  'LIN',      null,     null,              'msg/msgBody/Record',  null,             null,             null,           null
union select  15,         'CLEARDATA',   @sEDIDirection,@sEDITransaction,  'LIN',      null,     null,              null,                  null,             null,             'SKU1+SKU2+SKU3', null
union select  16,         'ADDXMLFIELD', @sEDIDirection,@sEDITransaction,  'LIN',      null,     null,              'msg/msgBody/Record',  'Action',         '[ImportAction]', null,           null
union select  17,         'ADDXMLFIELD', @sEDIDirection,@sEDITransaction,  'LIN',      null,     null,              'msg/msgBody/Record',  'BusinessUnit',   '[BusinessUnit]', null,           null
union select  18,         'ADDXMLFIELD', @sEDIDirection,@sEDITransaction,  'LIN',      null,     null,              'msg/msgBody/Record',  'RecordType',     'SKU',            null,           null
union select  19,         'ADDXMLFIELD', @sEDIDirection,@sEDITransaction,  'LIN',      'LIN03',  'LIN02=VN',        'msg/msgBody/Record',  'SKU1',           null,             null,           null
union select  20,         'SAVEDATA',    @sEDIDirection,@sEDITransaction,  'LIN',      'LIN03',  'LIN02=VN',        'msg/msgBody/Record',   null,            null,             'SKU1',          null
union select  21,         'ADDXMLFIELD', @sEDIDirection,@sEDITransaction,  'LIN',      'LIN05',  'LIN04=UP',        'msg/msgBody/Record',  'UPC',            null,             null,           null
union select  22,         'ADDXMLFIELD', @sEDIDirection,@sEDITransaction,  'LIN',      'LIN07',  'LIN06=UP',        'msg/msgBody/Record',  'UPC',            null,             null,           null
union select  23,         'ADDXMLFIELD', @sEDIDirection,@sEDITransaction,  'LIN',      'LIN07',  'LIN06=CM',        'msg/msgBody/Record',  'SKU2',           null,             null,           null
union select  24,         'SAVEDATA',    @sEDIDirection,@sEDITransaction,  'LIN',      'LIN07',  'LIN06=CM',        'msg/msgBody/Record',   null,            null,             'SKU2',         null
union select  25,         'ADDXMLFIELD', @sEDIDirection,@sEDITransaction,  'LIN',      'LIN09',  'LIN08=UP',        'msg/msgBody/Record',  'UPC',            null,             null,           null
union select  26,         'ADDXMLFIELD', @sEDIDirection,@sEDITransaction,  'LIN',      'LIN09',  'LIN08=SM',        'msg/msgBody/Record',  'SKU3',           null,             null,           null
union select  27,         'SAVEDATA',    @sEDIDirection,@sEDITransaction,  'LIN',      'LIN09',  'LIN08=SM',        'msg/msgBody/Record',   null,            null,             'SKU3',         null
union select  28,         'ADDXMLFIELD', @sEDIDirection,@sEDITransaction,  'LIN',       null,     null,             'msg/msgBody/Record',   'SKU',           '[SKU1]+[SKU2]+[SKU3]',null,      null

union select  29,         'ADDXMLFIELD', @sEDIDirection,@sEDITransaction,  'PID',      'PID04',  'PID01=S|X;PID02=08','msg/msgBody/Record','SKU1',           null,             null,           null
union select  30,         'ADDXMLFIELD', @sEDIDirection,@sEDITransaction,  'PID',      'PID04',  'PID01=S|X;PID02=73','msg/msgBody/Record','SKU2',           null,             null,           null
union select  31,         'ADDXMLFIELD', @sEDIDirection,@sEDITransaction,  'PID',      'PID04',  'PID01=S|X;PID02=74','msg/msgBody/Record','SKU3',           null,             null,           null
union select  32,         'ADDXMLFIELD', @sEDIDirection,@sEDITransaction,  'PID',      'PID05',  'PID01=F|X;PID02=08','msg/msgBody/Record','SKU1Description',null,             null,           null
union select  33,         'ADDXMLFIELD', @sEDIDirection,@sEDITransaction,  'PID',      'PID05',  'PID01=F|X;PID02=73','msg/msgBody/Record','SKU2Description',null,             null,           null
union select  34,         'ADDXMLFIELD', @sEDIDirection,@sEDITransaction,  'PID',      'PID05',  'PID01=F|X;PID02=74','msg/msgBody/Record','SKU3Description',null,             null,           null

union select  35,         'ADDXMLFIELD', @sEDIDirection,@sEDITransaction,  'CTP',      'CTP03',  'CTP02=UCP',         'msg/msgBody/Record','UnitCost',       null,             null,           null
union select  36,         'ADDXMLFIELD', @sEDIDirection,@sEDITransaction,  'CTP',      'CTP03',  'CTP02=MSR',         'msg/msgBody/Record','UnitPrice',      null,             null,           null


select @sEDIDirection = 'IMPORT',
       @sEDITransaction = '850';

insert into @ttEDIProcess
             (ProcessSeq, ProcessAction, EDIDirection,  EDITransaction,    SegmentId, ElementId, ProcessConditions, CIMSXMLPath,           CIMSXMLField,     DefaultValue,     CIMSField,      EDIElementDesc)
select        1,          'SAVEDATA',    @sEDIDirection,@sEDITransaction,  'ISA',     'ISA06',   null,              null,                  null,             null,             'MsgFrom',      null
union select  2,          'SAVEDATA',    @sEDIDirection,@sEDITransaction,  'ISA',     'ISA08',   null,              null,                  null,             null,             'BusinessUnit', null

union select  3,          'SAVEDATA',    @sEDIDirection,@sEDITransaction,  'GS',      'GS02',    null,              null,                  null,             null,             'TargetSystem', null
union select  4,          'SAVEDATA',    @sEDIDirection,@sEDITransaction,  'GS',      'GS03',    null,              null,                  null,             null,             'SourceSystem', null

union select  5,          'CHECK',       @sEDIDirection,@sEDITransaction,  'ST',       null,     'ST01=850',        null,                  null,             null,             null,          null
union select  6,          'NEWDOC',      @sEDIDirection,@sEDITransaction,  'ST',       null,     null,              null,                  null,             null,             null,          null
union select  7,          'ADDXMLFIELD', @sEDIDirection,@sEDITransaction,  'ST',       null,     null,              'msg/msgHeader',       'schemaName',     'RFCL_ImportRO',null,            null
union select  8,          'ADDXMLFIELD', @sEDIDirection,@sEDITransaction,  'ST',       null,     null,              'msg/msgHeader',       'schemaVersion',  '1.0',            null,          null
union select  9,          'ADDXMLFIELD', @sEDIDirection,@sEDITransaction,  'ST',       null,     null,              'msg/msgHeader',       'msgSubject',     'ImportRO',     null,            null
union select  10,         'ADDXMLFIELD', @sEDIDirection,@sEDITransaction,  'ST',       null,     null,              'msg/msgHeader',       'SourceReference','[EDIFileName]',  null,          null
union select  11,         'ADDXMLFIELD', @sEDIDirection,@sEDITransaction,  'ST',       null,     null,              'msg/msgHeader',       'msgFrom',        '[MsgFrom]',      null,          null

union select  12,         'NEWREC',      @sEDIDirection,@sEDITransaction,  'BEG',      null,     null,              'msg/msgBody/Record',  null,             null,             null,           null
union select  13,         'CLEARDATA',   @sEDIDirection,@sEDITransaction,  'BEG',      null,     null,              null,                  null,             null,             'ImportAction+ReceiptType+ReceiptNumber+DateOrdered', null
union select  14,         'SAVEDATA',    @sEDIDirection,@sEDITransaction,  'BEG',      null,     null,              null,                 null,             'U',               'ImportAction', null
union select  15,         'SAVEDATA',    @sEDIDirection,@sEDITransaction,  'BEG',      'BEG02',  null,              null,                 null,             null,              'ReceiptType',  null
union select  16,         'SAVEDATA',    @sEDIDirection,@sEDITransaction,  'BEG',      'BEG03',  null,              null,                 null,             null,              'ReceiptNumber',null
union select  17,         'SAVEDATA',    @sEDIDirection,@sEDITransaction,  'BEG',      'BEG05',  null,              null,                 null,             null,              'DateOrdered',  null

union select  18,         'ADDXMLFIELD', @sEDIDirection,@sEDITransaction,  'BEG',       null,     null,             'msg/msgBody/Record', 'RecordType',     'RH',              null,          null
union select  19,         'ADDXMLFIELD', @sEDIDirection,@sEDITransaction,  'BEG',       null,     null,             'msg/msgBody/Record', 'Action',         '[ImportAction]',  null,          null
union select  20,         'ADDXMLFIELD', @sEDIDirection,@sEDITransaction,  'BEG',       null,     null,             'msg/msgBody/Record', 'ReceiptNumber',  '[ReceiptNumber]', null,          null
union select  21,         'ADDXMLFIELD', @sEDIDirection,@sEDITransaction,  'BEG',       null,     null,             'msg/msgBody/Record', 'ReceiptType',    '[ReceiptType]',   null,          null
union select  22,         'ADDXMLFIELD', @sEDIDirection,@sEDITransaction,  'BEG',       null,     null,             'msg/msgBody/Record', 'DateOrdered',    '[DateOrdered]',   null,          null
union select  23,         'ADDXMLFIELD', @sEDIDirection,@sEDITransaction,  'BEG',       null,     null,             'msg/msgBody/Record', 'BusinessUnit',    '[BusinessUnit]', null,          null

union select  24,         'ADDXMLFIELD', @sEDIDirection,@sEDITransaction,  'N1',        'N102',   'N101=SF',        'msg/msgBody/Record', 'VendorId',        null,             null,          null
union select  25,         'ADDXMLFIELD', @sEDIDirection,@sEDITransaction,  'N1',        'N102',   'N101=ST',        'msg/msgBody/Record', 'Warehouse',       null,             null,          null

union select  26,         'NEWREC',      @sEDIDirection,@sEDITransaction,  'PO1',       null,     null,              'msg/msgBody/Record',  null,             null,             null,           null
union select  27,         'CLEARDATA',   @sEDIDirection,@sEDITransaction,  'PO1',       null,     null,               null,                 null,             null,             'SKU+UPC+VendorSKU', null
union select  28,         'ADDXMLFIELD', @sEDIDirection,@sEDITransaction,  'PO1',       null,     null,              'msg/msgBody/Record', 'RecordType',     'RD',     null,    null
union select  29,         'ADDXMLFIELD', @sEDIDirection,@sEDITransaction,  'PO1',       null,     null,              'msg/msgBody/Record', 'Action',         '[ImportAction]',  null,          null
union select  30,         'ADDXMLFIELD', @sEDIDirection,@sEDITransaction,  'PO1',       null,     null,              'msg/msgBody/Record', 'ReceiptNumber',  '[ReceiptNumber]', null,          null
union select  31,         'ADDXMLFIELD', @sEDIDirection,@sEDITransaction,  'PO1',       'PO102',  null,              'msg/msgBody/Record', 'QtyOrdered',     null, null,          null
union select  32,         'ADDXMLFIELD', @sEDIDirection,@sEDITransaction,  'PO1',       'PO104',  null,              'msg/msgBody/Record', 'UnitCost',       null, null,          null
union select  33,         'SAVEDATA',   @sEDIDirection,@sEDITransaction,  'PO1',       'PO107',  'PO106=UP',        'msg/msgBody/Record',  null,            null, 'UPC',          null
union select  34,         'SAVEDATA',   @sEDIDirection,@sEDITransaction,  'PO1',       'PO107',  'PO106=BP',        'msg/msgBody/Record',  null,            null, 'SKU',          null
union select  35,         'SAVEDATA',   @sEDIDirection,@sEDITransaction,  'PO1',       'PO107',  'PO106=VP',        'msg/msgBody/Record',  null,            null, 'VendorSKU',          null
union select  36,         'SAVEDATA',   @sEDIDirection,@sEDITransaction,  'PO1',       'PO109',  'PO108=UP',        'msg/msgBody/Record',  null,            null, 'UPC',          null
union select  37,         'SAVEDATA',   @sEDIDirection,@sEDITransaction,  'PO1',       'PO109',  'PO108=BP',        'msg/msgBody/Record',  null,            null, 'SKU',          null
union select  38,         'SAVEDATA',   @sEDIDirection,@sEDITransaction,  'PO1',       'PO109',  'PO108=VP',        'msg/msgBody/Record',  null,            null, 'VendorSKU',          null
union select  39,         'SAVEDATA',   @sEDIDirection,@sEDITransaction,  'PO1',       'PO111',  'PO110=UP',        'msg/msgBody/Record',  null,            null, 'UPC',          null
union select  40,         'SAVEDATA',   @sEDIDirection,@sEDITransaction,  'PO1',       'PO111',  'PO110=BP',        'msg/msgBody/Record',  null,            null, 'SKU',          null
union select  41,         'SAVEDATA',   @sEDIDirection,@sEDITransaction,  'PO1',       'PO111',  'PO110=VP',        'msg/msgBody/Record',  null,            null, 'VendorSKU',          null
union select  42,         'SAVEDATA',   @sEDIDirection,@sEDITransaction,  'PO1',       'PO113',  'PO112=UP',        'msg/msgBody/Record',  null,            null, 'UPC',          null
union select  43,         'SAVEDATA',   @sEDIDirection,@sEDITransaction,  'PO1',       'PO113',  'PO112=BP',        'msg/msgBody/Record',  null,            null, 'SKU',          null
union select  44,         'SAVEDATA',   @sEDIDirection,@sEDITransaction,  'PO1',       'PO113',  'PO112=VP',        'msg/msgBody/Record',  null,            null, 'VendorSKU',          null
union select  45,         'ADDXMLFIELD', @sEDIDirection,@sEDITransaction,  'PO1',       null,     null,              'msg/msgBody/Record', 'SKU',            '[SKU]|[UPC]',                    null,          null
union select  46,         'ADDXMLFIELD', @sEDIDirection,@sEDITransaction,  'PO1',       null,     null,              'msg/msgBody/Record', 'VendorSKU',      '[VendorSKU]', null,          null
union select  47,         'ADDXMLFIELD', @sEDIDirection,@sEDITransaction,  'PO1',       null,     null,              'msg/msgBody/Record', 'BusinessUnit',    '[BusinessUnit]', null,          null

  select *
  FROM @ttEDIProcess
  order by ProcessSeq
  FOR XML RAW('EDIProcessDetails'), TYPE, ELEMENTS XSINIL, ROOT('EDIProcess'), XMLSCHEMA
  ;

rollback transaction
