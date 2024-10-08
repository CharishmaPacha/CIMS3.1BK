/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2016/05/09  NB      (NBD-89)
                      Mapping changes from Diane's feedback for 861
  2016/03/21  NB      Reworked on corrections and changes based on review inputs(NBD-265)
  2016/03/10  NB      Initial Revision(NBD-265)
------------------------------------------------------------------------------*/

Go

  declare @vEDIDirection        TName,
          @vEDITransaction      TName,
          @vEDISenderId         TName,
          @vProfileName         TName,
          @vBusinessUnit        TBusinessUnit;

  declare @ttEDIPM              TEDIProcessMap;

select @vEDISenderId    = 'NBD',
       @vEDITransaction = '856',
       @vEDIDirection   = 'Import',
       @vBusinessUnit   = 'NBD',
       @vProfileName    = 'Generic856';

/*------------------------------------------------------------------------------*/
/* Add criteria */
/*------------------------------------------------------------------------------*/
exec pr_EDI_ManageProfileRule @vEDISenderId, @vEDITransaction, @vEDIDirection, @vProfileName, 'U' /* Action - add/udpate */, @vBusinessUnit;
exec pr_EDI_ManageProfileRule 'VASYLI', @vEDITransaction, @vEDIDirection, @vProfileName, 'U' /* Action - add/udpate */, @vBusinessUnit;
/*------------------------------------------------------------------------------*/
/* 850 Mapping for Generic */
/*------------------------------------------------------------------------------*/

/*                           ProcessAction,  SegmentId,  ProcessConditions,            ElementId, CIMSXMLField,       CIMSFieldName,      DefaultValue,      CIMSXMLPath, EDIElementDesc */

insert into @ttEDIPM select  'TEMPLATE',     'ST',       'ST01=856',                   null,      null,               null,               'ImportASN',       null,        null
/* BSN */
insert into @ttEDIPM select  'CLEARDATA',    'BSN',      null,                         null,      null,               'ShipmentId+ShipToCode+ContainerNo',null,null,      null

insert into @ttEDIPM select  'NEWREC',       'BSN',      null,                         null,      null,               null,               'RH',              null,        null
insert into @ttEDIPM select  'SAVEDATA',     'BSN',      null,                         null,      null,               'BusinessUnit',     @vBusinessUnit,    null,        null
/* 00 is the code for Original, 07 is the code for Duplicate */
insert into @ttEDIPM select  'SAVEDATA',     'BSN',      'BSN01=00',                   null,      null,               'ImportAction',     'I',               null,        null
insert into @ttEDIPM select  'SAVEDATA',     'BSN',      'BSN01=07',                   null,      null,               'ImportAction',     'U',               null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',  'BSN',      null,                         null,      'Action',           null,               '[ImportAction]',  null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',  'BSN',      null,                         null,      'ReceiptType',      null,               'A',               null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',  'BSN',      null,                         null,      'BusinessUnit',     null,               '[BusinessUnit]',  null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',  'BSN',      null,                         null,      'Ownership',        null,               '[SenderId]',      null,        null
/* Save the ShipmentId as ReceiptNumber
   This may be later replaced with the ContainerNumber, if it exists */
insert into @ttEDIPM select  'SAVEDATA',     'BSN',      null,                         'BSN02',   null,               'ShipmentId',       null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',  'BSN',      null,                         'BSN02',   'ReceiptNumber',    null,               null,              null,        null
insert into @ttEDIPM select  'UNMAPPED',     'BSN',      null,                         'BSN03',   null,               'ShipmentDate',     null,              null,        null
insert into @ttEDIPM select  'UNMAPPED',     'BSN',      null,                         'BSN04',   null,               'ShipmentTime',     null,              null,        null
/* Hierarchical Structure Code */
insert into @ttEDIPM select  'UNMAPPED',     'BSN',      null,                         'BSN05',   null,               'HierarchicalCode', null,              null,        null
/* DTM */
/*  Requested Date */
insert into @ttEDIPM select  'UNMAPPED',     'DTM',      'DTM01=010',                  'DTM02',   'RequestedDate',    null,               null,              null,        null
insert into @ttEDIPM select  'UNMAPPED',     'DTM',      'DTM01=010',                  'DTM03',   'RequestedTime',    null,               null,              null,        null
insert into @ttEDIPM select  'UNMAPPED',     'DTM',      'DTM01=010',                  'DTM04',   'TimeCode',         null,               null,              null,        null
/*  Estimated Port Delivery */
insert into @ttEDIPM select  'ADDXMLFIELD',  'DTM',      'DTM01=056',                  'DTM02',   'ETACountry',       null,               null,              null,        null
insert into @ttEDIPM select  'UNMAPPED',     'DTM',      'DTM01=056',                  'DTM03',   'EstPortDlvryTime', null,               null,              null,        null
insert into @ttEDIPM select  'UNMAPPED',     'DTM',      'DTM01=056',                  'DTM04',   'TimeCode',         null,               null,              null,        null
/* Estimated Arrival */
insert into @ttEDIPM select  'ADDXMLFIELD',  'DTM',      'DTM01=371',                  'DTM02',   'ETAWarehouse',     null,               null,              null,        null
insert into @ttEDIPM select  'UNMAPPED',     'DTM',      'DTM01=371',                  'DTM03',   'EstArrivalTime',   null,               null,              null,        null
insert into @ttEDIPM select  'UNMAPPED',     'DTM',      'DTM01=371',                  'DTM04',   'TimeCode',         null,               null,              null,        null

/* HL - Shipment segment */
insert into @ttEDIPM select  'UNMAPPED',     'HL',       'HL03=S',                     'HL01',    null,               'HierarchicalId',   null,              null,        null
insert into @ttEDIPM select  'UNMAPPED',     'HL',       'HL03=S',                     'HL02',    null,               'HierarParentId',   null,              null,        null
insert into @ttEDIPM select  'UNMAPPED',     'HL',       'HL03=S',                     'HL03',    null,               'HierarchicalLevel',null,              null,        null
insert into @ttEDIPM select  'UNMAPPED',     'HL',       'HL03=S',                     'HL04',    null,               'HierarchicalChildCode',null,          null,        null
/* TD1 segment */
insert into @ttEDIPM select  'ADDXMLFIELD',  'TD1',      null,                         'TD101',   'UDF3',             null,                null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',  'TD1',      null,                         'TD102',   'UDF4',             null,                null,              null,        null

/* TD5 segment */
insert into @ttEDIPM select  'UNMAPPED',     'TD5',      null,                         'TD501',   null,               'IdCodeQualifier',  null,              null,        null
insert into @ttEDIPM select  'UNMAPPED',     'TD5',      null,                         'TD502',   null,               'IdCode',           null,              null,        null
insert into @ttEDIPM select  'UNMAPPED',     'TD5',      null,                         'TD503',   null,               'TransportMethodTypeCode',null,        null,        null
--insert into @ttEDIPM select  'UNMAPPED',     'TD5',      null,                         'TD504',   null,               '',                 null,              null,        null
insert into @ttEDIPM select  'UNMAPPED',     'TD5',      null,                         'TD505',   null,               'Routing',          null,              null,        null
--insert into @ttEDIPM select  'UNMAPPED',     'TD5',      null,                         'TD506',   null,               '',                 null,              null,        null
insert into @ttEDIPM select  'UNMAPPED',     'TD5',      null,                         'TD507',   null,               'LocationQualifier',null,              null,        null
insert into @ttEDIPM select  'UNMAPPED',     'TD5',      null,                         'TD508',   null,               'LocationId',       null,              null,        null
--insert into @ttEDIPM select  'UNMAPPED',     'TD5',      null,                         'TD509',   null,               '',                 null,              null,        null
--insert into @ttEDIPM select  'UNMAPPED',     'TD5',      null,                         'TD510',   null,               '',                 null,              null,        null
--insert into @ttEDIPM select  'UNMAPPED',     'TD5',      null,                         'TD511',   null,               '',                 null,              null,        null
insert into @ttEDIPM select  'UNMAPPED',     'TD5',      null,                         'TD512',   null,               'ServiceLevelCode', null,              null,        null

/* N1 Segment */

insert into @ttEDIPM select  'UNMAPPED',     'N1',       'N101=60',                    'N102',    null,               'SalesPerson',      null,              null,        null
insert into @ttEDIPM select  'UNMAPPED',     'N1',       'N101=60;N103=92',            'N104',    null,               'SalesPersonCode',  null,              null,        null

insert into @ttEDIPM select  'UNMAPPED',     'N1',       'N101=A9',                    'N102',    null,               'SalesOffice',      null,              null,        null
insert into @ttEDIPM select  'UNMAPPED',     'N1',       'N101=A9;N103=92',            'N104',    null,               'SalesOfficeCode',  null,              null,        null

insert into @ttEDIPM select  'UNMAPPED',     'N1',       'N101=BY',                    'N102',    null,               'BuyingParty',      null,              null,        null
insert into @ttEDIPM select  'UNMAPPED',     'N1',       'N101=BY;N103=92',            'N104',    null,               'BuyingPartyCode',  null,              null,        null

insert into @ttEDIPM select  'UNMAPPED',     'N1',       'N101=BO',                    'N102',    null,               'Broker',           null,              null,        null
insert into @ttEDIPM select  'UNMAPPED',     'N1',       'N101=BO;N103=92',            'N104',    null,               'BrokerCode',       null,              null,        null

insert into @ttEDIPM select  'UNMAPPED',     'N1',       'N101=ST',                    'N102',    null,               'ShipTo',           null,              null,        null

insert into @ttEDIPM select  'SAVEDATA',     'N1',       'N101=ST;N103=92',            'N104',    null,               'ShipToCode',       null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',  'N1',       'N101=ST;N103=92',            null,      'Warehouse',        null,               '[SenderId]+[ShipToCode]',null, null

/* N2 Segment */
insert into @ttEDIPM select  'UNMAPPED',     'N2',       null,                         'N201',    'Name1',            null,               null,              null,        null
insert into @ttEDIPM select  'UNMAPPED',     'N2',       null,                         'N201',    'Name2',            null,               null,              null,        null

/* N3  Segment */
insert into @ttEDIPM select  'UNMAPPEd',     'N3',       null,                         'N301',    'Address1',         null,               null,              null,        null
insert into @ttEDIPM select  'UNMAPPEd',     'N3',       null,                         'N302',    'Address2',         null,               null,              null,        null
/* N4 Segment */
insert into @ttEDIPM select  'UNMAPPED',     'N4',       null,                         'N401',    'City',             null,               null,              null,        null
insert into @ttEDIPM select  'UNMAPPED',     'N4',       null,                         'N402',    'State',            null,               null,              null,        null
--insert into @ttEDIPM select  'UNMAPPED',     'N4',       null,                         'N403',    'City',             null,               null,              null,        null
insert into @ttEDIPM select  'UNMAPPED',     'N4',       null,                         'N404',    'Country',          null,               null,              null,        null

/* PER */
insert into @ttEDIPM select  'UNMAPPED',     'PER',      null,                         'PER01',      'ContactFunctionCode',null,             null,              null,        null
insert into @ttEDIPM select  'UNMAPPED',     'PER',      null,                         'PER02',      'Name',             null,               null,              null,        null
insert into @ttEDIPM select  'UNMAPPED',     'PER',      null,                         'PER03',      'CommNumQualifier1',null,               null,              null,        null
insert into @ttEDIPM select  'UNMAPPED',     'PER',      null,                         'PER04',      'CommNumber1',      null,               null,              null,        null
insert into @ttEDIPM select  'UNMAPPED',     'PER',      null,                         'PER05',      'CommNumQualifier2',null,               null,              null,        null
insert into @ttEDIPM select  'UNMAPPED',     'PER',      null,                         'PER06',      'CommNumber2',      null,               null,              null,        null
insert into @ttEDIPM select  'UNMAPPED',     'PER',      null,                         'PER07',      'CommNumQualifier3',null,               null,              null,        null
insert into @ttEDIPM select  'UNMAPPED',     'PER',      null,                         'PER08',      'CommNumber3',      null,               null,              null,        null
/* PRF Segment */
insert into @ttEDIPM select  'CLEARDATA',    'PRF',      null,                          null,        null,               'PONumber+PODate',  null,              null,        null
insert into @ttEDIPM select  'SAVEDATA',     'PRF',      null,                         'PRF01',      null,               'PONumber',         null,              null,        null
insert into @ttEDIPM select  'UNMAPPED',     'PRF',      null,                         'PRF02',      null,               null,               null,              null,        null
insert into @ttEDIPM select  'UNMAPPED',     'PRF',      null,                         'PRF03',      null,               null,               null,              null,        null
insert into @ttEDIPM select  'SAVEDATA',     'PRF',      null,                         'PRF04',      null,               'PODate',           null,              null,        null
/* REF Segment */
insert into @ttEDIPM select  'SAVEDATA',     'REF',      'REF01=OC',                   'REF02',      null,               'ContainerNo',      null,              null,       null
/* Receipt Number is a combination of ShipmentId+ContainerNumber */
insert into @ttEDIPM select  'ADDXMLFIELD',  'REF',      'REF01=OC',                   null,         'ReceiptNumber',    null,               '[ShipmentId]+[ContainerNo]',null,null
insert into @ttEDIPM select  'ADDXMLFIELD',  'REF',      'REF01=OC',                   'REF02',      'ContainerNo',      null,               null,              null,       null
insert into @ttEDIPM select  'ADDXMLFIELD',  'REF',      'REF01=WU',                   'REF02',      'Vessel',           null,               null,              null,        null
/* ContainerType */
insert into @ttEDIPM select  'ADDXMLFIELD',  'REF',      'REF01=98',                   'REF02',      'ContainerSize',    null,               null,              null,        null


/*
N2 - NOT CURRENTLY USED
insert into @ttEDIPM select  'SAVEDATA',     'N2',       null,                         null,      null,               null,               null,              null,        null

N3 - NOT CURRENTLY USED
insert into @ttEDIPM select  'SAVEDATA',     'N3',       null,                         null,      null,               null,               null,              null,        null

N4 - NOT CURRENTLY USED
insert into @ttEDIPM select  'SAVEDATA',     'N4',       null,                         null,      null,               null,               null,              null,        null

PER - NOT CURRENTLY USED
insert into @ttEDIPM select  'SAVEDATA',     'PER',      null,                         null,      null,               null,               null,              null,        null

*/

insert into @ttEDIPM select  'NEWREC',       'HL',       'HL03=I',                     null,      null,               null,               'RD',              null,        null

insert into @ttEDIPM select  'CLEARDATA',    'HL',       'HL03=I',                     null,      null,               'SKU+UPC+VendorSKU', null,             null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',  'HL',       'HL03=I',                     null,      'Action',           null,               '[ImportAction]',  null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',  'HL',       'HL03=I',                     null,      'BusinessUnit',     null,               '[BusinessUnit]',  null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',  'HL',       'HL03=I',                     null,      'Ownership',        null,               '[SenderId]',      null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',  'HL',       'HL03=I',                     null,      'ReceiptNumber',    null,               '[ShipmentId]+[ContainerNo]',null,null
insert into @ttEDIPM select  'ADDXMLFIELD',  'HL',       'HL03=I',                     null,      'CustPO',           null,               '[PONumber]',      null,        null
/* Save Shipment Id to RD_UDF5. This will be sent back in 861*/
insert into @ttEDIPM select  'ADDXMLFIELD',  'HL',       'HL03=I',                     null,      'UDF5',             null,               '[ShipmentId]',    null,        null
/* LIN Segment */
/* UPC - This must be translated into SKU and SKU components in SQL */
insert into @ttEDIPM select  'ADDXMLFIELD',  'LIN',      'LIN02=UP',                   'LIN03',   'SKU',              null,               null,              null,        null
/* There are 33 Elements in LIN segments. All except above are UNMAPPED */
/*SN1 Segment */
insert into @ttEDIPM select  'ADDXMLFIELD',  'SN1',      null,                         'SN101',   'HostReceiptLine',  null,               null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',  'SN1',      null,                         'SN102',   'QtyOrdered',       null,               null,              null,        null
insert into @ttEDIPM select  'ADDXMLFIELD',  'SN1',      null,                         'SN103',   'UoM',              null,               null,              null,        null
/* PO4 Segment */
insert into @ttEDIPM select  'UNMAPPED',     'PO4',      null,                         'PO401',   'Pack',             null,               null,              null,        null
insert into @ttEDIPM select  'UNMAPPED',     'PO4',      null,                         'PO402',   'Size',             null,               null,              null,        null
insert into @ttEDIPM select  'UNMAPPED',     'PO4',      null,                         'PO403',   'SizeUoM',          null,               null,              null,        null
insert into @ttEDIPM select  'UNMAPPED',     'PO4',      null,                         'PO404',   'PackingCode',      null,               null,              null,        null
insert into @ttEDIPM select  'UNMAPPED',     'PO4',      null,                         'PO405',   'WeightQualifier',  null,               null,              null,        null
insert into @ttEDIPM select  'UNMAPPED',     'PO4',      null,                         'PO406',   'GrossWtPerPack',   null,               null,              null,        null
insert into @ttEDIPM select  'UNMAPPED',     'PO4',      null,                         'PO407',   'GrossWtPerPackUoM',null,               null,              null,        null
insert into @ttEDIPM select  'UNMAPPED',     'PO4',      null,                         'PO408',   'GrossVolPerPack',  null,               null,              null,        null
insert into @ttEDIPM select  'UNMAPPED',     'PO4',      null,                         'PO409',   'GrossVolPerPackUoM',null,              null,              null,        null
insert into @ttEDIPM select  'UNMAPPED',     'PO4',      null,                         'PO410',   'Length',           null,               null,              null,        null
insert into @ttEDIPM select  'UNMAPPED',     'PO4',      null,                         'PO411',   'Width',            null,               null,              null,        null
insert into @ttEDIPM select  'UNMAPPED',     'PO4',      null,                         'PO412',   'Height',           null,               null,              null,        null
insert into @ttEDIPM select  'UNMAPPED',     'PO4',      null,                         'PO413',   'LWHUoM',           null,               null,              null,        null

/* CTT Segment */
insert into @ttEDIPM select  'UNMAPPED',     'CTT',      null,                         'CTT01',   'NumOfLineItems',   null,               null,              null,        null

exec pr_EDI_SetupProfileMap @vProfileName, @vEDITransaction, @ttEDIPM, 'R' /* Action - Add */, @vBusinessUnit;

Go
