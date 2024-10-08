/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  TReceiptDetailImportType: Added Lot, InventoryClass1 to InventoryClass3 and Removed RD_UDF11 to 30, TContactImportType: Added CT_UDF1 to 5
  TReceiptDetailImportType: Removed NextLineNo, ReceiptLine and added RD_UDF11 to RD_UDF30 (CIMS-2984)
  TReceiptDetailImportType: Added HostRecId (CIMSDE-18)
  2017/05/26  NB      TReceiptDetailImportType: Added RecordType column(HPI-1396)
  2016/09/01  KL      Added ReceiptType in TReceiptDetailValidationType  and TReceiptDetailImportType (HPI-512)
  2016/01/10  DK      Added ReasonCode field in TReceiptDetailImportType (FB-596)
  2014/12/02  SK      Added TReceiptDetailImportType, TReceiptDetailValidationType
  Create Type TReceiptDetailImportType as Table (
  Grant References on Type:: TReceiptDetailImportType   to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
/* Type used in ReceiptDetail type Import
   This table structure mimics the record structure of ReceiptDetails table, with few additional fields
   to capture key fields, etc.,. */
Create Type TReceiptDetailImportType as Table (
    RecordId                 TRecordId      identity (1,1),
    RecordType               TRecordType,
    RecordAction             TAction,

    ReceiptNumber            TReceiptNumber,
    HostReceiptLine          THostReceiptLine,

    SKU                      TSKU,
    SKU1                     TSKU,
    SKU2                     TSKU,
    SKU3                     TSKU,
    SKU4                     TSKU,
    SKU5                     TSKU,

    QtyOrdered               TQuantity,
    QtyReceived              TQuantity,
    ExtraQtyAllowed          TQuantity,

    VendorSKU                TVendorSKU,
    Lot                      TLot,
    InventoryClass1          TInventoryClass,
    InventoryClass2          TInventoryClass,
    InventoryClass3          TInventoryClass,
    CoO                      TCoO,
    VendorId                 TVendorId,
    CustPO                   TCustPO,
    Ownership                TOwnership,

    UnitCost                 TCost,
    ReasonCode               TReasonCode,

    RD_UDF1                  TUDF,
    RD_UDF2                  TUDF,
    RD_UDF3                  TUDF,
    RD_UDF4                  TUDF,
    RD_UDF5                  TUDF,
    RD_UDF6                  TUDF,
    RD_UDF7                  TUDF,
    RD_UDF8                  TUDF,
    RD_UDF9                  TUDF,
    RD_UDF10                 TUDF,

    -- SourceSystem             TName          DEFAULT 'HOST', not needed for Detail records
    BusinessUnit             TBusinessUnit,
    CreatedDate              TDateTime,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    /* Rest of the fields are for processing and not used for import */
    ReceiptType              TReceiptType,
    ReceiptDetailId          TRecordId,
    ReceiptId                TRecordId,
    SKUId                    TRecordId,

    SKUStatus                TStatus,

    InputXML                 TXML,
    ResultXML                TXML,
    HostRecId                TRecordId,

    Primary Key              (RecordId),
    Unique                   (RecordAction, RecordId)
);

Grant References on Type:: TReceiptDetailImportType   to public;

Go
