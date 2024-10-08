/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2016/03/23  NB      Fix to Warehouse field mapping(NBD-264)
  2016/03/22  NB      Reworked on corrections and changes based on review inputs(NBD-264)
  2016/03/10  NB      Initial Revision(NBD-264)
------------------------------------------------------------------------------*/

Go

  declare @vEDIDirection        TName,
          @vEDITransaction      TName,
          @vEDISenderId         TName,
          @vProfileName         TName,
          @vBusinessUnit        TBusinessUnit;

  declare @ttEDIPM              TEDIProcessMap;

select @vEDISenderId    = 'NBD',
       @vEDITransaction = '850',
       @vEDIDirection   = 'Import',
       @vBusinessUnit   = 'NBD',
       @vProfileName    = 'Generic850';

/*------------------------------------------------------------------------------*/
/* Add criteria */
/*------------------------------------------------------------------------------*/
exec pr_EDI_ManageProfileRule @vEDISenderId, @vEDITransaction, @vEDIDirection, @vProfileName, 'U' /* Action - add/udpate */, @vBusinessUnit;
exec pr_EDI_ManageProfileRule 'KUIU', @vEDITransaction, @vEDIDirection, @vProfileName, 'U' /* Action - add/udpate */, @vBusinessUnit;
/*------------------------------------------------------------------------------*/
/* 850 Mapping for Generic */
/*------------------------------------------------------------------------------*/

/*                            ProcessAction,  SegmentId,  ProcessConditions,            ElementId, CIMSXMLField,       CIMSFieldName,      DefaultValue,      CIMSXMLPath, EDIElementDesc */

insert into @ttEDIPM select  'TEMPLATE',      'ST',       'ST01=850',                   null,      null,               null,               'ImportRO',        null,        null

insert into @ttEDIPM select  'NEWREC',        'BEG',      null,                         null,      null,               null,               'RH',              null,        null
insert into @ttEDIPM select  'CLEARDATA',     'BEG',      null,                         null,      null,               'ImportAction+ReceiptNumber+DateOrdered',
                                                                                                                                           null,              null,        null
insert into @ttEDIPM select  'CLEARDATA',     'BEG',      null,                         null,      null,               'Warehouse',        null,              null,        null
insert into @ttEDIPM select  'SAVEDATA',      'BEG',      null,                         null,      null,               'BusinessUnit',     @vBusinessUnit,    null,        null
insert into @ttEDIPM select  'SAVEDATA',      'BEG',      null,                         null,      null,               'ImportAction',     'U',               null,        null
/* Ignore for now ..Always assume as PO for 850*/
insert into @ttEDIPM select  'UNMAPPED',      'BEG',      null,                         'BEG02',   null,               'ReceiptType',      null,              null,        null
insert into @ttEDIPM select  'SAVEDATA',      'BEG',      null,                         'BEG03',   null,               'ReceiptNumber',    null,              null,        null
insert into @ttEDIPM select  'UNMAPPED',      'BEG',      null,                         'BEG04',   'ReleaseNumber',    null,               null,              null,        null
insert into @ttEDIPM select  'SAVEDATA',      'BEG',      null,                         'BEG05',   null,               'DateOrdered',      null,              null,        null

insert into @ttEDIPM select  'ADDXMLFIELD',   'BEG',      null,                         null,      'Action',           null,               '[ImportAction]',  null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'BEG',      null,                         null,      'ReceiptNumber',    null,               '[ReceiptNumber]', null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'BEG',      null,                         null,      'ReceiptType',      null,               'PO',              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'BEG',      null,                         null,      'DateOrdered',      null,               '[DateOrdered]',   null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'BEG',      null,                         null,      'BusinessUnit',     null,               '[BusinessUnit]',  null,        null
/* TODO TODO TODO
  This must be transformed into Ownership via Mapping
*/
insert into @ttEDIPM select  'ADDXMLFIELD',   'BEG',      null,                         null,      'Ownership',        null,               '[SenderId]',      null,        null

/* Division */
insert into @ttEDIPM select  'ADDXMLFIELD',   'REF',      'REF01=19',                   'REF02',   'UDF1',             null,               null,               null,       null
/* TOD TODO TODO
insert into @ttEDIPM select  'ADDXMLFIELD',   'REF',      'REF01=ZZ',                   null,      'MutuallyDefined',  null,               null,               null,       null
*/
/* Catalog */
insert into @ttEDIPM select  'ADDXMLFIELD',   'REF',      'REF01=2S',                   'REF02',   'UDF2',             null,               null,               null,       null

/* ScheduledShip */
insert into @ttEDIPM select  'ADDXMLFIELD',   'DTM',      'DTM01=110',                  'DTM02',   'DateShipped',      null,               null,               null,       null
/* RequestedShip*/
insert into @ttEDIPM select  'UNMAPPED',      'DTM',      'DTM01=010',                  null,      'RequestedShip',    null,               null,               null,       null
/* EstimatedDelivery */
insert into @ttEDIPM select  'ADDXMLFIELD',   'DTM',      'DTM01=017',                  'DTM02',   'ETAWarehouse',     null,               null,               null,       null

/* From Warehouse */
insert into @ttEDIPM select  'UNMAPPED',      'TD5',      'TD502=54',                   'TD503',   'FromWarehouse',    null,               null,               null,       null
/* TransporationTypeCode */
insert into @ttEDIPM select  'UNMAPPED',      'TD5',      'TD502=54',                   'TD504',   'UDF4',             null,               null,               null,       null
/* Routing */
insert into @ttEDIPM select  'UNMAPPED',      'TD5',      'TD502=54',                   'TD505',   'Routing',          null,               null,               null,       null

/* TODO TODO TODO
   This must be transformed into VendorId code via Mapping
*/
insert into @ttEDIPM select  'ADDXMLFIELD',   'N1',       'N101=SF',                    'N102',    'VendorId',         null,               null,              null,        null
/* TODO TODO TODO
   This must be transformed into Warehouse code via Mapping
*/
insert into @ttEDIPM select  'SAVEDATA',      'N1',       'N101=ST',                    'N102',    null,               'Warehouse',             null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'N1',       'N101=ST',                    null,      'Warehouse',        null,                    '[SenderId]+[Warehouse]',null,  null
/*  Agent*/
insert into @ttEDIPM select  'UNMAPPED',      'N1',       'N101=AG',                    'N102',    'Agent',            null,               null,              null,        null


insert into @ttEDIPM select  'NEWREC',        'PO1',      null,                         null,      null,               null,               'RD',              null,        null
insert into @ttEDIPM select  'CLEARDATA',     'PO1',      null,                         null,      null,               'SKU+UPC+VendorSKU',null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'PO1',      null,                         null,      'Action',           null,               '[ImportAction]',  null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'PO1',      null,                         null,      'ReceiptNumber',    null,               '[ReceiptNumber]', null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'PO1',      null,                         'PO101',   'HostReceiptLine',  null,               null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'PO1',      null,                         'PO102',   'QtyOrdered',       null,               null,              null,        null
insert into @ttEDIPM select  'UNMAPPED',      'PO1',      null,                         'PO103',   'QtyOrderUoM',      null,               null,              null,        null
/* UnitPrice from Host */
insert into @ttEDIPM select  'ADDXMLFIELD',   'PO1',      null,                         'PO104',   'UnitCost',         null,               null,              null,        null
insert into @ttEDIPM select  'UNMAPPED',      'PO1',      null,                         'PO105',   'UnitCostBasis',    null,               null,              null,        null

insert into @ttEDIPM select  'SAVEDATA',      'PO1',      'PO106=UP',                   'PO107',   null,               'UPC',              null,              null,        null
insert into @ttEDIPM select  'SAVEDATA',      'PO1',      'PO106=BP',                   'PO107',   null,               'SKU',              null,              null,        null
insert into @ttEDIPM select  'SAVEDATA',      'PO1',      'PO106=VP',                   'PO107',   null,               'VendorSKU',        null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'PO1',      null,                         null,      'SKU',              null,               '[SKU]|[UPC]',     null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'PO1',      null,                         null,      'VendorSKU',        null,               '[VendorSKU]',     null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',   'PO1',      null,                         null,      'BusinessUnit',     null,               '[BusinessUnit]',  null,        null
/*   This must be transformed into Ownership via Mapping */
insert into @ttEDIPM select  'ADDXMLFIELD',   'PO1',      null,                         null,      'Ownership',        null,               '[SenderId]',      null,        null

insert into @ttEDIPM select  'UNMAPPED',      'PO1',      null,                         'PO108',   'ProdOrSvcIdCode1', null,               null,              null,        null
insert into @ttEDIPM select  'UNMAPPED',      'PO1',      null,                         'PO109',   'ProdOrSvcId1',     null,               null,              null,        null
insert into @ttEDIPM select  'UNMAPPED',      'PO1',      null,                         'PO110',   'ProdOrSvcIdCode2', null,               null,              null,        null
insert into @ttEDIPM select  'UNMAPPED',      'PO1',      null,                         'PO111',   'ProdOrSvcId2',     null,               null,              null,        null
insert into @ttEDIPM select  'UNMAPPED',      'PO1',      null,                         'PO112',   'ProdOrSvcIdCode3', null,               null,              null,        null
insert into @ttEDIPM select  'UNMAPPED',      'PO1',      null,                         'PO113',   'ProdOrSvcId3',     null,               null,              null,        null

/* TODO TODO TODO */
insert into @ttEDIPM select  'UNMAPPED',      'REF',      'REF01=PRT',                  'REF02',   'ProductType',      null,               null,              null,        null

exec pr_EDI_SetupProfileMap @vProfileName, @vEDITransaction, @ttEDIPM, 'R' /* Action - Add */, @vBusinessUnit;

Go
