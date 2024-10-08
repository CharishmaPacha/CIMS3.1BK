/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  TReceiptHeaderImportType: Removed RH_UDF11 to RH_UDF30
  TReceiptHeaderImportType: Added RH_UDF6 to RH_UDF30
  2020/02/25  SJ      TReceiptHeaderImportType: Modified Archived field (JL-48)
  2019/02/05  TD      TASNLPNImportType,TReceiptHeaderImportType:Added HostNumLines(CID-44)
  2017/11/27  SV      TReceiptHeaderImportType: Added HostRecId (CIMSDE-17)
  2016/05/25  NB      Added RecordType to TReceiptHeaderImportType(NBD-552)
  2015/09/30  DK      Added PickTicket field in TReceiptHeaderImportType (FB-416).
  2014/12/03  SV      Added fields in TReceiptHeaderImportType
  2014/12/01  SK      Added TReceiptHeaderImportType
  Create Type TReceiptHeaderImportType as Table (
  Grant References on Type:: TReceiptHeaderImportType   to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
/* Type used in ReceiptHeader type Import
   This table structure mimics the record structure of ReceiptHeaders table, with few additional fields
   to capture key fields, etc.,. */
Create Type TReceiptHeaderImportType as Table (
    RecordId                 TRecordId      identity (1,1),
    RecordType               TRecordType,
    RecordAction             TAction,

    ReceiptNumber            TReceiptNumber,
    ReceiptType              TReceiptType,

    VendorId                 TVendorId,
    Ownership                TOwnership,
    Warehouse                TWarehouse,

    NumLPNs                  TCount,
    NumUnits                 TCount,
    HostNumLines             TCount,

    Vessel                   TVessel,
    ContainerNo              TContainer,
    ContainerSize            TContainerSize,

    DateOrdered              TDateTime,
    DateShipped              TDateTime,
    ETACountry               TDate,
    ETACity                  TDate,
    ETAWarehouse             TDate,

    BillNo                   TBoLNumber,
    SealNo                   TSealNumber,
    InvoiceNo                TInvoiceNo,
    PickTicket               TPickTicket,

    RH_UDF1                  TUDF,
    RH_UDF2                  TUDF,
    RH_UDF3                  TUDF,
    RH_UDF4                  TUDF,
    RH_UDF5                  TUDF,
    RH_UDF6                  TUDF,
    RH_UDF7                  TUDF,
    RH_UDF8                  TUDF,
    RH_UDF9                  TUDF,
    RH_UDF10                 TUDF,

    SourceSystem             TName          DEFAULT 'HOST',
    BusinessUnit             TBusinessUnit,
    CreatedDate              TDateTime,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    /* Rest of the fields are for processing and not used for import */
    ReceiptId                TRecordId,
    Status                   TStatus,

    InputXML                 TXML,
    ResultXML                TXML,
    HostRecId                TRecordId,

    PRIMARY KEY              (RecordId),
    Unique                   (RecordAction, RecordId)
);

Grant References on Type:: TReceiptHeaderImportType   to public;

Go
